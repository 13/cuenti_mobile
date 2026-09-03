import 'dart:async';

import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/entity_edit_sheet.dart';
import 'package:cuentimobile/core/widgets/entity_list_filter.dart';
import 'package:cuentimobile/core/widgets/entity_list_header.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/tags/domain/tag.dart';
import 'package:cuentimobile/features/tags/ui/tags_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  static const _screen = 'tags';
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
    final tagsAsync = ref.watch(tagsControllerProvider);
    final options = [
      SortOption<Tag>(
        id: 'name',
        label: l.commonName,
        compare: (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          EntityListHeader<Tag>(
            searchController: _searchController,
            searchHint: l.tagsSearchHint,
            onSearchChanged: filters.setQuery,
            options: options,
            selected: sort,
            onSortChanged: filters.setSort,
          ),
          Expanded(
            child: AsyncValueWidget<List<Tag>>(
              value: tagsAsync,
              skeleton: SkeletonLoader.tiles(items: 6, height: 64),
              data: (tags) {
                final shown = applySearchAndSort(
                  tags,
                  query: filter.query,
                  searchText: (t) => t.name,
                  sort: sortOptionFor(options, sort),
                  descending: sort.descending,
                );

                return RefreshIndicator(
                  onRefresh: () {
                    ref.invalidate(tagsControllerProvider);
                    return ref.read(tagsControllerProvider.future);
                  },
                  child: shown.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            if (tags.isEmpty)
                              EmptyState(
                                icon: Icons.sell,
                                message: l.tagsEmpty,
                                actionLabel: l.tagsAdd,
                                onAction: () => _showEditDialog(context, null),
                              )
                            else
                              EmptyState(
                                icon: Icons.sell,
                                message: l.tagsNoMatch,
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
                            final tag = shown[i];
                            return Dismissible(
                              key: ValueKey(tag.id),
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
                                title: l.tagsDeleteTitle,
                                message: l.commonDeleteConfirm(tag.name),
                              ),
                              onDismissed: (_) => reportingFailure(
                                context,
                                () => ref
                                    .read(tagsControllerProvider.notifier)
                                    .delete(tag.id!),
                              ),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _showEditDialog(context, tag),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.sell,
                                            size: 20,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            tag.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
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
              onRetry: () => ref.invalidate(tagsControllerProvider),
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

  void _showEditDialog(BuildContext context, Tag? tag) {
    final name = TextEditingController(text: tag?.name ?? '');

    unawaited(
      showEntityEditSheet(
        context: context,
        title: tag == null
            ? L.of(context).tagsAddTitle
            : L.of(context).tagsEditTitle,
        successMessage: L.of(context).tagsSaved,
        fields: (context, _) => [
          TextField(
            controller: name,
            decoration: InputDecoration(
              labelText: L.of(context).commonName,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
        onSave: () => ref
            .read(tagsControllerProvider.notifier)
            .save(Tag(id: tag?.id, name: name.text)),
      ),
    );
  }
}
