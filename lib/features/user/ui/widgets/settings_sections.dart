import 'dart:async';

import 'package:cuentimobile/core/widgets/section_header.dart';
import 'package:cuentimobile/features/app_update/data/update_preferences.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:cuentimobile/features/currencies/ui/currencies_controller.dart';
import 'package:cuentimobile/features/user/data/user_repository.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/features/user/ui/widgets/admin_panel.dart';
import 'package:cuentimobile/features/user/ui/widgets/change_password_sheet.dart';
import 'package:cuentimobile/features/user/ui/widgets/edit_profile_sheet.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One titled card on the settings screen.
///
/// The Card / Padding / Column / SectionHeader nest was written out six
/// times in a row, which is most of what made that screen long.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [SectionHeader(title), ...children],
        ),
      ),
    );
  }
}

/// Both editing sheets are keyboard-facing, so they need the scroll control
/// that lets the padding lift them clear of it.
void _showSheet(BuildContext context, Widget sheet) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => sheet,
    ),
  );
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({required this.user, super.key});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: L.of(context).settingsProfile,
      children: [
        const SizedBox(height: 12),
        _InfoRow(label: L.of(context).commonUsername, value: user.username),
        _InfoRow(
          label: L.of(context).commonName,
          value: '${user.firstName} ${user.lastName}',
        ),
        _InfoRow(label: L.of(context).commonEmail, value: user.email),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () => _showSheet(context, EditProfileSheet(user: user)),
          child: Text(L.of(context).settingsEditProfile),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
}

class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({required this.user, super.key});

  final UserProfile user;

  Future<void> _setPreference(WidgetRef ref, Map<String, Object?> value) async {
    await ref.read(userRepositoryProvider).updatePreferences(value);
    await ref.read(authControllerProvider.notifier).refreshProfile();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final currencies = ref.watch(currenciesControllerProvider).value ?? [];

    return SettingsSection(
      title: l.settingsPreferences,
      children: [
        const SizedBox(height: 12),
        SwitchListTile(
          title: Text(l.settingsDarkMode),
          value: user.darkMode,
          onChanged: (v) => _setPreference(ref, {'darkMode': v}),
        ),
        ListTile(
          title: Text(l.settingsDefaultCurrency),
          trailing: Text(
            user.defaultCurrency,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () => _showCurrencyPicker(context, ref, currencies),
        ),
        ListTile(
          title: Text(l.settingsLocale),
          trailing: Text(user.locale),
          onTap: () => _showLocalePicker(context, ref),
        ),
        SwitchListTile(
          title: Text(l.settingsAutoUpdate),
          subtitle: Text(l.settingsAutoUpdateSubtitle),
          // Defaults to on while the stored value is still loading: the
          // switch must not flicker off and read as disabled.
          value: ref.watch(autoUpdateCheckProvider).value ?? true,
          onChanged: (v) => unawaited(
            ref.read(autoUpdateCheckProvider.notifier).set(enabled: v),
          ),
        ),
        SwitchListTile(
          title: Text(l.settingsApiAccess),
          subtitle: Text(l.settingsApiAccessSubtitle),
          value: user.apiEnabled,
          onChanged: (v) => _setPreference(ref, {'apiEnabled': v}),
        ),
      ],
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    WidgetRef ref,
    List<Currency> currencies,
  ) {
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
                    await _setPreference(ref, {'defaultCurrency': c.code});
                    if (ctx.mounted) nav.pop();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showLocalePicker(BuildContext context, WidgetRef ref) {
    // The locales the app actually speaks. It previously also offered
    // fr-FR and es-ES, which only ever changed number formatting and left
    // the interface in English; an option that half works reads as a bug.
    const locales = {
      'en-US': 'English',
      'de-DE': 'Deutsch',
      'it-IT': 'Italiano',
    };
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
                    await _setPreference(ref, {'locale': entry.key});
                    if (ctx.mounted) nav.pop();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final enabled = ref.watch(authControllerProvider).biometricEnabled;
    final auth = ref.read(authControllerProvider.notifier);

    return SettingsSection(
      title: l.settingsSecurity,
      children: [
        const SizedBox(height: 12),
        SwitchListTile(
          title: Text(l.settingsBiometric),
          subtitle: Text(l.settingsBiometricSubtitle),
          value: enabled,
          onChanged: (v) => unawaited(auth.setBiometricEnabled(enabled: v)),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () => _showSheet(context, const ChangePasswordSheet()),
          child: Text(l.settingsChangePassword),
        ),
      ],
    );
  }
}

class ServerSection extends ConsumerWidget {
  const ServerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final auth = ref.read(authControllerProvider.notifier);

    return SettingsSection(
      title: l.settingsServer,
      children: [
        const SizedBox(height: 8),
        Text(
          l.settingsConnectedTo(auth.serverUrl),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.go('/server-setup'),
          child: Text(l.serverChange),
        ),
      ],
    );
  }
}

class AdminSection extends StatelessWidget {
  const AdminSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: L.of(context).settingsAdministration,
      children: [
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () => unawaited(
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AdminPanel(),
            ),
          ),
          child: Text(L.of(context).settingsAdminPanel),
        ),
      ],
    );
  }
}
