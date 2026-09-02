import 'dart:async';
import 'dart:io';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/core/widgets/refresh_all.dart';
import 'package:cuentimobile/core/widgets/section_header.dart';
import 'package:cuentimobile/features/app_update/data/update_preferences.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:cuentimobile/features/currencies/ui/currencies_controller.dart';
import 'package:cuentimobile/features/user/data/export_import_repository.dart';
import 'package:cuentimobile/features/user/data/user_repository.dart';
import 'package:cuentimobile/features/user/ui/widgets/admin_panel.dart';
import 'package:cuentimobile/features/user/ui/widgets/change_password_sheet.dart';
import 'package:cuentimobile/features/user/ui/widgets/edit_profile_sheet.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exporting = false;
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final auth = ref.read(authControllerProvider.notifier);
    final user = authState.user;
    final currencies = ref.watch(currenciesControllerProvider).value ?? [];

    if (user == null) {
      return Center(child: Text(L.of(context).settingsNotLoggedIn));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User Profile Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(L.of(context).settingsProfile),
                const SizedBox(height: 12),
                _infoRow('Username', user.username),
                _infoRow('Name', '${user.firstName} ${user.lastName}'),
                _infoRow('Email', user.email),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => _showSheet(EditProfileSheet(user: user)),
                  child: Text(L.of(context).settingsEditProfile),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Preferences Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(L.of(context).settingsPreferences),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(L.of(context).settingsDarkMode),
                  value: user.darkMode,
                  onChanged: (v) async {
                    await ref.read(userRepositoryProvider).updatePreferences({
                      'darkMode': v,
                    });
                    await auth.refreshProfile();
                  },
                ),
                ListTile(
                  title: Text(L.of(context).settingsDefaultCurrency),
                  trailing: Text(
                    user.defaultCurrency,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _showCurrencyPicker(context, currencies),
                ),
                ListTile(
                  title: Text(L.of(context).settingsLocale),
                  trailing: Text(user.locale),
                  onTap: () => _showLocalePicker(context),
                ),
                SwitchListTile(
                  title: Text(L.of(context).settingsAutoUpdate),
                  subtitle: Text(L.of(context).settingsAutoUpdateSubtitle),
                  // Defaults to on while the stored value is still loading:
                  // the switch must not flicker off and read as disabled.
                  value: ref.watch(autoUpdateCheckProvider).value ?? true,
                  onChanged: (v) => unawaited(
                    ref.read(autoUpdateCheckProvider.notifier).set(enabled: v),
                  ),
                ),
                SwitchListTile(
                  title: Text(L.of(context).settingsApiAccess),
                  subtitle: Text(L.of(context).settingsApiAccessSubtitle),
                  value: user.apiEnabled,
                  onChanged: (v) async {
                    await ref.read(userRepositoryProvider).updatePreferences({
                      'apiEnabled': v,
                    });
                    await auth.refreshProfile();
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Security
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(L.of(context).settingsSecurity),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(L.of(context).settingsBiometric),
                  subtitle: Text(
                    L.of(context).settingsBiometricSubtitle,
                  ),
                  value: authState.biometricEnabled,
                  onChanged: (v) =>
                      unawaited(auth.setBiometricEnabled(enabled: v)),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => _showSheet(const ChangePasswordSheet()),
                  child: Text(L.of(context).settingsChangePassword),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Server
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(L.of(context).settingsServer),
                const SizedBox(height: 8),
                Text(
                  L.of(context).settingsConnectedTo(auth.serverUrl),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.go('/server-setup'),
                  child: Text(L.of(context).serverChange),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Data (export/import)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(L.of(context).settingsData),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.upload_file),
                  title: Text(L.of(context).settingsExportData),
                  trailing: _exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _exporting ? null : () => _exportData(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download),
                  title: Text(L.of(context).settingsImportData),
                  trailing: _importing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _importing ? null : () => _importData(context),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Admin section
        if (user.isAdmin) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(L.of(context).settingsAdministration),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => _showAdminPanel(context),
                    child: Text(L.of(context).settingsAdminPanel),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // About section
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(L.of(context).settingsAbout),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/about'),
          ),
        ),
        const SizedBox(height: 12),

        // Logout
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              // Land on the login screen only once the token and the saved
              // credentials are actually gone, so a fresh sign-in cannot
              // race the wipe.
              final router = GoRouter.of(context);
              await auth.logout();
              router.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: Text(L.of(context).actionLogout),
          ),
        ),
      ],
    );
  }

  /// Both editing sheets are keyboard-facing, so they need the scroll
  /// control that lets the padding lift them clear of it.
  void _showSheet(Widget sheet) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => sheet,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, List<Currency> currencies) {
    final auth = ref.read(authControllerProvider.notifier);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => ListView(
          children: currencies
              .map(
                (c) => ListTile(
                  leading: Text(c.symbol, style: const TextStyle(fontSize: 20)),
                  title: Text('${c.code} - ${c.name}'),
                  onTap: () async {
                    final nav = Navigator.of(ctx);
                    await ref.read(userRepositoryProvider).updatePreferences({
                      'defaultCurrency': c.code,
                    });
                    await auth.refreshProfile();
                    if (ctx.mounted) nav.pop();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showLocalePicker(BuildContext context) {
    // The locales the app actually speaks. It previously also offered
    // fr-FR and es-ES, which only ever changed number formatting and left
    // the interface in English; an option that half works reads as a bug.
    const locales = {
      'en-US': 'English',
      'de-DE': 'Deutsch',
      'it-IT': 'Italiano',
    };
    final auth = ref.read(authControllerProvider.notifier);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => ListView(
          children: locales.entries
              .map(
                (entry) => ListTile(
                  title: Text(entry.value),
                  subtitle: Text(entry.key),
                  onTap: () async {
                    final nav = Navigator.of(ctx);
                    await ref.read(userRepositoryProvider).updatePreferences({
                      'locale': entry.key,
                    });
                    await auth.refreshProfile();
                    if (ctx.mounted) nav.pop();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showAdminPanel(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => const AdminPanel(),
      ),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.localizedMessage(L.of(context))),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L.of(context).settingsExportFailed('$e')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
    try {
      final json = await file.readAsString();
      await ref.read(exportImportRepositoryProvider).importJson(json);
      invalidateAllData(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(L.of(context).settingsImportComplete)),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.localizedMessage(L.of(context))),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L.of(context).settingsImportFailed('$e')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }
}
