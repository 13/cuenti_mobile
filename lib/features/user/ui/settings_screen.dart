import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/ui/auth_controller.dart';
import '../../currencies/domain/currency.dart';
import '../../currencies/ui/currencies_controller.dart';
import '../data/user_repository.dart';
import '../domain/user_profile.dart';
import 'user_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  static const _colorOptions = <String, Color>{
    'Purple': Color(0xFF6750A4),
    'Blue': Color(0xFF1565C0),
    'Green': Color(0xFF2E7D32),
    'Red': Color(0xFFC62828),
    'Orange': Color(0xFFEF6C00),
    'Teal': Color(0xFF00897B),
    'Pink': Color(0xFFAD1457),
    'Indigo': Color(0xFF283593),
  };

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
                Text('Profile', style: Theme.of(context).textTheme.titleMedium),
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
                Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: user.darkMode,
                  onChanged: (v) async {
                    await ref
                        .read(userRepositoryProvider)
                        .updatePreferences({'darkMode': v});
                    await auth.refreshProfile();
                  },
                ),
                ListTile(
                  title: const Text('Color Scheme'),
                  subtitle: Text(_colorOptions.entries
                      .firstWhere((e) => e.value.toARGB32() == authState.colorSchemeSeed.toARGB32(),
                          orElse: () => _colorOptions.entries.first)
                      .key),
                  trailing: CircleAvatar(
                    radius: 16,
                    backgroundColor: authState.colorSchemeSeed,
                  ),
                  onTap: () => _showColorPicker(context),
                ),
                ListTile(
                  title: const Text('Default Currency'),
                  trailing: Text(user.defaultCurrency,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    await ref
                        .read(userRepositoryProvider)
                        .updatePreferences({'apiEnabled': v});
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
                Text('Security', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Biometric Unlock'),
                  subtitle: const Text('Require fingerprint/face to reopen app'),
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
                Text('Server', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Connected to: ${auth.serverUrl}',
                    style: Theme.of(context).textTheme.bodySmall),
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

        // Admin section
        if (user.isAdmin) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Administration', style: Theme.of(context).textTheme.titleMedium),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Profile', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: firstName, decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: lastName, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(
                onPressed: () async {
                  try {
                    final auth = ref.read(authControllerProvider.notifier);
                    final nav = Navigator.of(ctx);
                    await ref.read(userRepositoryProvider).updateProfile(
                          email: email.text,
                          firstName: firstName.text,
                          lastName: lastName.text,
                        );
                    await auth.refreshProfile();
                    if (ctx.mounted) nav.pop();
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Save'),
              )),
            ]),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Change Password', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: oldPw, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: newPw, obscureText: true, decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: confirmPw, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(
                onPressed: () async {
                  if (newPw.text != confirmPw.text) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match')));
                    return;
                  }
                  try {
                    await ref
                        .read(userRepositoryProvider)
                        .updatePassword(oldPw.text, newPw.text);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password changed')));
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Change'),
              )),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final authState = ref.read(authControllerProvider);
    final auth = ref.read(authControllerProvider.notifier);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Color Scheme', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorOptions.entries.map((e) {
                final isSelected = e.value.toARGB32() == authState.colorSchemeSeed.toARGB32();
                return GestureDetector(
                  onTap: () {
                    auth.setColorSchemeSeed(e.value);
                    Navigator.pop(ctx);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: e.value,
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(e.key, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, List<Currency> currencies) {
    final auth = ref.read(authControllerProvider.notifier);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        children: currencies.map((c) => ListTile(
          leading: Text(c.symbol, style: const TextStyle(fontSize: 20)),
          title: Text('${c.code} - ${c.name}'),
          onTap: () async {
            final nav = Navigator.of(ctx);
            await ref
                .read(userRepositoryProvider)
                .updatePreferences({'defaultCurrency': c.code});
            await auth.refreshProfile();
            if (ctx.mounted) nav.pop();
          },
        )).toList(),
      ),
    );
  }

  void _showLocalePicker(BuildContext context) {
    final locales = ['en-US', 'de-DE', 'it-IT', 'fr-FR', 'es-ES'];
    final auth = ref.read(authControllerProvider.notifier);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        children: locales.map((l) => ListTile(
          title: Text(l),
          onTap: () async {
            final nav = Navigator.of(ctx);
            await ref
                .read(userRepositoryProvider)
                .updatePreferences({'locale': l});
            await auth.refreshProfile();
            if (ctx.mounted) nav.pop();
          },
        )).toList(),
      ),
    );
  }

  void _showAdminPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _AdminPanel(),
    );
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
          height: 300, child: Center(child: CircularProgressIndicator()));
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
          Text('Users (${users.length})', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...users.map((u) => ListTile(
            leading: CircleAvatar(
                child: Text(u.firstName.isNotEmpty
                    ? u.firstName[0].toUpperCase()
                    : '?')),
            title: Text('${u.firstName} ${u.lastName}'),
            subtitle: Text('${u.username} • ${u.roles.join(', ')}'),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _onUserAction(context, ref, u, action),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'enable', child: Text('Enable')),
                PopupMenuItem(value: 'disable', child: Text('Disable')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          )),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _onUserAction(
      BuildContext context, WidgetRef ref, UserProfile user, String action) async {
    final repo = ref.read(userRepositoryProvider);
    try {
      switch (action) {
        case 'enable':
          await repo.setUserEnabled(user.id!, true);
        case 'disable':
          await repo.setUserEnabled(user.id!, false);
        case 'delete':
          final confirmed = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  icon: const Icon(Icons.delete_outline),
                  title: const Text('Delete User?'),
                  content: Text('This will permanently remove ${user.username}.'),
                  actions: [
                    OutlinedButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(c).colorScheme.error,
                        foregroundColor: Theme.of(c).colorScheme.onError,
                      ),
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ) ??
              false;
          if (!confirmed) return;
          await repo.deleteUser(user.id!);
      }
      ref.invalidate(adminUsersProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
