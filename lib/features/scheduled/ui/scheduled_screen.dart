import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../utils/number_format.dart';
import '../domain/scheduled_transaction.dart';
import 'scheduled_controller.dart';

class ScheduledScreen extends ConsumerWidget {
  const ScheduledScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledAsync = ref.watch(scheduledControllerProvider);

    return AsyncValueWidget<List<ScheduledTransaction>>(
      value: scheduledAsync,
      data: (items) => RefreshIndicator(
        onRefresh: () {
          ref.invalidate(scheduledControllerProvider);
          return ref.read(scheduledControllerProvider.future);
        },
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
                              onPressed: () => _post(context, ref, st.id!),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              icon: const Icon(Icons.skip_next, size: 18),
                              padding: EdgeInsets.zero,
                              tooltip: 'Skip',
                              onPressed: () => _skip(context, ref, st.id!),
                            ),
                          ),
                        ],
                      ),
                      onLongPress: () => _showDeleteDialog(context, ref, st),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _post(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(scheduledControllerProvider.notifier).post(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction posted')));
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

  Future<void> _skip(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(scheduledControllerProvider.notifier).skip(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Occurrence skipped')));
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref, ScheduledTransaction st) {
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
            onPressed: () async {
              Navigator.pop(c);
              try {
                await ref.read(scheduledControllerProvider.notifier).delete(st.id!);
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
