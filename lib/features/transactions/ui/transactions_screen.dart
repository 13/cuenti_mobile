import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../utils/number_format.dart';
import '../../accounts/ui/accounts_controller.dart';
import '../domain/transaction.dart';
import 'transaction_dialog.dart';
import 'transactions_controller.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _scrollController = ScrollController();
  String _search = '';
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(transactionsControllerProvider(accountId: _selectedAccountId)
              .notifier)
          .loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync =
        ref.watch(transactionsControllerProvider(accountId: _selectedAccountId));
    final accounts = ref.watch(accountsControllerProvider).value ?? [];

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Account',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedAccountId,
                  isDense: true,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Accounts')),
                    ...accounts.map((a) => DropdownMenuItem(
                        value: a.id, child: Text(a.accountName))),
                  ],
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                ref.invalidate(
                    transactionsControllerProvider(accountId: _selectedAccountId));
                return ref.read(
                    transactionsControllerProvider(accountId: _selectedAccountId)
                        .future);
              },
              child: AsyncValueWidget<TransactionsState>(
                value: transactionsAsync,
                data: (state) {
                  var transactions = state.items;
                  if (_search.isNotEmpty) {
                    final q = _search.toLowerCase();
                    transactions = transactions.where((t) =>
                        (t.payee ?? '').toLowerCase().contains(q) ||
                        (t.categoryName ?? '').toLowerCase().contains(q) ||
                        (t.memo ?? '').toLowerCase().contains(q) ||
                        t.amount.toString().contains(q)).toList();
                  }

                  // Build grouped list items with monthly separators
                  final items = <_ListItem>[];
                  String? lastMonth;
                  for (final t in transactions) {
                    final monthKey =
                        '${t.transactionDate.year}-${t.transactionDate.month.toString().padLeft(2, '0')}';
                    if (monthKey != lastMonth) {
                      final monthLabel = DateFormat('MMMM yyyy').format(t.transactionDate);
                      items.add(_ListItem(header: monthLabel));
                      lastMonth = monthKey;
                    }
                    items.add(_ListItem(transaction: t));
                  }

                  if (items.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 120),
                        Icon(Icons.receipt_long, size: 64,
                            color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Center(child: Text('No transactions',
                            style: Theme.of(context).textTheme.titleMedium)),
                        const SizedBox(height: 8),
                        Center(child: Text('Tap + to add your first transaction.',
                            style: Theme.of(context).textTheme.bodySmall)),
                      ],
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: items.length + (state.loadingMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                              child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2))),
                        );
                      }
                      final item = items[i];
                      if (item.header != null) {
                        return _MonthHeader(title: item.header!);
                      }
                      return _TransactionTile(
                        transaction: item.transaction!,
                        accountId: _selectedAccountId,
                        onDelete: _delete,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _delete(int id) async {
    try {
      await ref
          .read(transactionsControllerProvider(accountId: _selectedAccountId)
              .notifier)
          .delete(id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionDialog(accountId: _selectedAccountId),
    );
  }
}

class _ListItem {
  final String? header;
  final Transaction? transaction;
  _ListItem({this.header, this.transaction});
}

class _MonthHeader extends StatelessWidget {
  final String title;
  const _MonthHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final int? accountId;
  final void Function(int id) onDelete;
  const _TransactionTile(
      {required this.transaction, required this.accountId, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'EXPENSE';
    final isIncome = transaction.type == 'INCOME';
    final color = isExpense ? Colors.red : (isIncome ? Colors.green : Colors.blue);

    final accountName = isExpense
        ? transaction.fromAccountName
        : (isIncome ? transaction.toAccountName : '${transaction.fromAccountName} → ${transaction.toAccountName}');

    return Dismissible(
      key: ValueKey(transaction.id),
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
          title: const Text('Delete Transaction?'),
          content: const Text('This action cannot be undone.'),
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
      onDismissed: (_) {
        if (transaction.id != null) onDelete(transaction.id!);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(
            isExpense ? Icons.arrow_downward : (isIncome ? Icons.arrow_upward : Icons.swap_horiz),
            color: color,
          ),
        ),
        title: Text(transaction.payee ?? transaction.type),
        subtitle: Text(
          '${accountName ?? ''} • ${transaction.categoryName ?? ''}\n${_formatDate(transaction.transactionDate)}',
        ),
        isThreeLine: true,
        trailing: Text(
          '${isExpense ? '-' : (isIncome ? '+' : '')}${formatNumber(transaction.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => TransactionDialog(transaction: transaction, accountId: accountId),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
