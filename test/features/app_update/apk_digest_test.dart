import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cuentimobile/features/app_update/data/app_update_repository.dart';
import 'package:cuentimobile/features/app_update/domain/app_release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late File apk;
  late String goodDigest;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('apk_digest_test');
    apk = File('${dir.path}/cuenti-release.apk');
    final bytes = List.generate(4096, (i) => i % 251);
    await apk.writeAsBytes(bytes);
    goodDigest = 'sha256:${sha256.convert(bytes)}';
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('a matching digest passes and keeps the file', () async {
    await verifyDigest(apk, goodDigest);
    expect(apk.existsSync(), isTrue);
  });

  test('the hex comparison ignores case', () async {
    final upper = 'sha256:${goodDigest.substring(7).toUpperCase()}';
    await verifyDigest(apk, upper);
    expect(apk.existsSync(), isTrue);
  });

  test(
    'a mismatch throws and deletes the file, so it cannot be installed',
    () async {
      await expectLater(
        verifyDigest(apk, 'sha256:${'0' * 64}'),
        throwsA(isA<ApkIntegrityException>()),
      );
      expect(apk.existsSync(), isFalse);
    },
  );

  test('a release without a digest is not blocked', () async {
    await verifyDigest(apk, null);
    await verifyDigest(apk, '');
    expect(apk.existsSync(), isTrue);
  });

  test('an unknown digest algorithm is refused rather than trusted', () async {
    await expectLater(
      verifyDigest(apk, 'md5:0123'),
      throwsA(isA<ApkIntegrityException>()),
    );
  });

  test('the GitHub release JSON digest is parsed onto the asset', () {
    final release = AppRelease.fromJson(const {
      'tag_name': 'v2.9.2',
      'assets': [
        {
          'name': 'cuenti-release.apk',
          'browser_download_url': 'https://example.com/cuenti-release.apk',
          'size': 1,
          'digest': 'sha256:abc',
        },
        {
          'name': 'app-release.apk',
          'browser_download_url': 'https://example.com/app-release.apk',
          'size': 1,
        },
      ],
    });

    expect(release.assets.first.digest, 'sha256:abc');
    expect(release.assets.last.digest, isNull);
  });
}
