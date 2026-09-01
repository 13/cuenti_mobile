import 'dart:io';

import 'package:cuentimobile/features/app_update/data/app_update_repository.dart';
import 'package:cuentimobile/features/app_update/data/update_preferences.dart';
import 'package:cuentimobile/features/app_update/domain/app_release.dart';
import 'package:cuentimobile/features/app_update/domain/update_policy.dart';
import 'package:cuentimobile/features/app_update/domain/version_compare.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Injectable seams so widget tests can avoid platform channels.
final supportedAbisProvider = FutureProvider<List<String>>((ref) async {
  final info = await DeviceInfoPlugin().androidInfo;
  return info.supportedAbis;
});

final downloadDirProvider = Provider<Future<Directory> Function()>(
  (ref) => getTemporaryDirectory,
);

final apkInstallerProvider = Provider<Future<void> Function(String path)>(
  (ref) =>
      (path) async => OpenFilex.open(path),
);

/// The automatic check, run on launch and on resume.
///
/// Silent unless it has news: no "up to date" confirmation, no error when
/// GitHub is unreachable. A dialog about a new version is welcome at launch;
/// a snackbar about a failed background request is not, and the manual check
/// in About exists for anyone who wants the answer either way.
Future<void> maybeCheckForUpdates(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(updatePreferencesProvider);
  if (!await prefs.autoCheckEnabled()) return;
  if (!shouldCheck(
    lastChecked: await prefs.lastChecked(),
    now: DateTime.now(),
  )) {
    return;
  }
  final repo = ref.read(appUpdateRepositoryProvider);
  try {
    final release = await repo.getLatestRelease();
    // Recorded before deciding whether to prompt: the point of the throttle
    // is to rate-limit GitHub, and the request has already happened.
    await prefs.setLastChecked(DateTime.now());
    final current = (await PackageInfo.fromPlatform()).version;
    if (!shouldPrompt(
      currentVersion: current,
      tagName: release.tagName,
      skippedVersion: await prefs.skippedVersion(),
    )) {
      return;
    }
    final abis = await ref.read(supportedAbisProvider.future);
    final asset = repo.pickAsset(release, abis);
    if (asset == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _UpdateDialog(release: release, asset: asset),
    );
  } on Exception catch (_) {
    // Nothing to say: the user did not ask.
  }
}

/// The manual check from About. Always asks, always answers -- including
/// "you're up to date" -- and ignores both the throttle and any skipped
/// version, because the user just asked the question out loud.
Future<void> checkForUpdates(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  // Captured alongside the messenger, for the same reason: both are read
  // from context, and the awaits below outlive it.
  final l = L.of(context);
  final repo = ref.read(appUpdateRepositoryProvider);
  try {
    final release = await repo.getLatestRelease();
    await ref.read(updatePreferencesProvider).setLastChecked(DateTime.now());
    final current = (await PackageInfo.fromPlatform()).version;
    if (!isNewerVersion(current, release.tagName)) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.updateUpToDate)),
      );
      return;
    }
    final abis = await ref.read(supportedAbisProvider.future);
    final asset = repo.pickAsset(release, abis);
    if (asset == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.updateNoApk)),
      );
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _UpdateDialog(release: release, asset: asset),
    );
  } on Exception catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(l.updateCheckFailed)),
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

  /// Records the tag so the automatic check stops raising it. Without this
  /// an automatic check re-asks about the same release on every launch,
  /// which is how people learn to dismiss updates without reading them.
  Future<void> _skip() async {
    await ref
        .read(updatePreferencesProvider)
        .skipVersion(widget.release.tagName);
    if (mounted) Navigator.pop(context);
  }

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
    } on Exception catch (_) {
      if (mounted) {
        setState(() {
          _progress = null;
          _error = L.of(context).updateDownloadFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloading = _progress != null;
    return AlertDialog(
      title: Text(L.of(context).updateAvailable),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.of(context).updateReady(widget.release.tagName),
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
          onPressed: downloading ? null : _skip,
          child: Text(L.of(context).updateSkipVersion),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(L.of(context).updateLater),
        ),
        FilledButton(
          onPressed: downloading ? null : _download,
          child: Text(
            _error != null
                ? L.of(context).commonRetry
                : L.of(context).updateInstall,
          ),
        ),
      ],
    );
  }
}
