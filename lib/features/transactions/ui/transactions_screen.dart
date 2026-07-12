import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/cuenti_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/ui/accounts_controller.dart';
import '../../categories/domain/category.dart';
import '../../categories/ui/categories_controller.dart';
import '../domain/transaction.dart';
import '../domain/transaction_filter.dart';
import 'transaction_dialog.dart';
import 'transactions_controller.dart';

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
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    try {
      await ref
          .read(transactionsControllerProvider(filter: _filter).notifier)
          .loadMore();
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
              decoration: const InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
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
                        EmptyState(
                          icon: Icons.receipt_long,
                          message: 'No transactions match',
                          actionLabel: 'Clear filters',
                          onAction: _resetFilters,
                        ),
                      ],
                    );
                  }
                  return _buildList(context, state);
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

  Widget _buildList(BuildContext context, TransactionsState state) {
    final groups = _groupByDay(state.items);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        for (final group in groups)
          SliverMainAxisGroup(
            key: ValueKey(group.dayKey),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _DayHeaderDelegate(label: group.label),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final (t, index) = group.entries[i];
                    return _Staggered(
                      key: ValueKey('stagger-${t.id}'),
                      index: index,
                      child: _TransactionTile(
                        transaction: t,
                        accountId: _filter.accountId,
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

  List<_DayGroup> _groupByDay(List<Transaction> items) {
    final groups = <_DayGroup>[];
    String? lastKey;
    var index = 0;
    for (final t in items) {
      final d = t.transactionDate;
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (key != lastKey) {
        groups.add(_DayGroup(key, _dayLabel(d), []));
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
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
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
      label: Text(active ? _typeLabel(_filter.type!) : 'Type'),
      onPressed: () => _openOptionsSheet<String>(
        context,
        title: 'Transaction type',
        options: const [
          _ChipOption('All', null),
          _ChipOption('Expense', 'EXPENSE'),
          _ChipOption('Income', 'INCOME'),
          _ChipOption('Transfer', 'TRANSFER'),
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
        active != null ? (active.fullName ?? active.name) : 'Category',
      ),
      onPressed: () => _openOptionsSheet<int>(
        context,
        title: 'Category',
        options: [
          const _ChipOption('All', null),
          for (final c in categories) _ChipOption(c.fullName ?? c.name, c.id),
        ],
        onSelected: (v) =>
            setState(() => _filter = _filter.copyWith(categoryId: v)),
      ),
      onDeleted: active != null
          ? () => setState(() => _filter = _filter.copyWith(categoryId: null))
          : null,
    );
  }

  Widget _dateRangeChip(BuildContext context) {
    final active = _filter.start != null || _filter.end != null;
    final label = active
        ? '${_shortDate(_filter.start)} – ${_shortDate(_filter.end)}'
        : 'Date range';
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
      label: Text(active?.accountName ?? 'Account'),
      onPressed: () => _openOptionsSheet<int>(
        context,
        title: 'Account',
        options: [
          const _ChipOption('All accounts', null),
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
    try {
      await ref
          .read(transactionsControllerProvider(filter: _filter).notifier)
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
      builder: (_) => TransactionDialog(accountId: _filter.accountId),
    );
  }
}

class _ChipOption<T> {
  const _ChipOption(this.label, this.value);
  final String label;
  final T? value;
}

class _DayGroup {
  _DayGroup(this.dayKey, this.label, this.entries);
  final String dayKey;
  final String label;
  final List<(Transaction, int)> entries;
}

class _DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _DayHeaderDelegate({required this.label});
  final String label;

  static const double _height = 36;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: _height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.surfaceContainerHighest,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DayHeaderDelegate oldDelegate) =>
      oldDelegate.label != label;
}

/// One-shot entrance animation for a list tile: fades and slides in on
/// first build only (per-[State] lifetime), capped at [index] 12 so a long
/// list doesn't produce an ever-growing delay. Skipped entirely when the
/// platform/test requests reduced motion.
class _Staggered extends StatefulWidget {
  const _Staggered({required this.child, required this.index, super.key});
  final Widget child;
  final int index;

  @override
  State<_Staggered> createState() => _StaggeredState();
}

class _StaggeredState extends State<_Staggered> {
  bool _visible = false;
  bool _animate = true;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visible || _scheduled) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _animate = false;
      _visible = true;
      return;
    }
    _scheduled = true;
    final cappedIndex = widget.index > 12 ? 12 : widget.index;
    Future.delayed(Duration(milliseconds: cappedIndex * 35), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_animate) return widget.child;
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.accountId,
    required this.onDelete,
  });

  final Transaction transaction;
  final int? accountId;
  final void Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    final color = amountColorFor(context, transaction.type);
    final icon = switch (transaction.type) {
      'EXPENSE' => Icons.arrow_downward,
      'INCOME' => Icons.arrow_upward,
      _ => Icons.swap_horiz,
    };

    final accountName = switch (transaction.type) {
      'EXPENSE' => transaction.fromAccountName,
      'INCOME' => transaction.toAccountName,
      _ =>
        transaction.fromAccountName != null && transaction.toAccountName != null
            ? '${transaction.fromAccountName} → ${transaction.toAccountName}'
            : null,
    };

    final title = (transaction.payee?.isNotEmpty ?? false)
        ? transaction.payee!
        : (transaction.categoryName ?? transaction.memo ?? transaction.type);

    final subtitleParts = [
      if (transaction.memo != null && transaction.memo!.isNotEmpty)
        transaction.memo!,
      if (accountName != null && accountName.isNotEmpty) accountName,
    ];

    final colorScheme = Theme.of(context).colorScheme;
    final editColor = context.cuentiColors.transfer;

    return Dismissible(
      key: ValueKey(transaction.id),
      background: Container(
        color: editColor.withAlpha(31),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.edit, color: editColor),
            const SizedBox(width: 8),
            Text('Edit', style: TextStyle(color: editColor)),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete, color: colorScheme.onErrorContainer),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final confirmed = await showConfirmSheet(
            context,
            title: 'Delete transaction?',
            message: 'This action cannot be undone.',
          );
          if (confirmed && transaction.id != null) {
            onDelete(transaction.id!);
          }
          return confirmed;
        }
        unawaited(
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => TransactionDialog(
              transaction: transaction,
              accountId: accountId,
            ),
          ),
        );
        return false;
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(31),
          child: Icon(icon, color: color),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitleParts.isNotEmpty
            ? Text(
                subtitleParts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: AmountText(
          transaction.amount,
          type: transaction.type,
          signed: true,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => TransactionDialog(
              transaction: transaction,
              accountId: accountId,
            ),
          );
        },
      ),
    );
  }
}
