import 'dart:async';

import 'package:cuentimobile/core/enum_labels.dart';
import 'package:cuentimobile/core/widgets/amount_text.dart';
import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/entity_edit_sheet.dart';
import 'package:cuentimobile/core/widgets/entity_list_filter.dart';
import 'package:cuentimobile/core/widgets/entity_list_header.dart';
import 'package:cuentimobile/core/widgets/enum_dropdown.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/assets/domain/asset.dart';
import 'package:cuentimobile/features/assets/ui/assets_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();

  static Future<void> _delete(BuildContext context, WidgetRef ref, int id) =>
      reportingFailure(
        context,
        () => ref.read(assetsControllerProvider.notifier).delete(id),
      );

  static void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Asset? asset,
  ) {
    final symbol = TextEditingController(text: asset?.symbol ?? '');
    final name = TextEditingController(text: asset?.name ?? '');
    final currency = TextEditingController(text: asset?.currency ?? 'EUR');
    var type = asset?.type ?? 'STOCK';

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
        title: asset == null
            ? L.of(context).assetsAddTitle
            : L.of(context).assetsEditTitle,
        successMessage: L.of(context).assetsSaved,
        fields: (context, rebuild) => [
          field(symbol, L.of(context).assetsSymbolHint),
          const SizedBox(height: 12),
          field(name, L.of(context).commonName),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: InputDecoration(
              labelText: L.of(context).commonType,
              border: const OutlineInputBorder(),
            ),
            items: dropdownItemsFor(
              kAssetTypes,
              type,
              label: (v) => assetTypeLabel(L.of(context), v),
            ),
            onChanged: (v) {
              type = v ?? 'STOCK';
              rebuild();
            },
          ),
          const SizedBox(height: 12),
          field(currency, L.of(context).commonCurrency),
        ],
        onSave: () => ref
            .read(assetsControllerProvider.notifier)
            .save(
              Asset(
                id: asset?.id,
                symbol: symbol.text,
                name: name.text,
                type: type,
                currency: currency.text,
              ),
            ),
      ),
    );
  }
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  static const _screen = 'assets';
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
    final assetsAsync = ref.watch(assetsControllerProvider);
    final options = [
      SortOption<Asset>(
        id: 'name',
        label: l.commonName,
        compare: (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      ),
      SortOption<Asset>(
        id: 'symbol',
        label: l.commonSymbol,
        compare: (a, b) =>
            a.symbol.toLowerCase().compareTo(b.symbol.toLowerCase()),
      ),
      SortOption<Asset>(
        id: 'type',
        label: l.commonType,
        compare: (a, b) =>
            assetTypeLabel(l, a.type).compareTo(assetTypeLabel(l, b.type)),
      ),
      SortOption<Asset>(
        id: 'price',
        // An asset whose price has never been fetched ranks above every
        // real one, which puts it at the end of the cheapest-first order
        // rather than pretending it is worth nothing.
        label: l.commonPrice,
        compare: (a, b) => (a.currentPrice ?? double.infinity).compareTo(
          b.currentPrice ?? double.infinity,
        ),
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          EntityListHeader<Asset>(
            searchController: _searchController,
            searchHint: l.assetsSearchHint,
            onSearchChanged: filters.setQuery,
            options: options,
            selected: sort,
            onSortChanged: filters.setSort,
          ),
          Expanded(
            child: AsyncValueWidget<List<Asset>>(
              value: assetsAsync,
              skeleton: SkeletonLoader.tiles(items: 4, height: 88),
              data: (assets) {
                final shown = applySearchAndSort(
                  assets,
                  query: filter.query,
                  searchText: (a) =>
                      '${a.name} ${a.symbol} ${a.type} ${a.currency ?? ''}',
                  sort: sortOptionFor(options, sort),
                  descending: sort.descending,
                );

                return RefreshIndicator(
                  onRefresh: () {
                    ref.invalidate(assetsControllerProvider);
                    return ref.read(assetsControllerProvider.future);
                  },
                  child: shown.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            if (assets.isEmpty)
                              EmptyState(
                                icon: Icons.show_chart,
                                message: l.assetsEmpty,
                                actionLabel: l.assetsAdd,
                                onAction: () => AssetsScreen._showEditDialog(
                                  context,
                                  ref,
                                  null,
                                ),
                              )
                            else
                              EmptyState(
                                icon: Icons.show_chart,
                                message: l.assetsNoMatch,
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
                            final a = shown[i];
                            return Dismissible(
                              key: ValueKey(a.id),
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
                                title: l.assetsDeleteTitle,
                                message: l.commonDeleteConfirm(a.name),
                              ),
                              onDismissed: (_) =>
                                  AssetsScreen._delete(context, ref, a.id!),
                              child: _AssetTile(asset: a),
                            );
                          },
                        ),
                );
              },
              onRetry: () => ref.invalidate(assetsControllerProvider),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AssetsScreen._showEditDialog(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AssetTile extends ConsumerStatefulWidget {
  const _AssetTile({required this.asset});

  final Asset asset;

  @override
  ConsumerState<_AssetTile> createState() => _AssetTileState();
}

class _AssetTileState extends ConsumerState<_AssetTile> {
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.asset;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => AssetsScreen._showEditDialog(context, ref, a),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _typeColor(context, a.type).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _typeIcon(a.type),
                  color: _typeColor(context, a.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${a.symbol} • ${assetTypeLabel(L.of(context), a.type)}'
                      ' • ${a.currency ?? ''}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // AmountText, like every other amount in the app: it
                  // honours the currency's own punctuation and fraction
                  // digits, and it is what privacy mode blurs.
                  if (a.currentPrice != null)
                    AmountText(
                      a.currentPrice!,
                      currency: a.currency,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    Text(
                      L.of(context).assetsNoPrice,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (a.lastUpdate != null)
                    Text(
                      formatDayTime(context, a.lastUpdate!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: _refreshing
                        ? const Padding(
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            padding: EdgeInsets.zero,
                            tooltip: L.of(context).assetsRefreshPrice,
                            onPressed: () => _refreshPrice(context, a),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'ETF':
        return Icons.pie_chart;
      case 'CRYPTO':
        return Icons.currency_bitcoin;
      default:
        return Icons.show_chart;
    }
  }

  Color _typeColor(BuildContext context, String type) {
    final scheme = Theme.of(context).colorScheme;
    switch (type) {
      case 'ETF':
        return scheme.tertiary;
      case 'CRYPTO':
        return scheme.secondary;
      default:
        return scheme.primary;
    }
  }

  Future<void> _refreshPrice(BuildContext context, Asset a) async {
    setState(() => _refreshing = true);
    final messenger = ScaffoldMessenger.of(context);
    final refreshed = L.of(context).assetsPriceRefreshed(a.symbol);
    final ok = await reportingFailure(
      context,
      () => ref.read(assetsControllerProvider.notifier).refreshPrice(a.id!),
    );
    if (ok) messenger.showSnackBar(SnackBar(content: Text(refreshed)));
    if (mounted) setState(() => _refreshing = false);
  }
}
