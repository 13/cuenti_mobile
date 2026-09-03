import 'dart:async';

import 'package:cuentimobile/core/enum_labels.dart';
import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/entity_edit_sheet.dart';
import 'package:cuentimobile/core/widgets/entity_list_filter.dart';
import 'package:cuentimobile/core/widgets/entity_list_header.dart';
import 'package:cuentimobile/core/widgets/enum_dropdown.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/categories_controller.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:cuentimobile/features/payees/domain/payee.dart';
import 'package:cuentimobile/features/payees/ui/payees_controller.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PayeesScreen extends ConsumerStatefulWidget {
  const PayeesScreen({super.key});

  @override
  ConsumerState<PayeesScreen> createState() => _PayeesScreenState();
}

class _PayeesScreenState extends ConsumerState<PayeesScreen> {
  static const _screen = 'payees';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The remembered search has to reach the field too, or the list would
    // come back filtered by text the reader cannot see.
    _searchController.text = ref.read(entityListFilterProvider(_screen)).query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(entityListFilterProvider(_screen).notifier).clearQuery();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final filter = ref.watch(entityListFilterProvider(_screen));
    final filters = ref.read(entityListFilterProvider(_screen).notifier);
    final sort = filter.sort;
    final payeesAsync = ref.watch(payeesControllerProvider);
    // Watched, not read: the edit sheet's category picker needs this list
    // loaded, and nothing else on this screen subscribes to it.
    final categories = ref.watch(categoriesControllerProvider).value ?? [];
    final options = [
      SortOption<Payee>(
        id: 'name',
        label: l.commonName,
        compare: (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      ),
      SortOption<Payee>(
        id: 'category',
        label: l.categoryLabel,
        compare: (a, b) =>
            (a.defaultCategoryName ?? '').toLowerCase().compareTo(
              (b.defaultCategoryName ?? '').toLowerCase(),
            ),
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          EntityListHeader<Payee>(
            searchController: _searchController,
            searchHint: l.payeesSearchHint,
            onSearchChanged: filters.setQuery,
            options: options,
            selected: sort,
            onSortChanged: filters.setSort,
          ),
          Expanded(
            child: AsyncValueWidget<List<Payee>>(
              value: payeesAsync,
              skeleton: SkeletonLoader.tiles(items: 6),
              data: (payees) {
                final shown = applySearchAndSort(
                  payees,
                  query: filter.query,
                  searchText: (p) =>
                      '${p.name} ${p.notes ?? ''} ${p.defaultCategoryName ?? ''}',
                  sort: sortOptionFor(options, sort),
                  descending: sort.descending,
                );

                return RefreshIndicator(
                  onRefresh: () {
                    ref.invalidate(payeesControllerProvider);
                    return ref.read(payeesControllerProvider.future);
                  },
                  child: shown.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            if (payees.isEmpty)
                              EmptyState(
                                icon: Icons.storefront,
                                message: l.payeesEmpty,
                                actionLabel: l.payeesAdd,
                                onAction: () => _showEditDialog(
                                  context,
                                  null,
                                  categories,
                                ),
                              )
                            else
                              EmptyState(
                                icon: Icons.storefront,
                                message: l.payeesNoMatch,
                                actionLabel: l.commonClearFilters,
                                onAction: _clearFilters,
                              ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: shown.length,
                          itemBuilder: (context, i) {
                            final p = shown[i];
                            return Dismissible(
                              key: ValueKey(p.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
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
                                title: l.payeesDeleteTitle,
                                message: l.commonDeleteConfirm(p.name),
                              ),
                              onDismissed: (_) => reportingFailure(
                                context,
                                () => ref
                                    .read(payeesControllerProvider.notifier)
                                    .delete(p.id!),
                              ),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _showEditDialog(
                                    context,
                                    p,
                                    categories,
                                  ),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null, categories),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    Payee? payee,
    List<Category> categories,
  ) {
    final name = TextEditingController(text: payee?.name ?? '');
    final notes = TextEditingController(text: payee?.notes ?? '');
    var categoryId = payee?.defaultCategoryId;
    var paymentMethod = payee?.defaultPaymentMethod ?? 'NONE';

    unawaited(
      showEntityEditSheet(
        context: context,
        title: payee == null
            ? L.of(context).payeesAddTitle
            : L.of(context).payeesEditTitle,
        successMessage: L.of(context).payeesSaved,
        fields: (context, rebuild) => [
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
          CategoryPickerField(
            categories: categories,
            selectedId: categoryId,
            labelText: L.of(context).payeesDefaultCategory,
            placeholder: L.of(context).commonNone,
            onChanged: (v) {
              categoryId = v;
              rebuild();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: paymentMethod,
            decoration: InputDecoration(
              labelText: L.of(context).payeesDefaultPayment,
              border: const OutlineInputBorder(),
            ),
            items: dropdownItemsFor(
              kPaymentMethods,
              paymentMethod,
              label: (v) => paymentMethodLabel(L.of(context), v),
            ),
            onChanged: (v) {
              paymentMethod = v ?? 'NONE';
              rebuild();
            },
          ),
        ],
        onSave: () => ref
            .read(payeesControllerProvider.notifier)
            .save(
              Payee(
                id: payee?.id,
                name: name.text,
                notes: notes.text.isNotEmpty ? notes.text : null,
                defaultCategoryId: categoryId,
                defaultPaymentMethod: paymentMethod,
              ),
            ),
      ),
    );
  }
}
