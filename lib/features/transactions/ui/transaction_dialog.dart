import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_controller.dart';
import 'package:cuentimobile/features/categories/ui/categories_controller.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:cuentimobile/features/payees/ui/payee_autocomplete_field.dart';
import 'package:cuentimobile/features/payees/ui/payees_controller.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_split.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:cuentimobile/features/vehicles/domain/fuel_memo.dart';
import 'package:cuentimobile/features/vehicles/ui/fuel_meta_provider.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  const TransactionDialog({
    super.key,
    this.transaction,
    this.filter = const TransactionFilter(),
  });
  final Transaction? transaction;

  /// Filter of the transactions list this dialog was opened from. Saving
  /// goes through the controller instance keyed by this exact filter so
  /// the visible (possibly filtered) list refreshes after save.
  final TransactionFilter filter;

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
  late TextEditingController _fuelOdometer;
  late TextEditingController _fuelLiters;
  bool _fuelFullTank = false;
  String _fuelRemainder = '';
  bool _fuelSyncing = false;
  bool _fuelVisible = false; // last built visibility, used by _save()

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
    final fuelTokens = parseFuelTokens(t?.memo);
    _fuelOdometer = TextEditingController(
      text: fuelTokens.odometer != null
          ? formatFuelNumber(fuelTokens.odometer!)
          : '',
    );
    _fuelLiters = TextEditingController(
      text: fuelTokens.liters != null
          ? formatFuelNumber(fuelTokens.liters!)
          : '',
    );
    _fuelFullTank = fuelTokens.fullTank;
    _fuelRemainder = fuelTokens.remainderText;
    for (final s in t?.splits ?? const <TransactionSplit>[]) {
      _splits.add(
        _SplitDraft(
          categoryId: s.categoryId,
          amount: formatNumber(s.amount),
          memo: s.memo ?? '',
        ),
      );
    }
  }

  /// Same normalization as the main amount field: '.' thousands separator,
  /// ',' decimal separator (e.g. "1.234,56" -> 1234.56).
  double? _parseAmount(String text) {
    if (text.isEmpty) return null;
    final normalized = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  /// Fuel numbers accept comma or dot decimals ("41,3" -> 41.3), unlike
  /// _parseAmount which also strips thousands separators.
  double? _parseFuelNum(String text) =>
      text.isEmpty ? null : double.tryParse(text.replaceAll(',', '.'));

  void _syncMemoFromFuelFields() {
    if (_fuelSyncing) return;
    _fuelSyncing = true;
    _memo.text = buildFuelMemo(
      _parseFuelNum(_fuelOdometer.text),
      _parseFuelNum(_fuelLiters.text),
      _fuelRemainder,
      fullTank: _fuelFullTank,
    );
    _fuelSyncing = false;
  }

  void _reparseFuelFromMemo(String memo) {
    if (_fuelSyncing) return;
    final tokens = parseFuelTokens(memo);
    _fuelSyncing = true;
    setState(() {
      _fuelOdometer.text = tokens.odometer != null
          ? formatFuelNumber(tokens.odometer!)
          : '';
      _fuelLiters.text = tokens.liters != null
          ? formatFuelNumber(tokens.liters!)
          : '';
      _fuelFullTank = tokens.fullTank;
      _fuelRemainder = tokens.remainderText;
    });
    _fuelSyncing = false;
  }

  /// Odometer comparison baseline: the newest reading strictly before this
  /// transaction's date (web parity — `VehicleReportService.lastOdometer`).
  /// Using the newest reading overall would compare a fill-up against
  /// itself when editing the most recent entry (distance 0, false
  /// "not increasing" warning). Server dates are date-only, so compare on
  /// the date part only.
  double? _fuelBaseline(FuelMeta? meta) {
    if (meta == null) return null;
    final txDate = DateTime(_date.year, _date.month, _date.day);
    for (final r in meta.readings) {
      if (r.date.isBefore(txDate)) return r.odometer;
    }
    return null;
  }

  String? get _fuelLitersWarning {
    final liters = _parseFuelNum(_fuelLiters.text);
    if (liters == null) return null;
    return (liters <= 0 || liters > 200) ? 'Implausible liters value' : null;
  }

  /// Message + isWarning for the line under the fuel fields; null when
  /// nothing to show. First matching rule wins (mirrors the web app).
  (String, bool)? _fuelInfoLine(double? lastOdometer) {
    final odometer = _parseFuelNum(_fuelOdometer.text);
    if (odometer == null || lastOdometer == null) return null;
    final distance = odometer - lastOdometer;
    if (distance <= 0) {
      return (
        'Odometer is not higher than the last reading '
            '(${formatFuelNumber(lastOdometer)})',
        true,
      );
    }
    if (distance > 2000) {
      return (
        'Very large jump since the last reading '
            '(${formatFuelNumber(distance)} km) — typo?',
        true,
      );
    }
    final liters = _parseFuelNum(_fuelLiters.text);
    if (_fuelFullTank && liters != null && liters > 0) {
      final consumption = (liters / distance * 100).toStringAsFixed(1);
      return (
        '${formatFuelNumber(distance)} km since last, ~$consumption L/100km',
        false,
      );
    }
    return ('${formatFuelNumber(distance)} km since last fill-up', false);
  }

  /// Null when valid (or the section hasn't been touched / is empty) so the
  /// caller can use it both to gate the Save button and to show the banner.
  /// Also null for TRANSFER, mirroring the section's visibility: an invalid
  /// draft must not keep Save disabled after the user switches to a type
  /// that hides the section (the save path drops splits for TRANSFER anyway).
  String? get _splitsValidationMessage {
    if (_type == 'TRANSFER' || !_splitsTouched || _splits.isEmpty) return null;
    if (_splits.any((s) => s.categoryId == null)) {
      return 'Each split needs a category';
    }
    final sum = _splits.fold<double>(
      0,
      (acc, s) => acc + (_parseAmount(s.amount.text) ?? 0),
    );
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
    final payees = ref.watch(payeesControllerProvider).value ?? [];
    final amountColor = amountColorFor(context, _type);

    final fuelMeta = _type == 'EXPENSE' && _categoryId != null
        ? ref.watch(fuelMetaProvider(_categoryId!)).value
        : null;
    _fuelVisible =
        _type == 'EXPENSE' &&
        ((fuelMeta?.isFuel ?? false) ||
            parseFuelTokens(_memo.text).hasFuelData);
    final fuelBaseline = _fuelBaseline(fuelMeta);

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
                    final normalized = v
                        .replaceAll('.', '')
                        .replaceAll(',', '.');
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
                PayeeAutocompleteField(
                  controller: _payee,
                  payees: payees,
                ),
                const SizedBox(height: 12),

                // Category
                CategoryPickerField(
                  categories: categories
                      .where((c) => _type == 'TRANSFER' || c.type == _type)
                      .toList(),
                  selectedId: _categoryId,
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 12),

                // Fuel entry (structured tanking fields)
                if (_fuelVisible) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('fuel-odometer'),
                          controller: _fuelOdometer,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Odometer (km)',
                            border: const OutlineInputBorder(),
                            helperText: fuelBaseline != null
                                ? 'last: ${formatFuelNumber(fuelBaseline)}'
                                : null,
                          ),
                          onChanged: (_) => setState(_syncMemoFromFuelFields),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          key: const Key('fuel-liters'),
                          controller: _fuelLiters,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Liters',
                            border: const OutlineInputBorder(),
                            helperText: _fuelLitersWarning,
                            helperStyle: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onChanged: (_) => setState(_syncMemoFromFuelFields),
                        ),
                      ),
                    ],
                  ),
                  if (_fuelInfoLine(fuelBaseline) case (
                    final message,
                    final isWarning,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        message,
                        key: const Key('fuel-info'),
                        style: TextStyle(
                          color: isWarning
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  SwitchListTile(
                    key: const Key('fuel-full'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Full tank'),
                    value: _fuelFullTank,
                    onChanged: (v) => setState(() {
                      _fuelFullTank = v;
                      _syncMemoFromFuelFields();
                    }),
                  ),
                  const SizedBox(height: 12),
                ],

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
                            child: CategoryPickerField(
                              categories: categories
                                  .where((c) => c.type == _type)
                                  .toList(),
                              selectedId: _splits[i].categoryId,
                              allowNone: false,
                              isDense: true,
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
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (_parseAmount(v) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
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
                  onChanged: (v) =>
                      setState(() => _paymentMethod = v ?? 'NONE'),
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
                  onChanged: _reparseFuelFromMemo,
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
                  onPressed: _submitting || _splitsValidationMessage != null
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

    if (_fuelVisible &&
        _parseFuelNum(_fuelOdometer.text) == null &&
        _parseFuelNum(_fuelLiters.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No km/liters entered — this entry will not appear in the '
            'vehicle report',
          ),
        ),
      );
    }

    setState(() => _submitting = true);

    // TRANSFER never carries splits. If the transaction being edited had
    // existing splits, saving as TRANSFER must explicitly clear them
    // server-side (splitsTouched: true + empty list) rather than omitting
    // the splits key — omitting it makes the backend preserve the old
    // splits on the now-transfer row permanently, since the dialog hides
    // the splits section (and thus any way to fix it) for transfers.
    final splitsTouched = _type == 'TRANSFER'
        ? (widget.transaction?.splits.isNotEmpty ?? false)
        : _splitsTouched;
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
      // Kill the stale last-odometer hint so the next dialog for this
      // category refetches instead of showing pre-save data.
      if (mounted && _categoryId != null) {
        ref.invalidate(fuelMetaProvider(_categoryId!));
      }
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
    _fuelOdometer.dispose();
    _fuelLiters.dispose();
    for (final s in _splits) {
      s.dispose();
    }
    super.dispose();
  }
}
