import 'dart:io';

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
  final installed = <String>[];

  setUpAll(() {
    registerFallbackValue(const ReleaseAsset());
    registerFallbackValue(const AppRelease());
  });

  setUp(() {
    installed.clear();
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

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUpdateRepositoryProvider.overrideWithValue(repo),
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
                onPressed: () => checkForUpdates(context, ref),
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
}
