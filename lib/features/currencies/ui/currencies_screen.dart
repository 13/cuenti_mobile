import 'dart:async';

import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/entity_edit_sheet.dart';
import 'package:cuentimobile/core/widgets/entity_list_filter.dart';
import 'package:cuentimobile/core/widgets/entity_list_header.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:cuentimobile/features/currencies/ui/currencies_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrenciesScreen extends ConsumerStatefulWidget {
  const CurrenciesScreen({super.key});

  @override
  ConsumerState<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends ConsumerState<CurrenciesScreen> {
  static const _screen = 'currencies';
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
    final currenciesAsync = ref.watch(currenciesControllerProvider);
    final options = [
      SortOption<Currency>(
        id: 'code',
        label: l.commonCode,
        compare: (a, b) => a.code.toLowerCase().compareTo(b.code.toLowerCase()),
      ),
      SortOption<Currency>(
        id: 'name',
        label: l.commonName,
        compare: (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          EntityListHeader<Currency>(
            searchController: _searchController,
            searchHint: l.currenciesSearchHint,
            onSearchChanged: filters.setQuery,
            options: options,
            selected: sort,
            onSortChanged: filters.setSort,
          ),
          Expanded(
            child: AsyncValueWidget<List<Currency>>(
              value: currenciesAsync,
              skeleton: SkeletonLoader.tiles(items: 6, height: 76),
              data: (currencies) {
                final shown = applySearchAndSort(
                  currencies,
                  query: filter.query,
                  searchText: (c) => '${c.code} ${c.name} ${c.symbol}',
                  sort: sortOptionFor(options, sort),
                  descending: sort.descending,
                );

                return RefreshIndicator(
                  onRefresh: () {
                    ref.invalidate(currenciesControllerProvider);
                    return ref.read(currenciesControllerProvider.future);
                  },
                  child: shown.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            if (currencies.isEmpty)
                              EmptyState(
                                icon: Icons.currency_exchange,
                                message: l.currenciesEmpty,
                                actionLabel: l.currenciesAdd,
                                onAction: () => _showEditDialog(context, null),
                              )
                            else
                              EmptyState(
                                icon: Icons.currency_exchange,
                                message: l.currenciesNoMatch,
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
                            final c = shown[i];
                            return Dismissible(
                              key: ValueKey(c.id),
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
                                title: l.currenciesDeleteTitle,
                                message: l.commonDeleteConfirm(
                                  '${c.code} - ${c.name}',
                                ),
                              ),
                              onDismissed: (_) => _delete(context, c.id!),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _showEditDialog(context, c),
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
                                              c.symbol,
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
                                                '${c.code} - ${c.name}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleSmall,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                l.currenciesFormatSummary(
                                                  c.symbol,
                                                  '${c.fracDigits}',
                                                  c.decimalChar,
                                                  c.groupingChar,
                                                ),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelSmall,
                                              ),
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
              onRetry: () => ref.invalidate(currenciesControllerProvider),
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

  Future<void> _delete(BuildContext context, int id) => reportingFailure(
    context,
    () => ref.read(currenciesControllerProvider.notifier).delete(id),
  );

  void _showEditDialog(BuildContext context, Currency? currency) {
    final code = TextEditingController(text: currency?.code ?? '');
    final name = TextEditingController(text: currency?.name ?? '');
    final symbol = TextEditingController(text: currency?.symbol ?? '');
    final decimalChar = TextEditingController(
      text: currency?.decimalChar ?? ',',
    );
    final groupingChar = TextEditingController(
      text: currency?.groupingChar ?? '.',
    );
    var fracDigits = currency?.fracDigits ?? 2;

    Widget field(TextEditingController controller, String label) => TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );

    unawaited(
      showEntityEditSheet(
        context: context,
        title: currency == null
            ? L.of(context).currenciesAddTitle
            : L.of(context).currenciesEditTitle,
        successMessage: L.of(context).currenciesSaved,
        fields: (context, rebuild) => [
          field(code, L.of(context).currenciesCodeHint),
          const SizedBox(height: 12),
          field(name, L.of(context).currenciesNameHint),
          const SizedBox(height: 12),
          field(symbol, L.of(context).currenciesSymbolHint),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: field(decimalChar, L.of(context).currenciesDecimal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: field(groupingChar, L.of(context).currenciesGrouping),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: fracDigits,
                  decoration: InputDecoration(
                    labelText: L.of(context).currenciesDecimals,
                    border: const OutlineInputBorder(),
                  ),
                  items: List.generate(
                    9,
                    (i) => DropdownMenuItem(value: i, child: Text('$i')),
                  ),
                  onChanged: (v) {
                    fracDigits = v ?? 2;
                    rebuild();
                  },
                ),
              ),
            ],
          ),
        ],
        onSave: () => ref
            .read(currenciesControllerProvider.notifier)
            .save(
              Currency(
                id: currency?.id,
                code: code.text,
                name: name.text,
                symbol: symbol.text,
                decimalChar: decimalChar.text,
                groupingChar: groupingChar.text,
                fracDigits: fracDigits,
              ),
            ),
      ),
    );
  }
}
