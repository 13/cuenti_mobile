import 'dart:io';

import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/app_update/data/app_update_repository.dart';
import 'package:cuentimobile/features/app_update/domain/app_release.dart';
import 'package:cuentimobile/features/app_update/ui/update_check.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MockAppUpdateRepository extends Mock implements AppUpdateRepository {}

class _MemoryStorage extends SecureStorage {
  _MemoryStorage() : super();
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

const _release = AppRelease(
  tagName: 'v9.9.9',
  body: 'Big improvements',
  assets: [
    ReleaseAsset(
      name: 'app-arm64-v8a-release.apk',
      browserDownloadUrl: 'https://example.com/arm64.apk',
      size: 100,
    ),
  ],
);

void main() {
  late MockAppUpdateRepository repo;
  late _MemoryStorage storage;
  final installed = <String>[];

  setUpAll(() {
    registerFallbackValue(const ReleaseAsset());
    registerFallbackValue(const AppRelease());
  });

  setUp(() {
    installed.clear();
    storage = _MemoryStorage();
    repo = MockAppUpdateRepository();
    PackageInfo.setMockInitialValues(
      appName: 'Cuenti',
      packageName: 'app.cuenti',
      version: '2.0.4',
      buildNumber: '12',
      buildSignature: '',
    );
    when(() => repo.getLatestRelease()).thenAnswer((_) async => _release);
    when(() => repo.pickAsset(any(), any())).thenReturn(_release.assets.first);
    when(() => repo.downloadApk(any(), any(), any())).thenAnswer((
      invocation,
    ) async {
      final onProgress =
          invocation.positionalArguments[2] as void Function(int, int);
      onProgress(50, 100);
      return invocation.positionalArguments[1] as String;
    });
  });

  Future<void> pumpHost(WidgetTester tester, {bool automatic = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUpdateRepositoryProvider.overrideWithValue(repo),
          secureStorageProvider.overrideWithValue(storage),
          supportedAbisProvider.overrideWith((ref) async => ['arm64-v8a']),
          // No real IO here — actual file IO never completes under the
          // widget-test FakeAsync zone.
          downloadDirProvider.overrideWithValue(
            () async => Directory.systemTemp,
          ),
          apkInstallerProvider.overrideWithValue(
            (path) async => installed.add(path),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => automatic
                    ? maybeCheckForUpdates(context, ref)
                    : checkForUpdates(context, ref),
                child: const Text('check'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('newer release: dialog with notes, download, installer', (
    tester,
  ) async {
    await pumpHost(tester);
    await tester.tap(find.text('check'));
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsOneWidget);
    expect(find.textContaining('v9.9.9'), findsOneWidget);
    expect(find.text('Big improvements'), findsOneWidget);

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(installed, hasLength(1));
    expect(installed.single, endsWith('app-arm64-v8a-release.apk'));
  });

  testWidgets('up to date: snackbar, no dialog', (tester) async {
    when(
      () => repo.getLatestRelease(),
    ).thenAnswer((_) async => const AppRelease(tagName: 'v2.0.4'));
    await pumpHost(tester);
    await tester.tap(find.text('check'));
    await tester.pumpAndSettle();

    expect(find.text("You're up to date"), findsOneWidget);
    expect(find.text('Update available'), findsNothing);
  });

  group('the automatic check', () {
    testWidgets('prompts when a newer release is out', (tester) async {
      await pumpHost(tester, automatic: true);
      await tester.tap(find.text('check'));
      await tester.pumpAndSettle();

      expect(find.text('Update available'), findsOneWidget);
    });

    testWidgets('records when it looked, so it does not ask GitHub again on '
        'the next resume', (tester) async {
      await pumpHost(tester, automatic: true);
      await tester.tap(find.text('check'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(storage.data['update_last_checked'], isNotNull);

      await tester.tap(find.text('check'));
      await tester.pumpAndSettle();

      expect(find.text('Update available'), findsNothing);
      verify(() => repo.getLatestRelease()).called(1);
    });

    testWidgets('says nothing at all when already up to date', (tester) async {
      when(
        () => repo.getLatestRelease(),
      ).thenAnswer((_) async => const AppRelease(tagName: 'v2.0.4'));

      await pumpHost(tester, automatic: true);
      await tester.tap(find.text('check'));
      await tester.pumpAndSettle();

      expect(
        find.text("You're up to date"),
        findsNothing,
        reason: 'a launch-time check should be silent unless it has news',
      );
    });

    testWidgets('stays quiet when GitHub cannot be reached', (tester) async {
      when(() => repo.getLatestRelease()).thenThrow(Exception('offline'));

      await pumpHost(tester, automatic: true);
      await tester.tap(find.text('check'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't check for updates"), findsNothing);
      expect(find.text('Update available'), findsNothing);
    });

    testWidgets('does not check at all once switched off in settings', (
      tester,
    ) async {
      storage.data['update_auto_check'] = 'false';

      await pumpHost(tester, automatic: true);
      await tester.tap(find.text('check'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.getLatestRelease());
      expect(find.text('Update available'), findsNothing);
    });

    testWidgets('does not prompt again for a version the user skipped', (
      tester,
    ) async {
      storage.data['update_skipped_version'] = 'v9.9.9';

      await pumpHost(tester, automatic: true);
      await tester.tap(find.text('check'));
      await tester.pumpAndSettle();

      expect(find.text('Update available'), findsNothing);
    });
  });

  testWidgets('Skip this version records the tag so it stops asking', (
    tester,
  ) async {
    await pumpHost(tester, automatic: true);
    await tester.tap(find.text('check'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip this version'));
    await tester.pumpAndSettle();

    expect(storage.data['update_skipped_version'], 'v9.9.9');
    expect(find.text('Update available'), findsNothing);
  });

  testWidgets('the manual check still reports being up to date, and ignores '
      'both the throttle and a skipped version', (tester) async {
    storage.data
      ..['update_skipped_version'] = 'v9.9.9'
      ..['update_last_checked'] = DateTime.now().toIso8601String();

    await pumpHost(tester);
    await tester.tap(find.text('check'));
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsOneWidget);
  });
}
