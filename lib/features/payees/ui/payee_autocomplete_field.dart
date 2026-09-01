import 'package:cuentimobile/features/payees/domain/payee.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/token_search.dart';
import 'package:flutter/material.dart';

/// Payee entry with suggestions from the payees the account already knows.
///
/// Deliberately not a picker: a payee may be new, so anything the user types
/// stands. The suggestions only save retyping an existing one exactly, which
/// is what keeps the same shop from accumulating spelling variants.
class PayeeAutocompleteField extends StatefulWidget {
  const PayeeAutocompleteField({
    required this.controller,
    required this.payees,
    super.key,
    this.labelText,
  });

  final TextEditingController controller;
  final List<Payee> payees;

  /// Null takes the localised default; a const parameter cannot hold one.
  final String? labelText;

  @override
  State<PayeeAutocompleteField> createState() => _PayeeAutocompleteFieldState();
}

class _PayeeAutocompleteFieldState extends State<PayeeAutocompleteField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Iterable<Payee> _suggestions(TextEditingValue value) {
    // Nothing typed yet means no suggestions rather than the whole address
    // book: an overlay covering the form on focus helps nobody.
    if (value.text.trim().isEmpty) return const [];
    return widget.payees.where((p) => matchesAllTokens(p.name, value.text));
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Payee>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: _suggestions,
      displayStringForOption: (payee) => payee.name,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) =>
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            onFieldSubmitted: (_) => onFieldSubmitted(),
            decoration: InputDecoration(
              labelText: widget.labelText ?? L.of(context).payeeLabel,
              border: const OutlineInputBorder(),
            ),
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: options.length,
              itemBuilder: (context, i) {
                final payee = options.elementAt(i);
                return ListTile(
                  dense: true,
                  title: Text(payee.name),
                  onTap: () => onSelected(payee),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
