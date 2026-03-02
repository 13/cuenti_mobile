import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/data_provider.dart';
import '../../utils/number_format.dart';

class ScheduledScreen extends StatefulWidget {
  const ScheduledScreen({super.key});

  @override
  State<ScheduledScreen> createState() => _ScheduledScreenState();
}

class _ScheduledScreenState extends State<ScheduledScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dp = context.read<DataProvider>();
      await dp.loadScheduledTransactions();
      await dp.loadAccounts();
      await dp.loadCategories();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final items = dp.scheduledTransactions;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Icon(Icons.schedule, size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Center(child: Text('No scheduled transactions',
                    style: Theme.of(context).textTheme.titleMedium)),
              ],
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final st = items[i];
                final isLate = st.nextOccurrence.isBefore(DateTime.now());
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isLate ? Colors.red.withAlpha(30) : Colors.blue.withAlpha(30),
                      child: Icon(Icons.schedule, color: isLate ? Colors.red : Colors.blue),
                    ),
                    title: Text(st.payee ?? st.type),
                    subtitle: Text(
                      '${st.recurrencePattern} • Next: ${_formatDate(st.nextOccurrence)}'
                      '${isLate ? ' (LATE!)' : ''}\n'
                      '${st.fromAccountName ?? ''} ${st.type == 'TRANSFER' ? '→ ${st.toAccountName}' : ''}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatNumber(st.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            icon: const Icon(Icons.check, size: 18),
                            padding: EdgeInsets.zero,
                            tooltip: 'Post',
                            onPressed: () async {
                              await dp.postScheduledTransaction(st.id!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Transaction posted')));
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            icon: const Icon(Icons.skip_next, size: 18),
                            padding: EdgeInsets.zero,
                            tooltip: 'Skip',
                            onPressed: () async {
                              await dp.skipScheduledTransaction(st.id!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Occurrence skipped')));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    onLongPress: () => _showDeleteDialog(context, st),
                  ),
                );
              },
            ),
    );
  }

  void _showDeleteDialog(BuildContext context, ScheduledTransaction st) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Delete Schedule?'),
        content: Text('Delete "${st.payee ?? st.type}" recurring transaction?'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(c).colorScheme.error,
              foregroundColor: Theme.of(c).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.pop(c);
              context.read<DataProvider>().deleteScheduledTransaction(st.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
