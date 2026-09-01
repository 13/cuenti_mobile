import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:cuentimobile/features/transactions/ui/split_draft.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:flutter/material.dart';

/// Editor for splitting one transaction across several categories.
///
/// Stateless by design: the drafts live in the dialog because the save path
/// reads them, so every mutation here is reported through [onChanged] for
/// the dialog to apply and rebuild.
class SplitsEditor extends StatelessWidget {
  const SplitsEditor({
    required this.splits,
    required this.categories,
    required this.validationMessage,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
    super.key,
  });

  final List<SplitDraft> splits;

  /// Already narrowed to the transaction's type by the caller.
  final List<Category> categories;

  /// Rendered under the rows and, by the caller, used to gate Save -- one
  /// value so the banner and the button cannot disagree.
  final String? validationMessage;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  /// Any edit to a row; the dialog uses it to mark the section touched.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Splits',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add split',
              onPressed: onAdd,
            ),
          ],
        ),
        for (var i = 0; i < splits.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: CategoryPickerField(
                    categories: categories,
                    selectedId: splits[i].categoryId,
                    allowNone: false,
                    isDense: true,
                    onChanged: (v) {
                      splits[i].categoryId = v;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: splits[i].amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (parseAmountInput(v) == null) return 'Invalid number';
                      return null;
                    },
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: splits[i].memo,
                    decoration: const InputDecoration(
                      labelText: 'Memo',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Remove split',
                  onPressed: () => onRemove(i),
                ),
              ],
            ),
          ),
        if (validationMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              validationMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
