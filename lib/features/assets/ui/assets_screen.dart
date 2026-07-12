import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/async_value_widget.dart';
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
        data: (assets) => RefreshIndicator(
          onRefresh: () {
            ref.invalidate(assetsControllerProvider);
            return ref.read(assetsControllerProvider.future);
          },
          child: assets.isEmpty
              ? ListView(children: [
                  const SizedBox(height: 120),
                  Icon(Icons.show_chart, size: 64,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Center(child: Text('No assets yet',
                      style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 8),
                  Center(child: Text('Tap + to add an asset.',
                      style: Theme.of(context).textTheme.bodySmall)),
                ])
              : ListView.builder(
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
                        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      confirmDismiss: (_) => showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          icon: const Icon(Icons.delete_outline),
                          title: const Text('Delete Asset?'),
                          content: Text('Delete "${a.name}"?'),
                          actions: [
                            OutlinedButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(c).colorScheme.error,
                                foregroundColor: Theme.of(c).colorScheme.onError,
                              ),
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (_) => _delete(context, ref, a.id!),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _typeColor(a.type).withAlpha(30),
                            child: Icon(_typeIcon(a.type), color: _typeColor(a.type)),
                          ),
                          title: Text(a.name),
                          subtitle: Text('${a.symbol} • ${a.type} • ${a.currency ?? ''}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                a.currentPrice != null
                                    ? '${a.currentPrice!.toStringAsFixed(2)} ${a.currency ?? ''}'
                                    : 'No price',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (a.lastUpdate != null)
                                Text(
                                  _formatDate(a.lastUpdate!),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              GestureDetector(
                                onTap: () => _refreshPrice(context, ref, a),
                                child: Icon(Icons.refresh, size: 18,
                                    color: Theme.of(context).colorScheme.primary),
                              ),
                            ],
                          ),
                          onTap: () => _showEditDialog(context, ref, a),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'ETF': return Icons.pie_chart;
      case 'CRYPTO': return Icons.currency_bitcoin;
      default: return Icons.show_chart;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'ETF': return Colors.blue;
      case 'CRYPTO': return Colors.orange;
      default: return Colors.green;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
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

  Future<void> _refreshPrice(BuildContext context, WidgetRef ref, Asset a) async {
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
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Asset? asset) {
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
            left: 16, right: 16, top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(asset == null ? 'Add Asset' : 'Edit Asset',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(controller: symbol, decoration: const InputDecoration(labelText: 'Symbol (e.g. VWCE.DE)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: kAssetTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setModalState(() => type = v ?? 'STOCK'),
                ),
                const SizedBox(height: 12),
                TextField(controller: currency, decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: saving ? null : () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(
                    onPressed: saving ? null : () async {
                      setModalState(() => saving = true);
                      try {
                        await ref.read(assetsControllerProvider.notifier).save(
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
                              backgroundColor: Theme.of(ctx).colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    child: saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  )),
                ]),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
