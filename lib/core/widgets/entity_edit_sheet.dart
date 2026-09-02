import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The add/edit sheet the simple entity screens share: a title, the fields
/// the caller supplies, and a Cancel/Save row that disables both while the
/// save runs, closes and confirms on success, and reports a failure in the
/// user's language.
///
/// It existed six times over -- tags, payees, categories, currencies and
/// both settings sheets -- copied along with its error handling. That is
/// not a theoretical cost: when the wrong half of ApiException was used for
/// the failure message, it was wrong in five of those files at once,
/// because it had been copied into all five. This is the one place to make
/// that decision now.
///
/// `fields` is a builder rather than a list so a field that owns state --
/// the category parent dropdown, say -- can call its `rebuild` to redraw the
/// sheet without the caller managing a StatefulBuilder of its own.
Future<void> showEntityEditSheet({
  required BuildContext context,
  required String title,
  required List<Widget> Function(BuildContext context, VoidCallback rebuild)
  fields,
  required Future<void> Function() onSave,
  required String successMessage,
  String? saveLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _EntityEditSheet(
      title: title,
      fields: fields,
      onSave: onSave,
      successMessage: successMessage,
      saveLabel: saveLabel,
    ),
  );
}

class _EntityEditSheet extends StatefulWidget {
  const _EntityEditSheet({
    required this.title,
    required this.fields,
    required this.onSave,
    required this.successMessage,
    this.saveLabel,
  });

  final String title;
  final List<Widget> Function(BuildContext context, VoidCallback rebuild)
  fields;
  final Future<void> Function() onSave;
  final String successMessage;
  final String? saveLabel;

  @override
  State<_EntityEditSheet> createState() => _EntityEditSheetState();
}

class _EntityEditSheetState extends State<_EntityEditSheet> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    // Captured before the await: the save pops this sheet, leaving its own
    // context defunct, and the messenger belongs to the Scaffold above.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final colors = Theme.of(context).colorScheme;
    final l = L.of(context);
    try {
      await widget.onSave();
      if (!mounted) return;
      navigator.pop();
      showSuccessSnack(messenger, widget.successMessage);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnack(messenger, colors, e.localizedMessage(l));
      // Anything else is a platform or programming failure, whose
      // toString() is developer text rather than something to show anyone.
    } on Exception catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnack(messenger, colors, l.errorUnknown);
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
      // Scrollable because the taller forms -- payees, currencies -- do not
      // fit above the keyboard on a short phone, and a sheet that cannot be
      // scrolled to its Save button cannot be used at all.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...widget.fields(context, () => setState(() {})),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: Text(l.commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.saveLabel ?? l.commonSave),
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
}
