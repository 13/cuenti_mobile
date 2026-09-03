import 'dart:io';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/core/widgets/refresh_all.dart';
import 'package:cuentimobile/features/user/data/export_import_repository.dart';
import 'package:cuentimobile/features/user/ui/widgets/settings_sections.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Export and import of the whole account, and the two spinners that say one
/// is running.
///
/// It owns that state itself rather than the settings screen holding it:
/// this is the only part of that screen with any, and keeping it here is
/// what let the screen become a list of sections.
class DataSection extends ConsumerStatefulWidget {
  const DataSection({super.key});

  @override
  ConsumerState<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends ConsumerState<DataSection> {
  bool _exporting = false;
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SettingsSection(
      title: l.settingsData,
      children: [
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.upload_file),
          title: Text(l.settingsExportData),
          trailing: _exporting ? const _Spinner() : null,
          onTap: _exporting ? null : () => _exportData(context),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.download),
          title: Text(l.settingsImportData),
          trailing: _importing ? const _Spinner() : null,
          onTap: _importing ? null : () => _importData(context),
        ),
      ],
    );
  }

  /// Drops exports left by earlier runs, so at most one copy of the
  /// account's entire history sits in temp at a time.
  ///
  /// Done before writing rather than after sharing: the share sheet hands
  /// the file to another app, and deleting it the moment that call returns
  /// races whatever is still reading it.
  Future<void> _removeEarlierExports(Directory dir) async {
    try {
      for (final entry in dir.listSync()) {
        final name = entry.path.split(Platform.pathSeparator).last;
        if (entry is File &&
            name.startsWith('cuenti-export-') &&
            name.endsWith('.json')) {
          await entry.delete();
        }
      }
    } on FileSystemException catch (_) {
      // Housekeeping only: a temp directory that will not co-operate must
      // not stop the user exporting their data.
    }
  }

  Future<void> _exportData(BuildContext context) async {
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    final colors = Theme.of(context).colorScheme;
    final l = L.of(context);
    try {
      final json = await ref.read(exportImportRepositoryProvider).exportJson();
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      // The app's own temp directory, via path_provider, the way the
      // updater already does it: Directory.systemTemp is whatever the
      // platform makes of TMPDIR, and a complete financial export is not
      // the file to be relaxed about the location of.
      final dir = await getTemporaryDirectory();
      await _removeEarlierExports(dir);
      final path = '${dir.path}/cuenti-export-$date.json';
      await File(path).writeAsString(json);
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    } on ApiException catch (e) {
      showErrorSnack(messenger, colors, e.localizedMessage(l));
      // Unlike most failures this one names what went wrong: an export can
      // fail on the file system or the share sheet, and "an error occurred"
      // would leave the user nothing to act on.
    } on Exception catch (e) {
      showErrorSnack(messenger, colors, l.settingsExportFailed('$e'));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importData(BuildContext context) async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (file == null) return;
    if (!context.mounted) return;

    final confirmed = await showConfirmSheet(
      context,
      title: L.of(context).settingsImportTitle,
      message: L.of(context).settingsImportBody,
      confirmLabel: L.of(context).settingsImport,
    );
    if (!confirmed) return;
    if (!context.mounted) return;

    setState(() => _importing = true);
    final messenger = ScaffoldMessenger.of(context);
    final colors = Theme.of(context).colorScheme;
    final l = L.of(context);
    try {
      final json = await file.readAsString();
      await ref.read(exportImportRepositoryProvider).importJson(json);
      invalidateAllData(ref);
      messenger.showSnackBar(
        SnackBar(content: Text(l.settingsImportComplete)),
      );
    } on ApiException catch (e) {
      showErrorSnack(messenger, colors, e.localizedMessage(l));
    } on Exception catch (e) {
      showErrorSnack(messenger, colors, l.settingsImportFailed('$e'));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
