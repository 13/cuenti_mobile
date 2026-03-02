import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/data_provider.dart';

class CurrenciesScreen extends StatefulWidget {
  const CurrenciesScreen({super.key});

  @override
  State<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends State<CurrenciesScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { await context.read<DataProvider>().loadCurrencies(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: dp.currencies.isEmpty
            ? ListView(children: [
                const SizedBox(height: 120),
                Icon(Icons.currency_exchange, size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Center(child: Text('No currencies yet',
                    style: Theme.of(context).textTheme.titleMedium)),
                const SizedBox(height: 8),
                Center(child: Text('Tap + to add a currency.',
                    style: Theme.of(context).textTheme.bodySmall)),
              ])
            : ListView.builder(
                itemCount: dp.currencies.length,
                itemBuilder: (context, i) {
                  final c = dp.currencies[i];
                  return Dismissible(
                    key: ValueKey(c.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                    confirmDismiss: (_) => showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        icon: const Icon(Icons.delete_outline),
                        title: const Text('Delete Currency?'),
                        actions: [
                          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(ctx).colorScheme.error,
                              foregroundColor: Theme.of(ctx).colorScheme.onError,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                    onDismissed: (_) => dp.deleteCurrency(c.id!),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(c.symbol)),
                      title: Text('${c.code} - ${c.name}'),
                      subtitle: Text('Symbol: ${c.symbol} • Decimals: ${c.fracDigits} • Dec: "${c.decimalChar}" Group: "${c.groupingChar}"'),
                      onTap: () => _showEditDialog(context, c),
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

  void _showEditDialog(BuildContext context, Currency? currency) {
    final code = TextEditingController(text: currency?.code ?? '');
    final name = TextEditingController(text: currency?.name ?? '');
    final symbol = TextEditingController(text: currency?.symbol ?? '');
    final decimalChar = TextEditingController(text: currency?.decimalChar ?? ',');
    final groupingChar = TextEditingController(text: currency?.groupingChar ?? '.');
    int fracDigits = currency?.fracDigits ?? 2;
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
                Text(currency == null ? 'Add Currency' : 'Edit Currency',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(controller: code, decoration: const InputDecoration(labelText: 'Code (e.g. EUR)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name (e.g. Euro)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: symbol, decoration: const InputDecoration(labelText: 'Symbol (e.g. €)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: decimalChar, decoration: const InputDecoration(labelText: 'Decimal', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: groupingChar, decoration: const InputDecoration(labelText: 'Grouping', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: fracDigits,
                      decoration: const InputDecoration(labelText: 'Decimals', border: OutlineInputBorder()),
                      items: List.generate(9, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                      onChanged: (v) => setModalState(() => fracDigits = v ?? 2),
                    ),
                  ),
                ]),
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
                        await context.read<DataProvider>().saveCurrency({
                          'code': code.text,
                          'name': name.text,
                          'symbol': symbol.text,
                          'decimalChar': decimalChar.text,
                          'groupingChar': groupingChar.text,
                          'fracDigits': fracDigits,
                        }, id: currency?.id);
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
