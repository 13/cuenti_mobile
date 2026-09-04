import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/auth/ui/sign_out.dart';
import 'package:cuentimobile/features/user/ui/widgets/data_section.dart';
import 'package:cuentimobile/features/user/ui/widgets/settings_sections.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The settings screen is a list of sections and little else.
///
/// Each section owns whatever it needs -- its own providers, its own sheets,
/// and in the case of export/import its own state -- so this file says what
/// the screen is made of rather than how any of it works.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    if (user == null) {
      return Center(child: Text(L.of(context).settingsNotLoggedIn));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ProfileSection(user: user),
        const SizedBox(height: 12),
        PreferencesSection(user: user),
        const SizedBox(height: 12),
        const SecuritySection(),
        const SizedBox(height: 12),
        const ServerSection(),
        const SizedBox(height: 12),
        const DataSection(),
        const SizedBox(height: 12),
        if (user.isAdmin) ...[
          const AdminSection(),
          const SizedBox(height: 12),
        ],
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(L.of(context).settingsAbout),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/about'),
          ),
        ),
        const SizedBox(height: 12),
        const _LogoutButton(),
      ],
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          // Captured before the gap, and the flow itself is shared with the
          // drawer's Logout: see sign_out.dart.
          final router = GoRouter.of(context);
          if (!await confirmSignOut(context, ref)) return;
          await signOut(ref);
          router.go('/login');
        },
        icon: const Icon(Icons.logout),
        label: Text(L.of(context).actionLogout),
      ),
    );
  }
}
