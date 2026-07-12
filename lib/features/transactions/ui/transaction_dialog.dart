import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/cuenti_colors.dart';
import '../../../utils/number_format.dart';
import '../../accounts/ui/accounts_controller.dart';
import '../../categories/ui/categories_controller.dart';
import '../domain/transaction.dart';
import '../domain/transaction_filter.dart';
import '../domain/transaction_split.dart';
import 'transactions_controller.dart';

/// Mutable, in-progress row for the splits editor. Backed by
/// [TextEditingController]s so field widgets keep their own cursor/selection
/// state across rebuilds; converted to [TransactionSplit] only on save.
class _SplitDraft {
  _SplitDraft({this.categoryId, String amount = '', String memo = ''})
      : amount = TextEditingController(text: amount),
        memo = TextEditingController(text: memo);

  int? categoryId;
  final TextEditingController amount;
  final TextEditingController memo;

  void dispose() {
    amount.dispose();
    memo.dispose();
  }
}

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
  final List<_SplitDraft> _splits = [];
  bool _splitsTouched = false;

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
    for (final s in t?.splits ?? const <TransactionSplit>[]) {
      _splits.add(_SplitDraft(
        categoryId: s.categoryId,
        amount: formatNumber(s.amount),
        memo: s.memo ?? '',
      ));
    }
  }

  /// Same normalization as the main amount field: '.' thousands separator,
  /// ',' decimal separator (e.g. "1.234,56" -> 1234.56).
  double? _parseAmount(String text) {
    if (text.isEmpty) return null;
    final normalized = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  /// Null when valid (or the section hasn't been touched / is empty) so the
  /// caller can use it both to gate the Save button and to show the banner.
  String? get _splitsValidationMessage {
    if (!_splitsTouched || _splits.isEmpty) return null;
    if (_splits.any((s) => s.categoryId == null)) {
      return 'Each split needs a category';
    }
    final sum = _splits.fold<double>(
        0, (acc, s) => acc + (_parseAmount(s.amount.text) ?? 0));
    final mainAmount = _parseAmount(_amount.text) ?? 0;
    if ((sum - mainAmount).abs() > 0.005) {
      return 'Splits must sum to the amount: '
          '${formatNumber(sum)} of ${formatNumber(mainAmount)}';
    }
    return null;
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

                // Splits (transfers can't be split across categories)
                if (_type != 'TRANSFER') ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Splits',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Add split',
                        onPressed: () => setState(() {
                          _splits.add(_SplitDraft());
                          _splitsTouched = true;
                        }),
                      ),
                    ],
                  ),
                  for (var i = 0; i < _splits.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int?>(
                              initialValue:
                                  _splits[i].categoryId != null &&
                                      categories.any(
                                        (c) => c.id == _splits[i].categoryId,
                                      )
                                  ? _splits[i].categoryId
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: categories
                                  .where((c) => c.type == _type)
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.fullName ?? c.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _splits[i].categoryId = v;
                                _splitsTouched = true;
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _splits[i].amount,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) =>
                                  setState(() => _splitsTouched = true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _splits[i].memo,
                              decoration: const InputDecoration(
                                labelText: 'Memo',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) =>
                                  setState(() => _splitsTouched = true),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Remove split',
                            onPressed: () => setState(() {
                              _splits.removeAt(i).dispose();
                              _splitsTouched = true;
                            }),
                          ),
                        ],
                      ),
                    ),
                  if (_splitsValidationMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _splitsValidationMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],

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
                  onPressed:
                      _submitting || _splitsValidationMessage != null
                          ? null
                          : _save,
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
    if (_splitsValidationMessage != null) return;

    setState(() => _submitting = true);

    // TRANSFER never carries splits, regardless of stale state left over
    // from a type switch before saving.
    final splitsTouched = _type != 'TRANSFER' && _splitsTouched;
    final splits = _type == 'TRANSFER'
        ? const <TransactionSplit>[]
        : _splits
            .map(
              (s) => TransactionSplit(
                categoryId: s.categoryId,
                amount: _parseAmount(s.amount.text) ?? 0,
                memo: s.memo.text.isNotEmpty ? s.memo.text : null,
              ),
            )
            .toList();

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
      splits: splits,
    );

    try {
      await ref
          .read(transactionsControllerProvider(filter: widget.filter).notifier)
          .save(transaction, splitsTouched: splitsTouched);
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
    for (final s in _splits) {
      s.dispose();
    }
    super.dispose();
  }
}
