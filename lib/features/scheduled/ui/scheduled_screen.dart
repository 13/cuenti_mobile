import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../domain/scheduled_transaction.dart';
import 'scheduled_controller.dart';

class ScheduledScreen extends ConsumerWidget {
  const ScheduledScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledAsync = ref.watch(scheduledControllerProvider);

    return AsyncValueWidget<List<ScheduledTransaction>>(
      value: scheduledAsync,
      skeleton: SkeletonLoader.tiles(items: 4, height: 108),
      data: (items) => RefreshIndicator(
        onRefresh: () {
          ref.invalidate(scheduledControllerProvider);
          return ref.read(scheduledControllerProvider.future);
        },
        child: items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.schedule,
                    message: 'No scheduled transactions',
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
                  final isLate = st.nextOccurrence.isBefore(DateTime.now());
                  final color = isLate
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onLongPress: () => _showDeleteDialog(context, ref, st),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.schedule, color: color),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        st.payee ?? st.type,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${st.recurrencePattern} • Next: ${_formatDate(st.nextOccurrence)}'
                                        '${isLate ? ' (LATE!)' : ''}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                      if ((st.fromAccountName ?? '').isNotEmpty)
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
                                  crossAxisAlignment: CrossAxisAlignment.end,
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
                                      onChanged: (v) =>
                                          _toggleEnabled(context, ref, st, v),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _post(context, ref, st.id!),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Post'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _skip(context, ref, st.id!),
                                  icon: const Icon(Icons.skip_next, size: 18),
                                  label: const Text('Skip'),
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
      ),
    );
  }

  Future<void> _toggleEnabled(
    BuildContext context,
    WidgetRef ref,
    ScheduledTransaction st,
    bool value,
  ) async {
    try {
      await ref
          .read(scheduledControllerProvider.notifier)
          .save(st.copyWith(enabled: value));
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

  Future<void> _post(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(scheduledControllerProvider.notifier).post(id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction posted')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Occurrence skipped')));
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

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ScheduledTransaction st,
  ) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Delete Schedule?',
      message: 'Delete "${st.payee ?? st.type}" recurring transaction?',
    );
    if (!confirmed) return;
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
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
