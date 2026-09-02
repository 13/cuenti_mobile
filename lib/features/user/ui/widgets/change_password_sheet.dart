import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/user/data/user_repository.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Changes the signed-in user's password, checking the confirmation matches
/// before troubling the server with it.
class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  ConsumerState<ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (_next.text != _confirm.text) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.settingsPasswordsMismatch)),
      );
      return;
    }
    try {
      await ref
          .read(userRepositoryProvider)
          .updatePassword(_current.text, _next.text);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l.settingsPasswordChanged)),
      );
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
            l.settingsChangePassword,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _field(_current, l.settingsCurrentPassword),
          const SizedBox(height: 12),
          _field(_next, l.settingsNewPassword),
          const SizedBox(height: 12),
          _field(_confirm, l.settingsConfirmNewPassword),
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
                  onPressed: _change,
                  child: Text(l.settingsChange),
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
    obscureText: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );
}
