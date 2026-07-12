import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/domain/transaction_filter_codec.dart';
import '../../transactions/ui/transactions_controller.dart';
import '../domain/saved_view.dart';
import 'saved_views_controller.dart';

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
    final canSaveCurrent = widget.current != TransactionsController.defaultFilter;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Saved views', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: AsyncValueWidget<List<SavedView>>(
                value: viewsAsync,
                skeleton: SkeletonLoader.tiles(items: 3, height: 56),
                data: (views) {
                  if (views.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No saved views yet'),
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
              child: const Text('Save current view'),
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
      subtitle: enabled ? null : const Text('Saved by web app'),
      onTap: enabled
          ? () {
              widget.onApply(decoded);
              Navigator.of(context).pop();
            }
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _delete(view),
      ),
    );
  }

  Future<void> _delete(SavedView view) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Delete saved view?',
      message: 'Delete "${view.name}"?',
    );
    if (!confirmed || view.id == null) return;
    try {
      await ref.read(savedViewsControllerProvider.notifier).delete(view.id!);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _promptSave(BuildContext context) async {
    final nameController = TextEditingController();
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Save current view', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onChanged: (_) => setModalState(() {}),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving ? null : () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: saving || nameController.text.trim().isEmpty
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              try {
                                await ref
                                    .read(savedViewsControllerProvider.notifier)
                                    .saveCurrent(
                                      nameController.text.trim(),
                                      widget.current,
                                    );
                                if (ctx.mounted) Navigator.pop(ctx);
                              } on ApiException catch (e) {
                                setModalState(() => saving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.message}'),
                                      backgroundColor:
                                          Theme.of(ctx).colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
