import 'dart:async';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/categories_controller.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesControllerProvider);

    return Scaffold(
      body: AsyncValueWidget<List<Category>>(
        value: categoriesAsync,
        skeleton: SkeletonLoader.tiles(items: 5, height: 64),
        data: (categories) {
          // Group: parent categories (no parent) and their children
          final parents = categories.where((c) => c.parentId == null).toList();

          return RefreshIndicator(
            onRefresh: () {
              ref.invalidate(categoriesControllerProvider);
              return ref.read(categoriesControllerProvider.future);
            },
            child: categories.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.category,
                        message: L.of(context).categoriesEmpty,
                        actionLabel: L.of(context).categoriesAdd,
                        onAction: () => _showEditDialog(context, ref, null),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: parents.length,
                    itemBuilder: (context, i) {
                      final parent = parents[i];
                      final children = categories
                          .where((c) => c.parentId == parent.id)
                          .toList();
                      final color = parent.type == 'INCOME'
                          ? context.cuentiColors.income
                          : context.cuentiColors.expense;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              parent.type == 'INCOME'
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: color,
                              size: 20,
                            ),
                          ),
                          title: Text(parent.name),
                          subtitle: Text(parent.type),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: L.of(context).categoriesEditOne,
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () =>
                                    _showEditDialog(context, ref, parent),
                              ),
                              IconButton(
                                tooltip: L.of(context).categoriesDeleteOne,
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () =>
                                    _confirmDelete(context, ref, parent),
                              ),
                            ],
                          ),
                          children: children
                              .map(
                                (child) => ListTile(
                                  contentPadding: const EdgeInsets.only(
                                    left: 56,
                                    right: 16,
                                  ),
                                  title: Text(child.name),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: L
                                            .of(context)
                                            .categoriesEditOne,
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _showEditDialog(
                                          context,
                                          ref,
                                          child,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: L
                                            .of(context)
                                            .categoriesDeleteOne,
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _confirmDelete(context, ref, child),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
          );
        },
        onRetry: () => ref.invalidate(categoriesControllerProvider),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showConfirmSheet(
      context,
      title: L.of(context).categoriesDeleteTitle,
      message: L
          .of(context)
          .commonDeleteConfirm(
            category.fullName ?? category.name,
          ),
    );
    if (!confirmed) return;
    try {
      await ref
          .read(categoriesControllerProvider.notifier)
          .delete(category.id!);
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

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Category? category,
  ) {
    final name = TextEditingController(text: category?.name ?? '');
    var type = category?.type ?? 'EXPENSE';
    var parentId = category?.parentId;
    var saving = false;

    final categories = ref.read(categoriesControllerProvider).value ?? [];
    final parentOptions = categories
        .where((c) => c.parentId == null && c.id != category?.id)
        .toList();

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
                    category == null
                        ? L.of(context).categoriesAddTitle
                        : L.of(context).categoriesEditTitle,
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
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: InputDecoration(
                      labelText: L.of(context).commonType,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'EXPENSE',
                        child: Text(L.of(context).commonExpense),
                      ),
                      DropdownMenuItem(
                        value: 'INCOME',
                        child: Text(L.of(context).commonIncome),
                      ),
                    ],
                    onChanged: (v) =>
                        setModalState(() => type = v ?? 'EXPENSE'),
                  ),
                  const SizedBox(height: 12),
                  CategoryPickerField(
                    categories: parentOptions,
                    selectedId: parentId,
                    labelText: L.of(context).categoriesParent,
                    placeholder: L.of(context).categoriesTopLevel,
                    noneLabel: L.of(context).categoriesTopLevel,
                    onChanged: (v) => setModalState(() => parentId = v),
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
                                    final newCategory = Category(
                                      id: category?.id,
                                      name: name.text,
                                      type: type,
                                      parentId: parentId,
                                    );
                                    await ref
                                        .read(
                                          categoriesControllerProvider.notifier,
                                        )
                                        .save(newCategory);
                                    if (ctx.mounted) {
                                      final messenger = ScaffoldMessenger.of(
                                        ctx,
                                      );
                                      final saved = L.of(ctx).categoriesSaved;
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
