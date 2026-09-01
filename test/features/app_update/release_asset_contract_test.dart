import 'dart:io';

import 'package:cuentimobile/features/app_update/data/app_update_repository.dart';
import 'package:cuentimobile/features/app_update/domain/app_release.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// The release workflow chooses the APK file names; this client finds the
/// APK by name. Nothing in the type system connects the two, and when they
/// drifted apart the updater silently reported "no APK found" for everyone.
void main() {
  final repo = AppUpdateRepository(Dio());

  /// The basenames the workflow attaches to a GitHub Release.
  List<String> publishedAssetNames() {
    final yaml = File('.github/workflows/build-apk.yml').readAsStringSync();
    final filesBlock = yaml.split('files: |').last;
    return [
      for (final line in filesBlock.split('\n'))
        if (line.trim().endsWith('.apk')) line.trim().split('/').last,
    ];
  }

  ReleaseAsset? pick(List<String> names, List<String> abis) => repo.pickAsset(
    AppRelease(
      tagName: 'v9.9.9',
      assets: [
        for (final n in names)
          ReleaseAsset(name: n, browserDownloadUrl: 'https://x/$n', size: 1),
      ],
    ),
    abis,
  );

  test('the workflow publishes a universal APK this client can find', () {
    final published = publishedAssetNames();
    final universal = published.where((n) => !n.contains('*')).toList();

    expect(universal, isNotEmpty, reason: 'no universal APK is published');
    for (final name in universal) {
      expect(
        pick([name], ['x86'])?.name,
        name,
        reason: '$name is published but pickAsset does not recognise it',
      );
    }
  });

  test('the workflow publishes split APKs this client can find', () {
    final patterns = publishedAssetNames().where((n) => n.contains('*'));

    expect(patterns, isNotEmpty, reason: 'no split APKs are published');
    for (final pattern in patterns) {
      // What the glob expands to for a real ABI.
      final name = pattern.replaceFirst('*', 'arm64-v8a');
      expect(
        pick([name], ['arm64-v8a'])?.name,
        name,
        reason: '$name is published but pickAsset does not recognise it',
      );
    }
  });

  test('the app-named assets released up to v2.2.0 are still published, so '
      'clients already installed can still update', () {
    final published = publishedAssetNames();

    expect(published, contains('app-release.apk'));
    expect(published, contains('app-*-release.apk'));
  });

  test('the app is named in the assets it publishes', () {
    final published = publishedAssetNames();

    expect(published, contains('cuenti-release.apk'));
    expect(published, contains('cuenti-*-release.apk'));
  });
}
