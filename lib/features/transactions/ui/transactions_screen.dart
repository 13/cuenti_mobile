import 'dart:async';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_controller.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/categories_controller.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:cuentimobile/features/saved_views/ui/saved_views_sheet.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/ui/transaction_dialog.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:cuentimobile/features/transactions/ui/widgets/transaction_list_parts.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  TransactionFilter _filter = TransactionsController.defaultFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadMore() => reportingFailure(
    context,
    () => ref
        .read(transactionsControllerProvider(filter: _filter).notifier)
        .loadMore(),
  );

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(
        () => _filter = _filter.copyWith(search: value.isEmpty ? null : value),
      );
    });
  }

  void _resetFilters() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _filter = TransactionsController.defaultFilter);
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(
      transactionsControllerProvider(filter: _filter),
    );
    final accounts = ref.watch(accountsControllerProvider).value ?? [];
    final categories = ref.watch(categoriesControllerProvider).value ?? [];

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: L.of(context).txSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 4),
          _buildFilterChips(context, accounts, categories),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                ref.invalidate(transactionsControllerProvider(filter: _filter));
                return ref.read(
                  transactionsControllerProvider(filter: _filter).future,
                );
              },
              child: AsyncValueWidget<TransactionsState>(
                value: transactionsAsync,
                data: (state) {
                  if (state.items.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        if (_filter == TransactionsController.defaultFilter)
                          EmptyState(
                            icon: Icons.receipt_long,
                            message: L.of(context).txEmpty,
                            actionLabel: L.of(context).txAdd,
                            onAction: () => _showAddDialog(context),
                          )
                        else
                          EmptyState(
                            icon: Icons.receipt_long,
                            message: L.of(context).txNoMatch,
                            actionLabel: L.of(context).commonClearFilters,
                            onAction: _resetFilters,
                          ),
                      ],
                    );
                  }
                  return _buildList(context, state);
                },
                onRetry: () => ref.invalidate(
                  transactionsControllerProvider(filter: _filter),
                ),
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

  Widget _buildList(BuildContext context, TransactionsState state) {
    final groups = _groupByDay(state.items);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        for (final (groupIndex, group) in groups.indexed)
          SliverMainAxisGroup(
            // Index-suffixed: even if a pathological backend hands us the
            // same day twice (or duplicate ids slip past dedupe), sliver
            // keys stay unique so the framework never throws "Duplicate
            // keys found".
            key: ValueKey('${group.dayKey}-$groupIndex'),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: DayHeaderDelegate(label: group.label),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final (t, index) = group.entries[i];
                    return Staggered(
                      key: ValueKey('stagger-${t.id}'),
                      index: index,
                      child: TransactionTile(
                        transaction: t,
                        filter: _filter,
                        onDelete: _delete,
                      ),
                    );
                  },
                  childCount: group.entries.length,
                ),
              ),
            ],
          ),
        if (state.loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<DayGroup> _groupByDay(List<Transaction> items) {
    final groups = <DayGroup>[];
    String? lastKey;
    var index = 0;
    for (final t in items) {
      final d = t.transactionDate;
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (key != lastKey) {
        groups.add(DayGroup(key, _dayLabel(d), []));
        lastKey = key;
      }
      groups.last.entries.add((t, index));
      index++;
    }
    return groups;
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return L.of(context).commonToday;
    if (d == today.subtract(const Duration(days: 1))) {
      return L.of(context).commonYesterday;
    }
    return DateFormat('EEE, d MMM yyyy').format(d);
  }

  Widget _buildFilterChips(
    BuildContext context,
    List<Account> accounts,
    List<Category> categories,
  ) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _typeChip(context),
          const SizedBox(width: 8),
          _categoryChip(context, categories),
          const SizedBox(width: 8),
          _dateRangeChip(context),
          const SizedBox(width: 8),
          _accountChip(context, accounts),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: L.of(context).savedViewsTitle,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () => showSavedViewsSheet(
              context,
              ref,
              current: _filter,
              onApply: (f) => setState(() => _filter = f),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
    'EXPENSE' => 'Expense',
    'INCOME' => 'Income',
    'TRANSFER' => 'Transfer',
    _ => type,
  };

  Widget _typeChip(BuildContext context) {
    final active = _filter.type != null;
    return InputChip(
      avatar: const Icon(Icons.category_outlined, size: 18),
      label: Text(
        active ? _typeLabel(_filter.type!) : L.of(context).commonType,
      ),
      onPressed: () => _openOptionsSheet<String>(
        context,
        title: L.of(context).txTypeFilter,
        options: [
          _ChipOption(L.of(context).commonAll, null),
          _ChipOption(L.of(context).commonExpense, 'EXPENSE'),
          _ChipOption(L.of(context).commonIncome, 'INCOME'),
          _ChipOption(L.of(context).commonTransfer, 'TRANSFER'),
        ],
        onSelected: (v) => setState(() => _filter = _filter.copyWith(type: v)),
      ),
      onDeleted: active
          ? () => setState(() => _filter = _filter.copyWith(type: null))
          : null,
    );
  }

  Widget _categoryChip(BuildContext context, List<Category> categories) {
    final active = _categoryById(categories, _filter.categoryId);
    return InputChip(
      avatar: const Icon(Icons.label_outline, size: 18),
      label: Text(
        active != null
            ? (active.fullName ?? active.name)
            : L.of(context).categoryLabel,
      ),
      // The searchable sheet rather than the generic option list: the
      // category list is the one filter long enough to need typing.
      onPressed: () => unawaited(_pickCategory(context, categories)),
      onDeleted: active != null
          ? () => setState(() => _filter = _filter.copyWith(categoryId: null))
          : null,
    );
  }

  Future<void> _pickCategory(
    BuildContext context,
    List<Category> categories,
  ) async {
    final choice = await showCategorySearchSheet(
      context,
      categories: categories,
      selectedId: _filter.categoryId,
      noneLabel: 'All',
    );
    if (choice == null || !mounted) return;
    setState(
      () => _filter = _filter.copyWith(categoryId: choice.categoryId),
    );
  }

  Widget _dateRangeChip(BuildContext context) {
    final active = _filter.start != null || _filter.end != null;
    final label = active
        ? '${_shortDate(_filter.start)} – ${_shortDate(_filter.end)}'
        : L.of(context).commonDateRange;
    return InputChip(
      avatar: const Icon(Icons.date_range_outlined, size: 18),
      label: Text(label),
      onPressed: () => _pickDateRange(context),
      onDeleted: active
          ? () => setState(
              () => _filter = _filter.copyWith(start: null, end: null),
            )
          : null,
    );
  }

  String _shortDate(DateTime? d) =>
      d == null ? '…' : DateFormat('d MMM').format(d);

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _filter.start != null && _filter.end != null
          ? DateTimeRange(start: _filter.start!, end: _filter.end!)
          : null,
    );
    if (picked != null && mounted) {
      setState(
        () => _filter = _filter.copyWith(start: picked.start, end: picked.end),
      );
    }
  }

  Widget _accountChip(BuildContext context, List<Account> accounts) {
    final active = _accountById(accounts, _filter.accountId);
    return InputChip(
      avatar: const Icon(Icons.account_balance_wallet_outlined, size: 18),
      label: Text(active?.accountName ?? L.of(context).commonAccount),
      onPressed: () => _openOptionsSheet<int>(
        context,
        title: L.of(context).commonAccount,
        options: [
          _ChipOption(L.of(context).txAllAccounts, null),
          for (final a in accounts) _ChipOption(a.accountName, a.id),
        ],
        onSelected: (v) =>
            setState(() => _filter = _filter.copyWith(accountId: v)),
      ),
      onDeleted: active != null
          ? () => setState(() => _filter = _filter.copyWith(accountId: null))
          : null,
    );
  }

  Category? _categoryById(List<Category> categories, int? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Account? _accountById(List<Account> accounts, int? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> _openOptionsSheet<T>(
    BuildContext context, {
    required String title,
    required List<_ChipOption<T>> options,
    required void Function(T? value) onSelected,
  }) async {
    final selected = await showModalBottomSheet<_ChipOption<T>>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
              ),
            ),
            for (final o in options)
              ListTile(
                title: Text(o.label),
                onTap: () => Navigator.pop(ctx, o),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) onSelected(selected.value);
  }

  Future<void> _delete(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = L.of(context);
    final colors = Theme.of(context).colorScheme;
    try {
      await ref
          .read(transactionsControllerProvider(filter: _filter).notifier)
          .delete(id);
      showSuccessSnack(messenger, l.txDeleted);
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(messenger, colors, e.localizedMessage(l));
    }
  }

  void _showAddDialog(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => TransactionDialog(filter: _filter),
      ),
    );
  }
}

class _ChipOption<T> {
  const _ChipOption(this.label, this.value);
  final String label;
  final T? value;
}
