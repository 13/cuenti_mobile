import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart' as m;
import '../../providers/data_provider.dart';
import '../../utils/number_format.dart';
import '../../widgets/transaction_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool _loading = true;
  String _search = '';
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dp = context.read<DataProvider>();
      await Future.wait([
        dp.loadTransactions(accountId: _selectedAccountId),
        dp.loadAccounts(),
        dp.loadCategories(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    var transactions = dp.transactions;

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
      final monthKey = '${t.transactionDate.year}-${t.transactionDate.month.toString().padLeft(2, '0')}';
      if (monthKey != lastMonth) {
        final monthLabel = DateFormat('MMMM yyyy').format(t.transactionDate);
        items.add(_ListItem(header: monthLabel));
        lastMonth = monthKey;
      }
      items.add(_ListItem(transaction: t));
    }

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
                    ...dp.accounts.map((a) => DropdownMenuItem(
                      value: a.id, child: Text(a.accountName))),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedAccountId = v);
                    _load();
                  },
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: items.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 200),
                              Center(child: Text('No transactions')),
                            ],
                          )
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final item = items[i];
                              if (item.header != null) {
                                return _MonthHeader(title: item.header!);
                              }
                              return _TransactionTile(transaction: item.transaction!);
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

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const TransactionDialog(),
    ).then((_) => _load());
  }
}

class _ListItem {
  final String? header;
  final m.Transaction? transaction;
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
  final m.Transaction transaction;
  const _TransactionTile({required this.transaction});

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
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Delete Transaction?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
          ],
        ),
      ),
      onDismissed: (_) {
        if (transaction.id != null) {
          context.read<DataProvider>().deleteTransaction(transaction.id!);
        }
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
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => TransactionDialog(transaction: transaction),
          ).then((_) {
            if (context.mounted) {
              context.findAncestorStateOfType<_TransactionsScreenState>()?._load();
            }
          });
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
