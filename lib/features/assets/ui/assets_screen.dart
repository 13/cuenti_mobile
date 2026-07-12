import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../domain/asset.dart';
import 'assets_controller.dart';

class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetsControllerProvider);

    return Scaffold(
      body: AsyncValueWidget<List<Asset>>(
        value: assetsAsync,
        skeleton: SkeletonLoader.tiles(items: 4, height: 88),
        data: (assets) => RefreshIndicator(
          onRefresh: () {
            ref.invalidate(assetsControllerProvider);
            return ref.read(assetsControllerProvider.future);
          },
          child: assets.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    EmptyState(
                      icon: Icons.show_chart,
                      message: 'No assets yet',
                      actionLabel: 'Add asset',
                      onAction: () => _showEditDialog(context, ref, null),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: assets.length,
                  itemBuilder: (context, i) {
                    final a = assets[i];
                    return Dismissible(
                      key: ValueKey(a.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      confirmDismiss: (_) => showConfirmSheet(
                        context,
                        title: 'Delete Asset?',
                        message: 'Delete "${a.name}"?',
                      ),
                      onDismissed: (_) => _delete(context, ref, a.id!),
                      child: _AssetTile(asset: a),
                    );
                  },
                ),
        ),
        onRetry: () => ref.invalidate(assetsControllerProvider),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  static Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    try {
      await ref.read(assetsControllerProvider.notifier).delete(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  static void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Asset? asset,
  ) {
    final symbol = TextEditingController(text: asset?.symbol ?? '');
    final name = TextEditingController(text: asset?.name ?? '');
    final currency = TextEditingController(text: asset?.currency ?? 'EUR');
    String type = asset?.type ?? 'STOCK';
    bool saving = false;

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
                  asset == null ? 'Add Asset' : 'Edit Asset',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: symbol,
                  decoration: const InputDecoration(
                    labelText: 'Symbol (e.g. VWCE.DE)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: kAssetTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setModalState(() => type = v ?? 'STOCK'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: currency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
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
                        onPressed: saving
                            ? null
                            : () async {
                                setModalState(() => saving = true);
                                try {
                                  await ref
                                      .read(assetsControllerProvider.notifier)
                                      .save(
                                        Asset(
                                          id: asset?.id,
                                          symbol: symbol.text,
                                          name: name.text,
                                          type: type,
                                          currency: currency.text,
                                        ),
                                      );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } on ApiException catch (e) {
                                  setModalState(() => saving = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.message}'),
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
                      '${a.symbol} • ${a.type} • ${a.currency ?? ''}',
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
                  Text(
                    a.currentPrice != null
                        ? '${a.currentPrice!.toStringAsFixed(2)} ${a.currency ?? ''}'
                        : 'No price',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (a.lastUpdate != null)
                    Text(
                      _formatDate(a.lastUpdate!),
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
                            tooltip: 'Refresh price',
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Future<void> _refreshPrice(BuildContext context, Asset a) async {
    setState(() => _refreshing = true);
    try {
      await ref.read(assetsControllerProvider.notifier).refreshPrice(a.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Price refreshed for ${a.symbol}')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }
}
