import 'dart:async';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/entity_edit_sheet.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:cuentimobile/features/currencies/ui/currencies_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                      message: L.of(context).currenciesEmpty,
                      actionLabel: L.of(context).currenciesAdd,
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
                        title: L.of(context).currenciesDeleteTitle,
                        message: L
                            .of(context)
                            .commonDeleteConfirm('${c.code} - ${c.name}'),
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
                                        L
                                            .of(context)
                                            .currenciesFormatSummary(
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
            content: Text(e.localizedMessage(L.of(context))),
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
