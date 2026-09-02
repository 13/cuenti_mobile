import 'dart:async';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/payees/domain/payee.dart';
import 'package:cuentimobile/features/payees/ui/payees_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Constants for payment methods
const kPaymentMethods = ['CASH', 'CARD', 'BANK_TRANSFER', 'CHECK', 'NONE'];

class PayeesScreen extends ConsumerWidget {
  const PayeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payeesAsync = ref.watch(payeesControllerProvider);

    return Scaffold(
      body: AsyncValueWidget<List<Payee>>(
        value: payeesAsync,
        skeleton: SkeletonLoader.tiles(items: 6),
        data: (payees) {
          return RefreshIndicator(
            onRefresh: () {
              ref.invalidate(payeesControllerProvider);
              return ref.read(payeesControllerProvider.future);
            },
            child: payees.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.storefront,
                        message: L.of(context).payeesEmpty,
                        actionLabel: L.of(context).payeesAdd,
                        onAction: () => _showEditDialog(context, ref, null),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: payees.length,
                    itemBuilder: (context, i) {
                      final p = payees[i];
                      return Dismissible(
                        key: ValueKey(p.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(
                            Icons.delete,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                        confirmDismiss: (_) => showConfirmSheet(
                          context,
                          title: L.of(context).payeesDeleteTitle,
                          message: L.of(context).commonDeleteConfirm(p.name),
                        ),
                        onDismissed: (_) async {
                          try {
                            await ref
                                .read(payeesControllerProvider.notifier)
                                .delete(p.id!);
                          } on ApiException catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.localizedMessage(L.of(context)),
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showEditDialog(context, ref, p),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        p.name.isNotEmpty
                                            ? p.name[0].toUpperCase()
                                            : '?',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                        if ((p.defaultCategoryName ??
                                                p.notes ??
                                                '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            p.defaultCategoryName ??
                                                p.notes ??
                                                '',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelSmall,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
        onRetry: () => ref.invalidate(payeesControllerProvider),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Payee? payee) {
    final name = TextEditingController(text: payee?.name ?? '');
    final notes = TextEditingController(text: payee?.notes ?? '');
    var categoryId = payee?.defaultCategoryId;
    var paymentMethod = payee?.defaultPaymentMethod ?? 'NONE';
    var saving = false;

    unawaited(
      showModalBottomSheet<void>(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    payee == null
                        ? L.of(context).payeesAddTitle
                        : L.of(context).payeesEditTitle,
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: L.of(context).commonName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    decoration: InputDecoration(
                      labelText: L.of(context).payeesNotes,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: categoryId,
                    decoration: InputDecoration(
                      labelText: L.of(context).payeesDefaultCategory,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(child: Text(L.of(context).commonNone)),
                    ],
                    onChanged: (v) => setModalState(() => categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration: InputDecoration(
                      labelText: L.of(context).payeesDefaultPayment,
                      border: const OutlineInputBorder(),
                    ),
                    items: kPaymentMethods
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => paymentMethod = v ?? 'NONE'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving ? null : () => Navigator.pop(ctx),
                          child: Text(L.of(context).commonCancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  setModalState(() => saving = true);
                                  try {
                                    final newPayee = Payee(
                                      id: payee?.id,
                                      name: name.text,
                                      notes: notes.text.isNotEmpty
                                          ? notes.text
                                          : null,
                                      defaultCategoryId: categoryId,
                                      defaultPaymentMethod: paymentMethod,
                                    );
                                    await ref
                                        .read(payeesControllerProvider.notifier)
                                        .save(newPayee);
                                    if (ctx.mounted) {
                                      final messenger = ScaffoldMessenger.of(
                                        ctx,
                                      );
                                      final saved = L.of(ctx).payeesSaved;
                                      Navigator.pop(ctx);
                                      showSuccessSnack(messenger, saved);
                                    }
                                  } on ApiException catch (e) {
                                    setModalState(() => saving = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            L
                                                .of(context)
                                                .commonError(
                                                  e.localizedMessage(
                                                    L.of(context),
                                                  ),
                                                ),
                                          ),
                                          backgroundColor: Theme.of(
                                            ctx,
                                          ).colorScheme.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(L.of(context).commonSave),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
