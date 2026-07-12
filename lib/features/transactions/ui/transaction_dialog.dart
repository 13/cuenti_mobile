import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/cuenti_colors.dart';
import '../../../utils/number_format.dart';
import '../../accounts/ui/accounts_controller.dart';
import '../../categories/ui/categories_controller.dart';
import '../domain/transaction.dart';
import '../domain/transaction_filter.dart';
import 'transactions_controller.dart';

class TransactionDialog extends ConsumerStatefulWidget {
  final Transaction? transaction;

  /// Filter of the transactions list this dialog was opened from. Saving
  /// goes through the controller instance keyed by this exact filter so
  /// the visible (possibly filtered) list refreshes after save.
  final TransactionFilter filter;
  const TransactionDialog({
    super.key,
    this.transaction,
    this.filter = const TransactionFilter(),
  });

  @override
  ConsumerState<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends ConsumerState<TransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late TextEditingController _amount;
  late TextEditingController _payee;
  late TextEditingController _memo;
  late TextEditingController _tags;
  int? _fromAccountId;
  int? _toAccountId;
  int? _categoryId;
  String _paymentMethod = 'NONE';
  late DateTime _date;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _type = t?.type ?? 'EXPENSE';
    _amount = TextEditingController(
      text: t != null ? formatNumber(t.amount) : '',
    );
    _payee = TextEditingController(text: t?.payee ?? '');
    _memo = TextEditingController(text: t?.memo ?? '');
    _tags = TextEditingController(text: t?.tags ?? '');
    _fromAccountId = t?.fromAccountId;
    _toAccountId = t?.toAccountId;
    _categoryId = t?.categoryId;
    _paymentMethod = t?.paymentMethod ?? 'NONE';
    _date = t?.transactionDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsControllerProvider).value ?? [];
    final categories = ref.watch(categoriesControllerProvider).value ?? [];
    final amountColor = amountColorFor(context, _type);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.transaction == null
                      ? 'Add Transaction'
                      : 'Edit Transaction',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Amount (moved FIRST)
                TextFormField(
                  controller: _amount,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final normalized = v.replaceAll('.', '').replaceAll(',', '.');
                    if (double.tryParse(normalized) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Type selector
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'EXPENSE',
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                    ButtonSegment(
                      value: 'INCOME',
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: 'TRANSFER',
                      label: Text('Transfer'),
                      icon: Icon(Icons.swap_horiz),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) => setState(() => _type = v.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return amountColor.withValues(alpha: 0.15);
                      }
                      return null;
                    }),
                  ),
                ),
                const SizedBox(height: 12),

                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text('${_date.day}.${_date.month}.${_date.year}'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                const SizedBox(height: 12),

                // From Account
                if (_type == 'EXPENSE' || _type == 'TRANSFER')
                  DropdownButtonFormField<int>(
                    initialValue: accounts.any((a) => a.id == _fromAccountId)
                        ? _fromAccountId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'From Account',
                      border: OutlineInputBorder(),
                    ),
                    items: accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.accountName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _fromAccountId = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                if (_type == 'EXPENSE' || _type == 'TRANSFER')
                  const SizedBox(height: 12),

                // To Account
                if (_type == 'INCOME' || _type == 'TRANSFER')
                  DropdownButtonFormField<int>(
                    initialValue: accounts.any((a) => a.id == _toAccountId)
                        ? _toAccountId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'To Account',
                      border: OutlineInputBorder(),
                    ),
                    items: accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.accountName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _toAccountId = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                if (_type == 'INCOME' || _type == 'TRANSFER')
                  const SizedBox(height: 12),

                // Payee
                TextFormField(
                  controller: _payee,
                  decoration: const InputDecoration(
                    labelText: 'Payee',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Category
                DropdownButtonFormField<int?>(
                  initialValue:
                      _categoryId == null ||
                          categories.any((c) => c.id == _categoryId)
                      ? _categoryId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...categories
                        .where((c) => _type == 'TRANSFER' || c.type == _type)
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.fullName ?? c.name),
                          ),
                        ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 12),

                // Payment method
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  items: kPaymentMethods
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _paymentMethod = v ?? 'NONE'),
                ),
                const SizedBox(height: 12),

                // Memo
                TextFormField(
                  controller: _memo,
                  decoration: const InputDecoration(
                    labelText: 'Memo',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Tags
                TextFormField(
                  controller: _tags,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _submitting ? null : _save,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final transaction = Transaction(
      id: widget.transaction?.id,
      type: _type,
      amount: double.parse(
        _amount.text.replaceAll('.', '').replaceAll(',', '.'),
      ),
      transactionDate: _date,
      fromAccountId: _fromAccountId,
      toAccountId: _toAccountId,
      payee: _payee.text.isNotEmpty ? _payee.text : null,
      categoryId: _categoryId,
      memo: _memo.text.isNotEmpty ? _memo.text : null,
      tags: _tags.text.isNotEmpty ? _tags.text : null,
      paymentMethod: _paymentMethod,
      sortOrder: widget.transaction?.sortOrder ?? 0,
    );

    try {
      await ref
          .read(transactionsControllerProvider(filter: widget.filter).notifier)
          .save(transaction);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _payee.dispose();
    _memo.dispose();
    _tags.dispose();
    super.dispose();
  }
}
