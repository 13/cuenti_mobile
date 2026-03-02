import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart' as m;
import '../providers/data_provider.dart';
import '../utils/number_format.dart';

class TransactionDialog extends StatefulWidget {
  final m.Transaction? transaction;
  const TransactionDialog({super.key, this.transaction});

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _type = t?.type ?? 'EXPENSE';
    _amount = TextEditingController(text: t != null ? formatNumber(t.amount) : '');
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
    final dp = context.watch<DataProvider>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.transaction == null ? 'Add Transaction' : 'Edit Transaction',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Type selector
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'EXPENSE', label: Text('Expense'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment(value: 'INCOME', label: Text('Income'), icon: Icon(Icons.arrow_upward)),
                  ButtonSegment(value: 'TRANSFER', label: Text('Transfer'), icon: Icon(Icons.swap_horiz)),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
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

              // Amount
              TextFormField(
                controller: _amount,
                decoration: const InputDecoration(
                  labelText: 'Amount', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final normalized = v.replaceAll('.', '').replaceAll(',', '.');
                  if (double.tryParse(normalized) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // From Account
              if (_type == 'EXPENSE' || _type == 'TRANSFER')
                DropdownButtonFormField<int>(
                  initialValue: dp.accounts.any((a) => a.id == _fromAccountId) ? _fromAccountId : null,
                  decoration: const InputDecoration(
                    labelText: 'From Account', border: OutlineInputBorder()),
                  items: dp.accounts.map((a) => DropdownMenuItem(
                    value: a.id, child: Text(a.accountName))).toList(),
                  onChanged: (v) => setState(() => _fromAccountId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              if (_type == 'EXPENSE' || _type == 'TRANSFER')
                const SizedBox(height: 12),

              // To Account
              if (_type == 'INCOME' || _type == 'TRANSFER')
                DropdownButtonFormField<int>(
                  initialValue: dp.accounts.any((a) => a.id == _toAccountId) ? _toAccountId : null,
                  decoration: const InputDecoration(
                    labelText: 'To Account', border: OutlineInputBorder()),
                  items: dp.accounts.map((a) => DropdownMenuItem(
                    value: a.id, child: Text(a.accountName))).toList(),
                  onChanged: (v) => setState(() => _toAccountId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              if (_type == 'INCOME' || _type == 'TRANSFER')
                const SizedBox(height: 12),

              // Payee
              TextFormField(
                controller: _payee,
                decoration: const InputDecoration(
                  labelText: 'Payee', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<int?>(
                initialValue: _categoryId == null || dp.categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                decoration: const InputDecoration(
                  labelText: 'Category', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...dp.categories
                      .where((c) => _type == 'TRANSFER' || c.type == _type)
                      .map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.fullName ?? c.name))),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 12),

              // Payment method
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method', border: OutlineInputBorder()),
                items: m.Transaction.paymentMethods
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _paymentMethod = v ?? 'NONE'),
              ),
              const SizedBox(height: 12),

              // Memo
              TextFormField(
                controller: _memo,
                decoration: const InputDecoration(
                  labelText: 'Memo', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // Tags
              TextFormField(
                controller: _tags,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
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
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = {
      'type': _type,
      'amount': double.parse(_amount.text.replaceAll('.', '').replaceAll(',', '.')),
      'transactionDate': _date.toIso8601String(),
      'fromAccountId': _fromAccountId,
      'toAccountId': _toAccountId,
      'payee': _payee.text.isNotEmpty ? _payee.text : null,
      'categoryId': _categoryId,
      'memo': _memo.text.isNotEmpty ? _memo.text : null,
      'tags': _tags.text.isNotEmpty ? _tags.text : null,
      'paymentMethod': _paymentMethod,
      'sortOrder': 0,
    };

    try {
      await context.read<DataProvider>().saveTransaction(data, id: widget.transaction?.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${context.read<DataProvider>().lastError ?? e}'),
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
