import 'package:cuentimobile/core/enum_labels.dart';
import 'package:cuentimobile/core/widgets/amount_text.dart';
import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/entity_list_filter.dart';
import 'package:cuentimobile/core/widgets/entity_list_header.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/scheduled/domain/overdue.dart';
import 'package:cuentimobile/features/scheduled/domain/scheduled_transaction.dart';
import 'package:cuentimobile/features/scheduled/ui/scheduled_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScheduledScreen extends ConsumerStatefulWidget {
  const ScheduledScreen({super.key});

  @override
  ConsumerState<ScheduledScreen> createState() => _ScheduledScreenState();
}

class _ScheduledScreenState extends ConsumerState<ScheduledScreen> {
  static const _screen = 'scheduled';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    final scheduledAsync = ref.watch(scheduledControllerProvider);
    final options = [
      SortOption<ScheduledTransaction>(
        id: 'next',
        label: l.commonNext,
        compare: (a, b) => a.nextOccurrence.compareTo(b.nextOccurrence),
      ),
      SortOption<ScheduledTransaction>(
        id: 'amount',
        label: l.commonAmount,
        compare: (a, b) => a.amount.compareTo(b.amount),
      ),
      SortOption<ScheduledTransaction>(
        id: 'payee',
        label: l.commonName,
        compare: (a, b) => (a.payee ?? '').toLowerCase().compareTo(
          (b.payee ?? '').toLowerCase(),
        ),
      ),
    ];

    return Column(
      children: [
        EntityListHeader<ScheduledTransaction>(
          searchController: _searchController,
          searchHint: l.scheduledSearchHint,
          onSearchChanged: filters.setQuery,
          options: options,
          selected: sort,
          onSortChanged: filters.setSort,
        ),
        Expanded(
          child: AsyncValueWidget<List<ScheduledTransaction>>(
            value: scheduledAsync,
            skeleton: SkeletonLoader.tiles(items: 4, height: 108),
            data: (all) {
              final items = applySearchAndSort(
                all,
                query: filter.query,
                searchText: (st) =>
                    '${st.payee ?? ''} ${st.fromAccountName ?? ''} '
                    '${st.toAccountName ?? ''} ${st.categoryName ?? ''} '
                    '${categoryTypeLabel(l, st.type)} '
                    '${recurrenceLabel(l, st.recurrencePattern)}',
                sort: sortOptionFor(options, sort),
                descending: sort.descending,
              );

              return RefreshIndicator(
                onRefresh: () {
                  ref.invalidate(scheduledControllerProvider);
                  return ref.read(scheduledControllerProvider.future);
                },
                child: items.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          if (all.isEmpty)
                            EmptyState(
                              icon: Icons.schedule,
                              message: l.scheduledEmpty,
                            )
                          else
                            EmptyState(
                              icon: Icons.schedule,
                              message: l.scheduledNoMatch,
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
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final st = items[i];
                          final isLate = isOverdue(st, DateTime.now());
                          final color = isLate
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onLongPress: () =>
                                  _showDeleteDialog(context, ref, st),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.12,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.schedule,
                                            color: color,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                // Without a payee the row would
                                                // otherwise be titled 'EXPENSE'.
                                                st.payee ??
                                                    categoryTypeLabel(
                                                      L.of(context),
                                                      st.type,
                                                    ),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleSmall,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                L
                                                        .of(context)
                                                        .scheduledNextOn(
                                                          recurrenceLabel(
                                                            L.of(context),
                                                            st.recurrencePattern,
                                                          ),
                                                          formatDay(
                                                            context,
                                                            st.nextOccurrence,
                                                          ),
                                                        ) +
                                                    (isLate
                                                        ? ' ${L.of(context).scheduledLate}'
                                                        : ''),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelSmall,
                                              ),
                                              if ((st.fromAccountName ?? '')
                                                  .isNotEmpty)
                                                Text(
                                                  '${st.fromAccountName ?? ''} ${st.type == 'TRANSFER' ? '→ ${st.toAccountName}' : ''}',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.labelSmall,
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            AmountText(
                                              st.amount,
                                              type: st.type,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Switch(
                                              value: st.enabled,
                                              onChanged: (v) => _toggleEnabled(
                                                context,
                                                ref,
                                                st,
                                                v,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () =>
                                              _post(context, ref, st.id!),
                                          icon: const Icon(
                                            Icons.check,
                                            size: 18,
                                          ),
                                          label: Text(
                                            L.of(context).scheduledPost,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _skip(context, ref, st.id!),
                                          icon: const Icon(
                                            Icons.skip_next,
                                            size: 18,
                                          ),
                                          label: Text(
                                            L.of(context).scheduledSkip,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              );
            },
            onRetry: () => ref.invalidate(scheduledControllerProvider),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleEnabled(
    BuildContext context,
    WidgetRef ref,
    ScheduledTransaction st,
    bool value,
  ) async {
    await reportingFailure(
      context,
      () => ref
          .read(scheduledControllerProvider.notifier)
          .save(st.copyWith(enabled: value)),
    );
  }

  Future<void> _post(BuildContext context, WidgetRef ref, int id) async {
    final messenger = ScaffoldMessenger.of(context);
    final posted = L.of(context).scheduledPosted;
    final ok = await reportingFailure(
      context,
      () => ref.read(scheduledControllerProvider.notifier).post(id),
    );
    if (ok) messenger.showSnackBar(SnackBar(content: Text(posted)));
  }

  Future<void> _skip(BuildContext context, WidgetRef ref, int id) async {
    final messenger = ScaffoldMessenger.of(context);
    final skipped = L.of(context).scheduledSkipped;
    final ok = await reportingFailure(
      context,
      () => ref.read(scheduledControllerProvider.notifier).skip(id),
    );
    if (ok) messenger.showSnackBar(SnackBar(content: Text(skipped)));
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ScheduledTransaction st,
  ) async {
    final confirmed = await showConfirmSheet(
      context,
      title: L.of(context).scheduledDeleteTitle,
      message: L.of(context).scheduledDeleteBody(st.payee ?? st.type),
    );
    if (!confirmed || !context.mounted) return;
    await reportingFailure(
      context,
      () => ref.read(scheduledControllerProvider.notifier).delete(st.id!),
    );
  }
}
