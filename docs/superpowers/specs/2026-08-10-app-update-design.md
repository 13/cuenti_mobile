# In-App Update from GitHub Releases — Design

Date: 2026-08-10
Status: approved

## Goal

Manual "Check for updates" in the About screen. The app compares its own
version against the latest GitHub release of `13/cuenti_mobile`, and when a
newer release exists it shows the version + release notes, downloads the
ABI-matched APK with progress, and hands the file to the Android package
installer.

## Decisions

- **Trigger:** manual only — no startup/background checks.
- **Asset selection:** ABI-matched split APK (`app-<abi>-release.apk`),
  falling back to the universal `app-release.apk` when no ABI match exists.
- **Flow detail:** dialog shows new version and GitHub release notes, inline
  download progress bar, then launches the installer.
- **Install:** Android never allows silent install; the user grants
  "install unknown apps" once and confirms the system install dialog.

## Architecture

New feature directory `lib/features/app_update/`:

- `domain/app_release.dart` — freezed models:
  - `AppRelease { String tagName, String? body, List<ReleaseAsset> assets }`
  - `ReleaseAsset { String name, String browserDownloadUrl, int size }`
- `data/app_update_repository.dart`
  - Own `Dio` instance (GitHub, not the backend — the app's auth interceptor
    must not leak tokens there).
  - `Future<AppRelease> getLatestRelease()` — GET
    `https://api.github.com/repos/13/cuenti_mobile/releases/latest`.
  - `Future<String> downloadApk(ReleaseAsset asset, String savePath, void Function(int, int) onProgress)`
    — `Dio.download` to the app cache dir, returns the file path.
  - `pickAsset(AppRelease, List<String> supportedAbis)` — first split APK
    whose name contains a supported ABI, else universal, else null.
- `domain/version_compare.dart` — pure function
  `bool isNewer(String currentVersion, String tagName)`; strips leading `v`,
  compares numeric semver fields, ignores build number (`+NN`).
- `ui/update_check.dart` — `checkForUpdates(BuildContext, WidgetRef)`:
  current version via `package_info_plus`, ABIs via `device_info_plus`
  (`androidInfo.supportedAbis`), then dialog → download → installer via
  `open_filex`. Installer launch wrapped in an injectable callback so widget
  tests stop at that boundary.
- About screen gets a "Check for updates" tile invoking the flow.

## Platform changes

- `AndroidManifest.xml`: `<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>`
- `open_filex` ships its own FileProvider; no manual provider config.

## Error handling

- Check fails (offline, rate limit): snackbar "Couldn't check for updates".
- Up to date: snackbar "You're up to date".
- No usable asset: snackbar with link-out suggestion (open releases page).
- Download failure: error state in dialog with Retry.

## Dependencies added

`open_filex`, `device_info_plus`.

## Testing

- `version_compare` unit tests (newer/older/equal, build-number ignored,
  malformed tags).
- Repository tests with mocked Dio adapter (existing `fake_dio` pattern):
  release parsing, asset pick per ABI + universal fallback.
- Widget test for the About tile flow with mocked repository: dialog shows
  version + notes, progress, installer callback receives the downloaded path.
