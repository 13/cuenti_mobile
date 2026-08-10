import 'package:cuentimobile/features/app_update/data/app_update_repository.dart';
import 'package:cuentimobile/features/app_update/domain/app_release.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late AppUpdateRepository repo;

  const releaseJson = {
    'tag_name': 'v2.0.5',
    'body': 'Bug fixes',
    'assets': [
      {
        'name': 'app-arm64-v8a-release.apk',
        'browser_download_url': 'https://example.com/arm64.apk',
        'size': 100,
      },
      {
        'name': 'app-release.apk',
        'browser_download_url': 'https://example.com/universal.apk',
        'size': 300,
      },
    ],
  };

  setUp(() {
    dio = MockDio();
    repo = AppUpdateRepository(dio);
  });

  test('getLatestRelease parses GitHub JSON', () async {
    when(() => dio.get<Map<String, dynamic>>(
          any(),
          options: any(named: 'options'),
        )).thenAnswer((_) async => ok(releaseJson));

    final release = await repo.getLatestRelease();

    expect(release.tagName, 'v2.0.5');
    expect(release.body, 'Bug fixes');
    expect(release.assets, hasLength(2));
    expect(
      release.assets.first.browserDownloadUrl,
      'https://example.com/arm64.apk',
    );
  });

  test('pickAsset prefers ABI match, falls back to universal', () {
    final release = AppRelease.fromJson(releaseJson);

    expect(
      repo.pickAsset(release, ['arm64-v8a', 'armeabi-v7a'])!.name,
      'app-arm64-v8a-release.apk',
    );
    expect(
      repo.pickAsset(release, ['x86'])!.name,
      'app-release.apk',
    );
  });

  test('pickAsset returns null when release has no APKs', () {
    const empty = AppRelease(tagName: 'v9.9.9');
    expect(repo.pickAsset(empty, ['arm64-v8a']), isNull);
  });
}
