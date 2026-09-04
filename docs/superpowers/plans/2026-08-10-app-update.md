# In-App Update from GitHub Releases Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Manual "Check for updates" in the About screen that fetches the latest GitHub release, downloads the ABI-matched APK with progress, and launches the Android installer.

**Architecture:** New `lib/features/app_update/` feature: freezed release models, a repository with its own Dio instance (GitHub — never the backend Dio with auth interceptors), a pure version-compare function, and an update dialog wired into the About screen. Installer launch, ABI lookup, and temp-dir lookup live behind Riverpod providers so widget tests can override them.

**Tech Stack:** Flutter, Riverpod (codegen not required — plain providers), freezed/json_serializable, Dio, package_info_plus, device_info_plus, path_provider, open_filex.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-08-10-app-update-design.md`
- GitHub repo queried: `13/cuenti_mobile`, endpoint `https://api.github.com/repos/13/cuenti_mobile/releases/latest`
- Asset names: `app-<abi>-release.apk` (split), `app-release.apk` (universal fallback)
- Version compare ignores build number (`+NN`), strips leading `v`
- Flutter binary: `~/fvm/versions/stable/bin/flutter`
- Repository style: mirror `lib/features/categories/data/categories_repository.dart` (`_guard` helper, `ApiException.fromDio`)
- Commit after every task; run `~/fvm/versions/stable/bin/flutter test` before each commit

---

### Task 1: Dependencies + Android manifest permission

**Files:**
- Modify: `pubspec.yaml` (dependencies)
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Produces: packages `open_filex`, `device_info_plus`, `path_provider` resolvable; manifest carries `REQUEST_INSTALL_PACKAGES`.

- [ ] **Step 1: Add packages**

Run: `~/fvm/versions/stable/bin/flutter pub add open_filex device_info_plus path_provider`
Expected: pubspec updated, `pub get` succeeds.

- [ ] **Step 2: Add install permission to manifest**

In `android/app/src/main/AndroidManifest.xml`, next to the existing `<uses-permission>` entries (add one if none exist, directly under the root `<manifest>` tag):

```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
```

- [ ] **Step 3: Verify**

Run: `~/fvm/versions/stable/bin/flutter analyze --no-fatal-infos 2>&1 | tail -3`
Expected: no new errors (existing info-level lints OK).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml
git commit -m "chore(app-update): add open_filex, device_info_plus, path_provider; install permission"
```

---

### Task 2: Version compare function

**Files:**
- Create: `lib/features/app_update/domain/version_compare.dart`
- Test: `test/features/app_update/version_compare_test.dart`

**Interfaces:**
- Produces: `bool isNewerVersion(String currentVersion, String tagName)` — true iff tag's semver > current. Malformed input → false.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:cuentimobile/features/app_update/domain/version_compare.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('newer patch/minor/major detected', () {
    expect(isNewerVersion('2.0.4', 'v2.0.5'), isTrue);
    expect(isNewerVersion('2.0.4', 'v2.1.0'), isTrue);
    expect(isNewerVersion('2.0.4', 'v3.0.0'), isTrue);
  });

  test('equal or older is not newer', () {
    expect(isNewerVersion('2.0.4', 'v2.0.4'), isFalse);
    expect(isNewerVersion('2.0.4', 'v2.0.3'), isFalse);
    expect(isNewerVersion('2.1.0', 'v2.0.9'), isFalse);
  });

  test('build number and v prefix ignored', () {
    expect(isNewerVersion('2.0.4+12', 'v2.0.5'), isTrue);
    expect(isNewerVersion('2.0.4', '2.0.5'), isTrue);
  });

  test('malformed input is never newer', () {
    expect(isNewerVersion('2.0.4', 'nightly'), isFalse);
    expect(isNewerVersion('', 'v2.0.5'), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/fvm/versions/stable/bin/flutter test test/features/app_update/version_compare_test.dart`
Expected: FAIL — file/function missing.

- [ ] **Step 3: Write minimal implementation**

```dart
/// True iff [tagName] (e.g. 'v2.0.5') is a strictly newer semver than
/// [currentVersion] (e.g. '2.0.4' or '2.0.4+12'). Build numbers are
/// ignored; malformed input is never considered newer.
bool isNewerVersion(String currentVersion, String tagName) {
  List<int>? parse(String s) {
    final m = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)').firstMatch(s.trim());
    if (m == null) return null;
    return [int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!)];
  }

  final current = parse(currentVersion);
  final tag = parse(tagName);
  if (current == null || tag == null) return false;
  for (var i = 0; i < 3; i++) {
    if (tag[i] != current[i]) return tag[i] > current[i];
  }
  return false;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `~/fvm/versions/stable/bin/flutter test test/features/app_update/version_compare_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/app_update/domain/version_compare.dart test/features/app_update/version_compare_test.dart
git commit -m "feat(app-update): semver compare against release tag"
```

---

### Task 3: Release models + repository

**Files:**
- Create: `lib/features/app_update/domain/app_release.dart` (+ generated `.freezed.dart`/`.g.dart` via build_runner)
- Create: `lib/features/app_update/data/app_update_repository.dart`
- Test: `test/features/app_update/app_update_repository_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  - `ReleaseAsset { String name, String browserDownloadUrl, int size }`
  - `AppRelease { String tagName, String? body, List<ReleaseAsset> assets }`
  - `appUpdateRepositoryProvider` → `AppUpdateRepository`
  - `Future<AppRelease> getLatestRelease()`
  - `ReleaseAsset? pickAsset(AppRelease release, List<String> supportedAbis)`
  - `Future<String> downloadApk(ReleaseAsset asset, String savePath, void Function(int received, int total) onProgress)`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:cuentimobile/features/app_update/data/app_update_repository.dart';
import 'package:cuentimobile/features/app_update/domain/app_release.dart';
import 'package:dio/dio.dart';
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
    expect(release.assets.first.browserDownloadUrl,
        'https://example.com/arm64.apk');
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/fvm/versions/stable/bin/flutter test test/features/app_update/app_update_repository_test.dart`
Expected: FAIL — files missing.

- [ ] **Step 3: Write the model**

`lib/features/app_update/domain/app_release.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_release.freezed.dart';
part 'app_release.g.dart';

@freezed
abstract class ReleaseAsset with _$ReleaseAsset {
  const factory ReleaseAsset({
    @Default('') String name,
    @JsonKey(name: 'browser_download_url')
    @Default('')
    String browserDownloadUrl,
    @Default(0) int size,
  }) = _ReleaseAsset;

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) =>
      _$ReleaseAssetFromJson(json);
}

@freezed
abstract class AppRelease with _$AppRelease {
  const factory AppRelease({
    @JsonKey(name: 'tag_name') @Default('') String tagName,
    String? body,
    @Default([]) List<ReleaseAsset> assets,
  }) = _AppRelease;

  factory AppRelease.fromJson(Map<String, dynamic> json) =>
      _$AppReleaseFromJson(json);
}
```

Run: `~/fvm/versions/stable/bin/flutter pub run build_runner build`
Expected: generates `app_release.freezed.dart` and `app_release.g.dart`.

- [ ] **Step 4: Write the repository**

`lib/features/app_update/data/app_update_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../domain/app_release.dart';

/// Deliberately its own Dio: requests go to GitHub, so the backend client
/// with its auth interceptor must not be reused here.
final appUpdateRepositoryProvider = Provider<AppUpdateRepository>(
    (ref) => AppUpdateRepository(Dio()));

class AppUpdateRepository {
  AppUpdateRepository(this._dio);
  final Dio _dio;

  static const _latestUrl =
      'https://api.github.com/repos/13/cuenti_mobile/releases/latest';

  Future<AppRelease> getLatestRelease() => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          _latestUrl,
          options: Options(
            headers: {'Accept': 'application/vnd.github+json'},
          ),
        );
        return AppRelease.fromJson(res.data!);
      });

  /// First split APK matching a supported ABI (in ABI preference order),
  /// else the universal APK, else null.
  ReleaseAsset? pickAsset(AppRelease release, List<String> supportedAbis) {
    for (final abi in supportedAbis) {
      for (final asset in release.assets) {
        if (asset.name == 'app-$abi-release.apk') return asset;
      }
    }
    for (final asset in release.assets) {
      if (asset.name == 'app-release.apk') return asset;
    }
    return null;
  }

  Future<String> downloadApk(
    ReleaseAsset asset,
    String savePath,
    void Function(int received, int total) onProgress,
  ) =>
      _guard(() async {
        await _dio.download(
          asset.browserDownloadUrl,
          savePath,
          onReceiveProgress: onProgress,
        );
        return savePath;
      });
}

/// Shared guard: rethrows DioException as ApiException. Copy this exact
/// helper into each repository file (3 lines; a shared base class would
/// couple repositories for no gain).
Future<T> _guard<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `~/fvm/versions/stable/bin/flutter test test/features/app_update/app_update_repository_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/app_update test/features/app_update/app_update_repository_test.dart
git commit -m "feat(app-update): GitHub release model and repository"
```

---

### Task 4: Update flow UI + About screen integration

**Files:**
- Create: `lib/features/app_update/ui/update_check.dart`
- Modify: `lib/features/user/ui/about_screen.dart`
- Test: `test/features/app_update/update_check_test.dart`

**Interfaces:**
- Consumes: `appUpdateRepositoryProvider`, `isNewerVersion`, `AppRelease`, `ReleaseAsset` from Tasks 2–3.
- Produces:
  - `supportedAbisProvider` → `Future<List<String>>`
  - `downloadDirProvider` → `Future<Directory> Function()`
  - `apkInstallerProvider` → `Future<void> Function(String path)`
  - `Future<void> checkForUpdates(BuildContext context, WidgetRef ref)`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/app_update/data/app_update_repository.dart';
import 'package:cuentimobile/features/app_update/domain/app_release.dart';
import 'package:cuentimobile/features/app_update/ui/update_check.dart';
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
    when(() => repo.pickAsset(any(), any()))
        .thenReturn(_release.assets.first);
    when(() => repo.downloadApk(any(), any(), any()))
        .thenAnswer((invocation) async {
      final onProgress = invocation.positionalArguments[2]
          as void Function(int, int);
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
          downloadDirProvider.overrideWithValue(
            () async => Directory.systemTemp.createTemp('apk_test'),
          ),
          apkInstallerProvider.overrideWithValue(
            (path) async => installed.add(path),
          ),
        ],
        child: MaterialApp(
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

  testWidgets('newer release: dialog with notes, download, installer',
      (tester) async {
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
    when(() => repo.getLatestRelease()).thenAnswer(
        (_) async => const AppRelease(tagName: 'v2.0.4'));
    await pumpHost(tester);
    await tester.tap(find.text('check'));
    await tester.pumpAndSettle();

    expect(find.text("You're up to date"), findsOneWidget);
    expect(find.text('Update available'), findsNothing);
  });
}
```

Note: test file needs `import 'dart:io';` for `Directory`.

- [ ] **Step 2: Run test to verify it fails**

Run: `~/fvm/versions/stable/bin/flutter test test/features/app_update/update_check_test.dart`
Expected: FAIL — `update_check.dart` missing.

- [ ] **Step 3: Implement `lib/features/app_update/ui/update_check.dart`**

```dart
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../data/app_update_repository.dart';
import '../domain/app_release.dart';
import '../domain/version_compare.dart';

/// Injectable seams so widget tests can avoid platform channels.
final supportedAbisProvider = FutureProvider<List<String>>((ref) async {
  final info = await DeviceInfoPlugin().androidInfo;
  return info.supportedAbis;
});

final downloadDirProvider = Provider<Future<Directory> Function()>(
    (ref) => getTemporaryDirectory);

final apkInstallerProvider = Provider<Future<void> Function(String path)>(
    (ref) => (path) async => OpenFilex.open(path));

Future<void> checkForUpdates(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(appUpdateRepositoryProvider);
  try {
    final release = await repo.getLatestRelease();
    final current = (await PackageInfo.fromPlatform()).version;
    if (!isNewerVersion(current, release.tagName)) {
      messenger.showSnackBar(
        const SnackBar(content: Text("You're up to date")),
      );
      return;
    }
    final abis = await ref.read(supportedAbisProvider.future);
    final asset = repo.pickAsset(release, abis);
    if (asset == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No APK found in the latest release')),
      );
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _UpdateDialog(release: release, asset: asset),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text("Couldn't check for updates")),
    );
  }
}

class _UpdateDialog extends ConsumerStatefulWidget {
  const _UpdateDialog({required this.release, required this.asset});

  final AppRelease release;
  final ReleaseAsset asset;

  @override
  ConsumerState<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<_UpdateDialog> {
  double? _progress;
  String? _error;

  Future<void> _download() async {
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      final dir = await ref.read(downloadDirProvider)();
      final path = await ref.read(appUpdateRepositoryProvider).downloadApk(
            widget.asset,
            '${dir.path}/${widget.asset.name}',
            (received, total) {
              if (total > 0 && mounted) {
                setState(() => _progress = received / total);
              }
            },
          );
      await ref.read(apkInstallerProvider)(path);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _progress = null;
          _error = 'Download failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloading = _progress != null;
    return AlertDialog(
      title: const Text('Update available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.release.tagName} is ready to install.',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if ((widget.release.body ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Text(widget.release.body!),
              ),
            ),
          ],
          if (downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: downloading ? null : _download,
          child: Text(_error != null ? 'Retry' : 'Update'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `~/fvm/versions/stable/bin/flutter test test/features/app_update/update_check_test.dart`
Expected: PASS.

- [ ] **Step 5: Wire into About screen**

`lib/features/user/ui/about_screen.dart`: convert to `ConsumerStatefulWidget` and add a check-for-updates button to the Software Info card.

Class declaration changes:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_update/ui/update_check.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
```

In the Software Info card, after the `_infoRow` entries:

```dart
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => checkForUpdates(context, ref),
                    icon: const Icon(Icons.system_update_alt),
                    label: const Text('Check for updates'),
                  ),
                ),
```

- [ ] **Step 6: Full suite**

Run: `~/fvm/versions/stable/bin/flutter test`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/app_update lib/features/user/ui/about_screen.dart test/features/app_update/update_check_test.dart
git commit -m "feat(app-update): manual update check in About screen with download + install"
```
