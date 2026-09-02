import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/user/data/user_repository.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Edits the signed-in user's name and email, then refreshes the profile so
/// the settings screen shows what the server stored rather than what was
/// typed.
class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({required this.user, super.key});

  final UserProfile user;

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final _firstName = TextEditingController(text: widget.user.firstName);
  late final _lastName = TextEditingController(text: widget.user.lastName);
  late final _email = TextEditingController(text: widget.user.email);

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(userRepositoryProvider)
          .updateProfile(
            email: _email.text,
            firstName: _firstName.text,
            lastName: _lastName.text,
          );
      await ref.read(authControllerProvider.notifier).refreshProfile();
      if (mounted) navigator.pop();
    } on ApiException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(e.localizedMessage(l))),
        );
      }
      // Anything that is not an ApiException is a platform or programming
      // failure, whose toString() is developer text -- not something to put
      // in front of someone in any language.
    } on Exception catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l.errorUnknown)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.settingsEditProfile,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _field(_firstName, l.commonFirstName),
          const SizedBox(height: 12),
          _field(_lastName, l.commonLastName),
          const SizedBox(height: 12),
          _field(_email, l.commonEmail),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.commonCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: Text(l.commonSave),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) => TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );
}
