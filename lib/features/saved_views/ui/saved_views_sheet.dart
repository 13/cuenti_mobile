import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/core/widgets/entity_edit_sheet.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/saved_views/domain/saved_view.dart';
import 'package:cuentimobile/features/saved_views/ui/saved_views_controller.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter_codec.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows a bottom sheet listing saved transaction filters. Views whose
/// `params` were written by this app decode cleanly and can be applied or
/// deleted; views written by the web app (a different params format)
/// show up disabled with a 'Saved by web app' subtitle but can still be
/// deleted.
Future<void> showSavedViewsSheet(
  BuildContext context,
  WidgetRef ref, {
  required TransactionFilter current,
  required ValueChanged<TransactionFilter> onApply,
}) {
  ref.invalidate(savedViewsControllerProvider);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SavedViewsSheet(current: current, onApply: onApply),
  );
}

class _SavedViewsSheet extends ConsumerStatefulWidget {
  const _SavedViewsSheet({required this.current, required this.onApply});

  final TransactionFilter current;
  final ValueChanged<TransactionFilter> onApply;

  @override
  ConsumerState<_SavedViewsSheet> createState() => _SavedViewsSheetState();
}

class _SavedViewsSheetState extends ConsumerState<_SavedViewsSheet> {
  @override
  Widget build(BuildContext context) {
    final viewsAsync = ref.watch(savedViewsControllerProvider);
    final canSaveCurrent =
        widget.current != TransactionsController.defaultFilter;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              L.of(context).savedViewsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: AsyncValueWidget<List<SavedView>>(
                value: viewsAsync,
                skeleton: SkeletonLoader.tiles(height: 56),
                data: (views) {
                  if (views.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(L.of(context).savedViewsEmpty),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: views.length,
                    itemBuilder: (context, i) => _viewTile(context, views[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: canSaveCurrent ? () => _promptSave(context) : null,
              child: Text(L.of(context).savedViewsSaveCurrent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewTile(BuildContext context, SavedView view) {
    final decoded = TransactionFilterCodec.decode(view.params);
    final enabled = decoded != null;
    return ListTile(
      enabled: enabled,
      title: Text(view.name),
      subtitle: enabled ? null : Text(L.of(context).savedViewsFromWeb),
      onTap: enabled
          ? () {
              widget.onApply(decoded);
              Navigator.of(context).pop();
            }
          : null,
      trailing: IconButton(
        tooltip: L.of(context).savedViewsDeleteOne,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _delete(view),
      ),
    );
  }

  Future<void> _delete(SavedView view) async {
    final confirmed = await showConfirmSheet(
      context,
      title: L.of(context).savedViewsDeleteTitle,
      message: L.of(context).commonDeleteConfirm(view.name),
    );
    if (!confirmed || view.id == null || !mounted) return;
    await reportingFailure(
      context,
      () => ref.read(savedViewsControllerProvider.notifier).delete(view.id!),
    );
  }

  Future<void> _promptSave(BuildContext context) async {
    final nameController = TextEditingController();

    await showEntityEditSheet(
      context: context,
      title: L.of(context).savedViewsSaveCurrent,
      successMessage: L.of(context).savedViewsSaved,
      // A view with no name is not one anybody could pick out of the list
      // again, so Save waits until there is one.
      canSave: () => nameController.text.trim().isNotEmpty,
      fields: (context, rebuild) => [
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: L.of(context).commonName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onChanged: (_) => rebuild(),
        ),
      ],
      onSave: () => ref
          .read(savedViewsControllerProvider.notifier)
          .saveCurrent(nameController.text.trim(), widget.current),
    );
  }
}
