import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/enum_labels.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/enum_dropdown.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_controller.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/categories_controller.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:cuentimobile/features/payees/domain/payee.dart';
import 'package:cuentimobile/features/payees/ui/payee_picker_field.dart';
import 'package:cuentimobile/features/payees/ui/payees_controller.dart';
import 'package:cuentimobile/features/transactions/domain/split_validation.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_split.dart';
import 'package:cuentimobile/features/transactions/ui/fuel_entry_section.dart';
import 'package:cuentimobile/features/transactions/ui/split_draft.dart';
import 'package:cuentimobile/features/transactions/ui/splits_editor.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:cuentimobile/features/vehicles/domain/fuel_advice.dart';
import 'package:cuentimobile/features/vehicles/domain/fuel_memo.dart';
import 'package:cuentimobile/features/vehicles/ui/fuel_meta_provider.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the add/edit sheet.
///
/// [localId] identifies the outbox entry [transaction] came from when it
/// has never reached the server (no server id yet to key on). Passing it
/// through to the dialog, and from there to
/// [TransactionsController.save], is what lets editing an unsent entry
/// replace it in the outbox instead of queuing a second one beside it.
Future<void> showTransactionDialog(
  BuildContext context, {
  Transaction? transaction,
  String? localId,
  TransactionFilter filter = const TransactionFilter(),
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => TransactionDialog(
      transaction: transaction,
      localId: localId,
      filter: filter,
    ),
  );
}

class TransactionDialog extends ConsumerStatefulWidget {
  const TransactionDialog({
    super.key,
    this.transaction,
    this.localId,
    this.filter = const TransactionFilter(),
  });
  final Transaction? transaction;

  /// The outbox key of the pending entry this dialog is editing, if
  /// [transaction] has never reached the server. Carried through to
  /// [TransactionsController.save] so an offline edit replaces that entry
  /// instead of queuing a second one beside it.
  final String? localId;

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
  final List<SplitDraft> _splits = [];
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
        SplitDraft(
          categoryId: s.categoryId,
          amount: formatNumber(s.amount),
          memo: s.memo ?? '',
        ),
      );
    }
  }

  /// Same normalization as the main amount field: '.' thousands separator,
  /// ',' decimal separator (e.g. "1.234,56" -> 1234.56).
  void _syncMemoFromFuelFields() {
    if (_fuelSyncing) return;
    _fuelSyncing = true;
    _memo.text = buildFuelMemo(
      parseFuelInput(_fuelOdometer.text),
      parseFuelInput(_fuelLiters.text),
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

  /// Null when valid (or the section hasn't been touched / is empty) so the
  /// caller can use it both to gate the Save button and to show the banner.
  /// Also null for TRANSFER, mirroring the section's visibility: an invalid
  /// draft must not keep Save disabled after the user switches to a type
  /// that hides the section (the save path drops splits for TRANSFER anyway).
  String? _splitsValidationMessageFor(L l) => splitsValidationMessage(
    l: l,
    type: _type,
    touched: _splitsTouched,
    splits: [
      for (final s in _splits)
        (categoryId: s.categoryId, amount: parseAmountInput(s.amount.text)),
    ],
    mainAmount: parseAmountInput(_amount.text) ?? 0,
  );

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsControllerProvider).value ?? [];
    final categories = ref.watch(categoriesControllerProvider).value ?? [];
    final payees = ref.watch(payeesControllerProvider).value ?? [];
    final amountColor = amountColorFor(context, _type);

    // A one-shot read, not a watch: creating a category or payee posts to
    // the server for the id/record a queued transaction would otherwise
    // have nothing to reference, so the row is withheld whenever the
    // connection was down at open. This dialog is a short-lived modal --
    // reconnecting mid-edit does not need the create row to reappear
    // instantly, and the picker sheet it lives in is re-opened fresh each
    // time anyway.
    final offline =
        ref.watch(apiClientProvider).offlineCache?.stale.value ?? false;

    final fuelMeta = _type == 'EXPENSE' && _categoryId != null
        ? ref.watch(fuelMetaProvider(_categoryId!)).value
        : null;
    _fuelVisible =
        _type == 'EXPENSE' &&
        ((fuelMeta?.isFuel ?? false) ||
            parseFuelTokens(_memo.text).hasFuelData);
    final baseline = fuelBaseline(fuelMeta, _date);

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
                      ? L.of(context).txAddTitle
                      : L.of(context).txEditTitle,
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
                  decoration: InputDecoration(
                    labelText: L.of(context).commonAmount,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return L.of(context).commonRequired;
                    }
                    final normalized = v
                        .replaceAll('.', '')
                        .replaceAll(',', '.');
                    if (double.tryParse(normalized) == null) {
                      return L.of(context).commonInvalidNumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Type selector
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'EXPENSE',
                      label: Text(L.of(context).commonExpense),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    ButtonSegment(
                      value: 'INCOME',
                      label: Text(L.of(context).commonIncome),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: 'TRANSFER',
                      label: Text(L.of(context).commonTransfer),
                      icon: const Icon(Icons.swap_horiz),
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
                    decoration: InputDecoration(
                      labelText: L.of(context).txFromAccount,
                      border: const OutlineInputBorder(),
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
                    decoration: InputDecoration(
                      labelText: L.of(context).txToAccount,
                      border: const OutlineInputBorder(),
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
                PayeePickerField(
                  controller: _payee,
                  payees: payees,
                  onCreate: offline ? null : _createPayee,
                ),
                const SizedBox(height: 12),

                // Category
                Builder(
                  builder: (context) {
                    final ofType = categories
                        .where((c) => _type == 'TRANSFER' || c.type == _type)
                        .toList();
                    return CategoryPickerField(
                      categories: ofType,
                      selectedId: _categoryId,
                      onChanged: (v) => setState(() => _categoryId = v),
                      // A transfer is shown every category and so names no
                      // type; there is nothing to stamp on a new one, so it
                      // offers no create row rather than guessing EXPENSE.
                      // Offline, there is no id the server could hand back
                      // for a queued transaction to reference, so the row
                      // is withheld for the same reason.
                      onCreate: _type == 'TRANSFER' || offline
                          ? null
                          : (typed) => _createCategory(typed, ofType),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Fuel entry (structured tanking fields)
                if (_fuelVisible)
                  FuelEntrySection(
                    odometer: _fuelOdometer,
                    liters: _fuelLiters,
                    fullTank: _fuelFullTank,
                    baseline: baseline,
                    onFieldChanged: () => setState(_syncMemoFromFuelFields),
                    onFullTankChanged: (v) => setState(() {
                      _fuelFullTank = v;
                      _syncMemoFromFuelFields();
                    }),
                  ),

                // Splits (transfers can't be split across categories)
                if (_type != 'TRANSFER')
                  SplitsEditor(
                    splits: _splits,
                    categories: categories
                        .where((c) => c.type == _type)
                        .toList(),
                    validationMessage: _splitsValidationMessageFor(
                      L.of(context),
                    ),
                    onAdd: () => setState(() {
                      _splits.add(SplitDraft());
                      _splitsTouched = true;
                    }),
                    onRemove: (i) => setState(() {
                      _splits.removeAt(i).dispose();
                      _splitsTouched = true;
                    }),
                    onChanged: () => setState(() => _splitsTouched = true),
                  ),

                // Payment method
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: L.of(context).txPaymentMethod,
                    border: const OutlineInputBorder(),
                  ),
                  items: dropdownItemsFor(
                    kPaymentMethods,
                    _paymentMethod,
                    label: (v) => paymentMethodLabel(L.of(context), v),
                  ),
                  onChanged: (v) =>
                      setState(() => _paymentMethod = v ?? 'NONE'),
                ),
                const SizedBox(height: 12),

                // Memo
                TextFormField(
                  controller: _memo,
                  decoration: InputDecoration(
                    labelText: L.of(context).commonMemo,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: _reparseFuelFromMemo,
                ),
                const SizedBox(height: 12),

                // Tags
                TextFormField(
                  controller: _tags,
                  decoration: InputDecoration(
                    labelText: L.of(context).txTagsHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed:
                      _submitting ||
                          _splitsValidationMessageFor(L.of(context)) != null
                      ? null
                      : _save,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(L.of(context).commonSave),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Saves a payee by [name], answering whether it worked.
  ///
  /// The answer is advisory: a transaction stores its payee as a plain
  /// string, so a refused save costs the record -- the default category and
  /// payment method it would have carried -- and not the entry itself.
  Future<bool> _createPayee(String name) => reportingFailure(
    context,
    () => ref.read(payeesControllerProvider.notifier).save(Payee(name: name)),
  );

  /// Makes the category the picker could not find and answers with its id,
  /// or null if the server refused -- which the picker takes as "stay open".
  Future<int?> _createCategory(String typed, List<Category> ofType) async {
    final parsed = parseNewCategoryPath(typed, ofType);
    if (parsed.name.isEmpty) return null;

    Category? created;
    final ok = await reportingFailure(context, () async {
      created = await ref
          .read(categoriesControllerProvider.notifier)
          .save(
            Category(
              name: parsed.name,
              type: _type,
              parentId: parsed.parentId,
            ),
          );
    });
    return ok ? created?.id : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_splitsValidationMessageFor(L.of(context)) != null) return;

    if (_fuelVisible &&
        parseFuelInput(_fuelOdometer.text) == null &&
        parseFuelInput(_fuelLiters.text) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L.of(context).txFuelHint)));
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
                  amount: parseAmountInput(s.amount.text) ?? 0,
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

    // Captured before the pop: this dialog's context is gone afterwards,
    // while the messenger belongs to the Scaffold above it.
    final messenger = ScaffoldMessenger.of(context);
    final l = L.of(context);
    final colors = Theme.of(context).colorScheme;
    try {
      final outcome = await ref
          .read(transactionsControllerProvider(filter: widget.filter).notifier)
          .save(
            transaction,
            splitsTouched: splitsTouched,
            localId: widget.localId,
          );
      // Kill the stale last-odometer hint so the next dialog for this
      // category refetches instead of showing pre-save data.
      if (mounted && _categoryId != null) {
        ref.invalidate(fuelMetaProvider(_categoryId!));
      }
      if (mounted) Navigator.pop(context);
      showSuccessSnack(
        messenger,
        outcome == SaveOutcome.queued ? l.txSavedOnDevice : l.txSaved,
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        showErrorSnack(messenger, colors, e.localizedMessage(l));
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
