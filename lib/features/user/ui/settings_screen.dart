import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/refresh_all.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/ui/auth_controller.dart';
import '../../currencies/domain/currency.dart';
import '../../currencies/ui/currencies_controller.dart';
import '../data/export_import_repository.dart';
import '../data/user_repository.dart';
import '../domain/user_profile.dart';
import 'user_controller.dart';

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

    if (user == null) return const Center(child: Text('Not logged in'));

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
                const SectionHeader('Profile'),
                const SizedBox(height: 12),
                _infoRow('Username', user.username),
                _infoRow('Name', '${user.firstName} ${user.lastName}'),
                _infoRow('Email', user.email),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => _showEditProfileDialog(context, user),
                  child: const Text('Edit Profile'),
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
                const SectionHeader('Preferences'),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: user.darkMode,
                  onChanged: (v) async {
                    await ref.read(userRepositoryProvider).updatePreferences({
                      'darkMode': v,
                    });
                    await auth.refreshProfile();
                  },
                ),
                ListTile(
                  title: const Text('Default Currency'),
                  trailing: Text(
                    user.defaultCurrency,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _showCurrencyPicker(context, currencies),
                ),
                ListTile(
                  title: const Text('Locale'),
                  trailing: Text(user.locale),
                  onTap: () => _showLocalePicker(context),
                ),
                SwitchListTile(
                  title: const Text('API Access'),
                  subtitle: const Text('Enable API access for this account'),
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
                const SectionHeader('Security'),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Biometric Unlock'),
                  subtitle: const Text(
                    'Require fingerprint/face to reopen app',
                  ),
                  value: authState.biometricEnabled,
                  onChanged: (v) => auth.setBiometricEnabled(v),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => _showChangePasswordDialog(context),
                  child: const Text('Change Password'),
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
                const SectionHeader('Server'),
                const SizedBox(height: 8),
                Text(
                  'Connected to: ${auth.serverUrl}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.go('/server-setup'),
                  child: const Text('Change Server'),
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
                const SectionHeader('Data'),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Export data'),
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
                  title: const Text('Import data'),
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
                  const SectionHeader('Administration'),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => _showAdminPanel(context),
                    child: const Text('Admin Panel'),
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
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/about'),
          ),
        ),
        const SizedBox(height: 12),

        // Logout
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              auth.logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ),
      ],
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

  void _showEditProfileDialog(BuildContext context, UserProfile user) {
    final firstName = TextEditingController(text: user.firstName);
    final lastName = TextEditingController(text: user.lastName);
    final email = TextEditingController(text: user.email);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Profile', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: firstName,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastName,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        final auth = ref.read(authControllerProvider.notifier);
                        final nav = Navigator.of(ctx);
                        await ref
                            .read(userRepositoryProvider)
                            .updateProfile(
                              email: email.text,
                              firstName: firstName.text,
                              lastName: lastName.text,
                            );
                        await auth.refreshProfile();
                        if (ctx.mounted) nav.pop();
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPw = TextEditingController();
    final newPw = TextEditingController();
    final confirmPw = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Change Password', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: oldPw,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPw,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPw,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      if (newPw.text != confirmPw.text) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                          ),
                        );
                        return;
                      }
                      try {
                        await ref
                            .read(userRepositoryProvider)
                            .updatePassword(oldPw.text, newPw.text);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password changed')),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    child: const Text('Change'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, List<Currency> currencies) {
    final auth = ref.read(authControllerProvider.notifier);
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
    );
  }

  void _showLocalePicker(BuildContext context) {
    final locales = ['en-US', 'de-DE', 'it-IT', 'fr-FR', 'es-ES'];
    final auth = ref.read(authControllerProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => ListView(
        children: locales
            .map(
              (l) => ListTile(
                title: Text(l),
                onTap: () async {
                  final nav = Navigator.of(ctx);
                  await ref.read(userRepositoryProvider).updatePreferences({
                    'locale': l,
                  });
                  await auth.refreshProfile();
                  if (ctx.mounted) nav.pop();
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showAdminPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _AdminPanel(),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    setState(() => _exporting = true);
    try {
      final json = await ref.read(exportImportRepositoryProvider).exportJson();
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final path = '${Directory.systemTemp.path}/cuenti-export-$date.json';
      await File(path).writeAsString(json);
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
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
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (file == null) return;
    if (!context.mounted) return;

    final confirmed = await showConfirmSheet(
      context,
      title: 'Import data?',
      message: 'This replaces data on the server with the file contents.',
      confirmLabel: 'Import',
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
        ).showSnackBar(const SnackBar(content: Text('Import complete')));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }
}

class _AdminPanel extends ConsumerWidget {
  const _AdminPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final settingsAsync = ref.watch(adminSettingsProvider);

    if (usersAsync.isLoading || settingsAsync.isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final users = usersAsync.value ?? [];
    final settings = settingsAsync.value;
    final registrationEnabled = settings?.registrationEnabled ?? true;
    final apiEnabled = settings?.apiEnabled ?? false;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Administration', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Registration Enabled'),
            value: registrationEnabled,
            onChanged: (v) async {
              await ref
                  .read(userRepositoryProvider)
                  .updateAdminSettings(registrationEnabled: v);
              ref.invalidate(adminSettingsProvider);
            },
          ),
          SwitchListTile(
            title: const Text('Global API Enabled'),
            value: apiEnabled,
            onChanged: (v) async {
              await ref
                  .read(userRepositoryProvider)
                  .updateAdminSettings(apiEnabled: v);
              ref.invalidate(adminSettingsProvider);
            },
          ),
          const Divider(),
          Text(
            'Users (${users.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...users.map(
            (u) => ListTile(
              leading: CircleAvatar(child: Text(u.firstName[0].toUpperCase())),
              title: Text('${u.firstName} ${u.lastName}'),
              subtitle: Text('${u.username} • ${u.roles.join(', ')}'),
              trailing: Text(
                u.apiEnabled ? 'API ✓' : '',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
