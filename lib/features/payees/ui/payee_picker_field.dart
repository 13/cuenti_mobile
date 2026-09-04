import 'dart:async';

import 'package:cuentimobile/core/widgets/search_create_sheet.dart';
import 'package:cuentimobile/features/payees/domain/payee.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Payee entry, the same shape as the category picker: a sheet you search,
/// pick from, and can add to.
///
/// It replaces an inline autocomplete that was deliberately free-text --
/// "a payee may be new, so anything the user types stands". That intent
/// survives here: creating a payee that the server refuses still puts the
/// typed name on the transaction, because a transaction carries its payee
/// as a plain string. The Payee record only buys a default category and
/// payment method next time, so failing to make one costs that and nothing
/// more.
class PayeePickerField extends StatelessWidget {
  const PayeePickerField({
    required this.controller,
    required this.payees,
    super.key,
    this.labelText,
    this.onCreate,
  });

  final TextEditingController controller;
  final List<Payee> payees;

  /// Null takes the localised default; a const parameter cannot hold one.
  final String? labelText;

  /// Saves a payee by this name, answering whether it worked. Null offers
  /// no create row.
  final Future<bool> Function(String name)? onCreate;

  Future<void> _open(BuildContext context) async {
    final title = labelText ?? L.of(context).payeeLabel;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SearchCreateSheet<Payee>(
        items: payees,
        label: (p) => p.name,
        title: title,
        selected: controller.text.isEmpty ? null : controller.text,
        onPick: (payee) {
          controller.text = payee?.name ?? '';
          Navigator.of(sheetContext).pop();
        },
        onCreate: onCreate == null
            ? null
            : (typed) async {
                // Adopted either way: the name is what the transaction
                // stores, and the record is a bonus on top of it.
                await onCreate!(typed);
                controller.text = typed;
                return true;
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return InkWell(
      onTap: () => unawaited(_open(context)),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText ?? l.payeeLabel,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Text(
            controller.text.isEmpty ? l.commonNone : controller.text,
            style: controller.text.isEmpty
                ? TextStyle(color: Theme.of(context).hintColor)
                : null,
          ),
        ),
      ),
    );
  }
}
