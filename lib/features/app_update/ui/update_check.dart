import 'dart:io';

import 'package:cuentimobile/features/app_update/data/app_update_repository.dart';
import 'package:cuentimobile/features/app_update/domain/app_release.dart';
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

Future<void> checkForUpdates(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  // Captured alongside the messenger, for the same reason: both are read
  // from context, and the awaits below outlive it.
  final l = L.of(context);
  final repo = ref.read(appUpdateRepositoryProvider);
  try {
    final release = await repo.getLatestRelease();
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
          _error = 'Download failed';
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
          child: Text(L.of(context).updateLater),
        ),
        FilledButton(
          onPressed: downloading ? null : _download,
          child: Text(_error != null ? 'Retry' : 'Update'),
        ),
      ],
    );
  }
}
