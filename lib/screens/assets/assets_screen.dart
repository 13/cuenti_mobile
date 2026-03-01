import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/data_provider.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { await context.read<DataProvider>().loadAssets(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: dp.assets.isEmpty
            ? const Center(child: Text('No assets'))
            : ListView.builder(
                itemCount: dp.assets.length,
                itemBuilder: (context, i) {
                  final a = dp.assets[i];
                  return Dismissible(
                    key: ValueKey(a.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) => showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Delete Asset?'),
                        content: Text('Delete "${a.name}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                        ],
                      ),
                    ),
                    onDismissed: (_) => dp.deleteAsset(a.id!),
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
                              onTap: () async {
                                await dp.refreshAssetPrice(a.id!);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Price refreshed for ${a.symbol}')),
                                  );
                                }
                              },
                              child: Icon(Icons.refresh, size: 18,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                          ],
                        ),
                        onTap: () => _showEditDialog(context, a),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null),
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

  void _showEditDialog(BuildContext context, Asset? asset) {
    final symbol = TextEditingController(text: asset?.symbol ?? '');
    final name = TextEditingController(text: asset?.name ?? '');
    final currency = TextEditingController(text: asset?.currency ?? 'EUR');
    String type = asset?.type ?? 'STOCK';
    bool saving = false;

    showModalBottomSheet(
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
                  items: Asset.assetTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
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
                        await context.read<DataProvider>().saveAsset({
                          'symbol': symbol.text,
                          'name': name.text,
                          'type': type,
                          'currency': currency.text,
                        }, id: asset?.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModalState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${context.read<DataProvider>().lastError ?? e}'),
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
