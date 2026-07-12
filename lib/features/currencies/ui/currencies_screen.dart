import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../domain/currency.dart';
import 'currencies_controller.dart';

class CurrenciesScreen extends ConsumerWidget {
  const CurrenciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currenciesAsync = ref.watch(currenciesControllerProvider);

    return Scaffold(
      body: AsyncValueWidget<List<Currency>>(
        value: currenciesAsync,
        skeleton: SkeletonLoader.tiles(items: 6, height: 76),
        data: (currencies) => RefreshIndicator(
          onRefresh: () {
            ref.invalidate(currenciesControllerProvider);
            return ref.read(currenciesControllerProvider.future);
          },
          child: currencies.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    EmptyState(
                      icon: Icons.currency_exchange,
                      message: 'No currencies yet',
                      actionLabel: 'Add currency',
                      onAction: () => _showEditDialog(context, ref, null),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: currencies.length,
                  itemBuilder: (context, i) {
                    final c = currencies[i];
                    return Dismissible(
                      key: ValueKey(c.id),
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
                        title: 'Delete Currency?',
                        message: 'Delete "${c.code} - ${c.name}"?',
                      ),
                      onDismissed: (_) => _delete(context, ref, c.id!),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showEditDialog(context, ref, c),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
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
                                        'Symbol: ${c.symbol} • Decimals: ${c.fracDigits} • Dec: "${c.decimalChar}" Group: "${c.groupingChar}"',
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
        ),
        onRetry: () => ref.invalidate(currenciesControllerProvider),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(currenciesControllerProvider.notifier).delete(id);
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

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Currency? currency,
  ) {
    final code = TextEditingController(text: currency?.code ?? '');
    final name = TextEditingController(text: currency?.name ?? '');
    final symbol = TextEditingController(text: currency?.symbol ?? '');
    final decimalChar = TextEditingController(
      text: currency?.decimalChar ?? ',',
    );
    final groupingChar = TextEditingController(
      text: currency?.groupingChar ?? '.',
    );
    int fracDigits = currency?.fracDigits ?? 2;
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
                  currency == null ? 'Add Currency' : 'Edit Currency',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: code,
                  decoration: const InputDecoration(
                    labelText: 'Code (e.g. EUR)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Name (e.g. Euro)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: symbol,
                  decoration: const InputDecoration(
                    labelText: 'Symbol (e.g. €)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: decimalChar,
                        decoration: const InputDecoration(
                          labelText: 'Decimal',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: groupingChar,
                        decoration: const InputDecoration(
                          labelText: 'Grouping',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: fracDigits,
                        decoration: const InputDecoration(
                          labelText: 'Decimals',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(
                          9,
                          (i) => DropdownMenuItem(value: i, child: Text('$i')),
                        ),
                        onChanged: (v) =>
                            setModalState(() => fracDigits = v ?? 2),
                      ),
                    ),
                  ],
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
                                      .read(
                                        currenciesControllerProvider.notifier,
                                      )
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
