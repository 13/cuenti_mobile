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

  /// A published name as a v9.9.9 release carries it: `-v*-` is the tag in
  /// the versioned names, and any `*` left over is an ABI.
  String expandVersion(String name) => name.replaceFirst('-v*-', '-v9.9.9-');

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
    final universal = published
        .map(expandVersion)
        .where((n) => !n.contains('*'))
        .toList();

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
    final patterns = publishedAssetNames()
        .map(expandVersion)
        .where((n) => n.contains('*'));

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

  test('the version and the app name are in the published file names', () {
    final published = publishedAssetNames();

    expect(published, contains('Cuenti-v*-release.apk'));
    expect(published, contains('Cuenti-v*-*-release.apk'));
  });

  test('each APK is published under exactly one name', () {
    // Releases used to carry every APK three times (app-*, cuenti-* and
    // Cuenti-v*). Only the versioned, app-named file is published now.
    expect(
      publishedAssetNames(),
      unorderedEquals([
        'Cuenti-v*-release.apk',
        'Cuenti-v*-*-release.apk',
      ]),
    );
  });
}
