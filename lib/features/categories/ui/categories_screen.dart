import 'dart:async';

import 'package:cuentimobile/core/enum_labels.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/entity_edit_sheet.dart';
import 'package:cuentimobile/core/widgets/entity_list_filter.dart';
import 'package:cuentimobile/core/widgets/entity_list_header.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/categories_controller.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/token_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A top-level category together with the children to show beneath it.
typedef _Branch = ({Category parent, List<Category> children});

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  static const _screen = 'categories';
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

  /// Groups [all] into the branches to draw.
  ///
  /// A tree cannot be filtered a row at a time: a child that matches has to
  /// bring its parent along or it has nowhere to hang, and a parent that
  /// matches is more useful with its whole branch than with none of it. So a
  /// branch survives when either end of it matches, and it carries every
  /// child when the parent itself was the hit.
  ///
  /// The screen draws two levels, which is all the editor lets anyone build.
  /// Anything the data holds that does not fit -- a grandchild, or a child
  /// whose parent is not in the response -- is drawn at the top instead of
  /// being skipped. A row that is not drawn cannot be edited or deleted
  /// either, so quietly dropping it would strand it in the account.
  List<_Branch> _branches(
    List<Category> all,
    EntityFilter filter,
    SortOption<Category>? sort,
  ) {
    final rootIds = {
      for (final c in all)
        if (c.parentId == null) c.id,
    };
    final tops = all.where(
      (c) => c.parentId == null || !rootIds.contains(c.parentId),
    );

    final branches = <_Branch>[];
    for (final parent in tops) {
      final children = all.where((c) => c.parentId == parent.id).toList();
      final parentMatches = matchesAllTokens(
        categoryLabel(parent),
        filter.query,
      );
      final matchingChildren = [
        for (final child in children)
          if (matchesAllTokens(categoryLabel(child), filter.query)) child,
      ];
      if (!parentMatches && matchingChildren.isEmpty) continue;
      branches.add((
        parent: parent,
        children: applySearchAndSort(
          parentMatches ? children : matchingChildren,
          query: '',
          searchText: categoryLabel,
          sort: sort,
          descending: filter.sort.descending,
        ),
      ));
    }

    final orderedParents = applySearchAndSort(
      [for (final b in branches) b.parent],
      query: '',
      searchText: categoryLabel,
      sort: sort,
      descending: filter.sort.descending,
    );
    return [
      for (final parent in orderedParents)
        branches.firstWhere((b) => b.parent.id == parent.id),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final filter = ref.watch(entityListFilterProvider(_screen));
    final filters = ref.read(entityListFilterProvider(_screen).notifier);
    final sort = filter.sort;
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final options = [
      SortOption<Category>(
        id: 'name',
        label: l.commonName,
        compare: (a, b) => categoryLabel(a).toLowerCase().compareTo(
          categoryLabel(b).toLowerCase(),
        ),
      ),
      SortOption<Category>(
        id: 'type',
        label: l.commonType,
        compare: (a, b) => categoryTypeLabel(
          l,
          a.type,
        ).compareTo(categoryTypeLabel(l, b.type)),
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          EntityListHeader<Category>(
            searchController: _searchController,
            searchHint: l.categoriesSearchHint,
            onSearchChanged: filters.setQuery,
            options: options,
            selected: sort,
            onSortChanged: filters.setSort,
          ),
          Expanded(
            child: AsyncValueWidget<List<Category>>(
              value: categoriesAsync,
              skeleton: SkeletonLoader.tiles(items: 5, height: 64),
              data: (categories) {
                final branches = _branches(
                  categories,
                  filter,
                  sortOptionFor(options, sort),
                );

                return RefreshIndicator(
                  onRefresh: () {
                    ref.invalidate(categoriesControllerProvider);
                    return ref.read(categoriesControllerProvider.future);
                  },
                  child: branches.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            if (categories.isEmpty)
                              EmptyState(
                                icon: Icons.category,
                                message: l.categoriesEmpty,
                                actionLabel: l.categoriesAdd,
                                onAction: () => _showEditDialog(context, null),
                              )
                            else
                              EmptyState(
                                icon: Icons.category,
                                message: l.categoriesNoMatch,
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
                          itemCount: branches.length,
                          itemBuilder: (context, i) {
                            final branch = branches[i];
                            final parent = branch.parent;
                            final color = parent.type == 'INCOME'
                                ? context.cuentiColors.income
                                : context.cuentiColors.expense;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              clipBehavior: Clip.antiAlias,
                              child: ExpansionTile(
                                // A search that matched a child has to show
                                // it; the key changes with that state so the
                                // tile takes the new initiallyExpanded.
                                key: ValueKey(
                                  '${parent.id}-${filter.query.isEmpty}',
                                ),
                                initiallyExpanded: filter.query.isNotEmpty,
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
                                subtitle: Text(
                                  categoryTypeLabel(l, parent.type),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: l.categoriesEditOne,
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () =>
                                          _showEditDialog(context, parent),
                                    ),
                                    IconButton(
                                      tooltip: l.categoriesDeleteOne,
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () =>
                                          _confirmDelete(context, parent),
                                    ),
                                  ],
                                ),
                                children: branch.children
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
                                              tooltip: l.categoriesEditOne,
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 20,
                                              ),
                                              onPressed: () => _showEditDialog(
                                                context,
                                                child,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: l.categoriesDeleteOne,
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 20,
                                              ),
                                              onPressed: () => _confirmDelete(
                                                context,
                                                child,
                                              ),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final confirmed = await showConfirmSheet(
      context,
      title: L.of(context).categoriesDeleteTitle,
      message: L
          .of(context)
          .commonDeleteConfirm(
            category.fullName ?? category.name,
          ),
    );
    if (!confirmed || !context.mounted) return;
    await reportingFailure(
      context,
      () =>
          ref.read(categoriesControllerProvider.notifier).delete(category.id!),
    );
  }

  void _showEditDialog(BuildContext context, Category? category) {
    final name = TextEditingController(text: category?.name ?? '');
    var type = category?.type ?? 'EXPENSE';
    var parentId = category?.parentId;

    final categories = ref.read(categoriesControllerProvider).value ?? [];
    final parentOptions = categories
        .where((c) => c.parentId == null && c.id != category?.id)
        .toList();

    unawaited(
      showEntityEditSheet(
        context: context,
        title: category == null
            ? L.of(context).categoriesAddTitle
            : L.of(context).categoriesEditTitle,
        successMessage: L.of(context).categoriesSaved,
        fields: (context, rebuild) => [
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
            onChanged: (v) {
              type = v ?? 'EXPENSE';
              rebuild();
            },
          ),
          const SizedBox(height: 12),
          CategoryPickerField(
            categories: parentOptions,
            selectedId: parentId,
            labelText: L.of(context).categoriesParent,
            placeholder: L.of(context).categoriesTopLevel,
            noneLabel: L.of(context).categoriesTopLevel,
            onChanged: (v) {
              parentId = v;
              rebuild();
            },
          ),
        ],
        onSave: () => ref
            .read(categoriesControllerProvider.notifier)
            .save(
              Category(
                id: category?.id,
                name: name.text,
                type: type,
                parentId: parentId,
              ),
            ),
      ),
    );
  }
}
