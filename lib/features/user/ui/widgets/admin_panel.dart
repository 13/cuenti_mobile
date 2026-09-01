import 'dart:async';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/user/data/user_repository.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/features/user/ui/user_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminPanel extends ConsumerWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final settingsAsync = ref.watch(adminSettingsProvider);
    final authState = ref.watch(authControllerProvider);

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
          Text(
            L.of(context).settingsAdministration,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(L.of(context).settingsRegistrationEnabled),
            value: registrationEnabled,
            onChanged: (v) async {
              await ref
                  .read(userRepositoryProvider)
                  .updateAdminSettings(registrationEnabled: v);
              ref.invalidate(adminSettingsProvider);
            },
          ),
          SwitchListTile(
            title: Text(L.of(context).settingsGlobalApiEnabled),
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
            L.of(context).settingsUsersCount('${users.length}'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...users.map(
            (u) {
              // Positive, null-safe gate: only show the actions menu when we
              // know who the current user is AND this row is someone else.
              // A null auth user must never expose the menu.
              final showMenu =
                  authState.user != null &&
                  u.username != authState.user!.username;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(u.firstName[0].toUpperCase()),
                ),
                title: Text('${u.firstName} ${u.lastName}'),
                subtitle: Text('${u.username} • ${u.roles.join(', ')}'),
                trailing: !showMenu
                    ? Text(
                        u.apiEnabled ? 'API ✓' : '',
                        style: const TextStyle(fontSize: 12),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            u.apiEnabled ? 'API ✓' : '',
                            style: const TextStyle(fontSize: 12),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (action) =>
                                _onUserAction(context, ref, u, action),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'enable',
                                child: Text(L.of(context).settingsEnable),
                              ),
                              PopupMenuItem(
                                value: 'disable',
                                child: Text(L.of(context).settingsDisable),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(L.of(context).commonDelete),
                              ),
                            ],
                          ),
                        ],
                      ),
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L.of(context).commonClose),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _onUserAction(
    BuildContext context,
    WidgetRef ref,
    UserProfile user,
    String action,
  ) async {
    final repo = ref.read(userRepositoryProvider);
    try {
      switch (action) {
        case 'enable':
          await repo.setUserEnabled(user.id!, enabled: true);
        case 'disable':
          await repo.setUserEnabled(user.id!, enabled: false);
        case 'delete':
          final confirmed = await showConfirmSheet(
            context,
            title: L.of(context).settingsDeleteUserTitle(user.username),
            message: L.of(context).settingsDeleteUserBody,
          );
          if (!confirmed) return;
          await repo.deleteUser(user.id!);
      }
      if (context.mounted) ref.invalidate(adminUsersProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.localizedMessage(L.of(context))),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
