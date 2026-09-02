import 'dart:async';

import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_controller.dart';
import 'package:cuentimobile/features/statistics/domain/statistics_data.dart';
import 'package:cuentimobile/features/statistics/domain/time_range.dart';
import 'package:cuentimobile/features/statistics/ui/statistics_controller.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/category_tab.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/overview_tab.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TimeRange _timeRange = TimeRange.yearly;
  int? _selectedAccountId;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange:
          _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _timeRange = TimeRange.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsControllerProvider).value ?? [];
    // statisticsRange lives in the domain and is tested there; this screen
    // used to carry a second copy of the same switch, so the ranges every
    // user actually got were the untested ones.
    final range = statisticsRange(
      _timeRange,
      now: DateTime.now(),
      custom: _customRange,
    );
    final fmt = DateFormat('yyyy-MM-dd');
    final start = fmt.format(range.start);
    final end = fmt.format(range.end);
    final statsProvider = statisticsProvider(
      start: start,
      end: end,
      accountId: _selectedAccountId,
    );
    final statsAsync = ref.watch(statsProvider);

    return Column(
      children: [
        _buildFilterBar(context, accounts),
        const SizedBox(height: 4),
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: L.of(context).statsOverview),
            Tab(text: L.of(context).commonIncome),
            Tab(text: L.of(context).commonExpense),
          ],
        ),
        Expanded(
          child: AsyncValueWidget<StatisticsData>(
            value: statsAsync,
            skeleton: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SkeletonLoader.card(height: 96),
                const SizedBox(height: 24),
                SkeletonLoader.card(height: 200),
                const SizedBox(height: 24),
                SkeletonLoader.card(height: 250),
              ],
            ),
            onRetry: () => ref.invalidate(statsProvider),
            data: (stats) => TabBarView(
              controller: _tabController,
              children: [
                OverviewTab(
                  stats: stats,
                  onRefresh: () {
                    ref.invalidate(statsProvider);
                    return ref.read(statsProvider.future);
                  },
                ),
                CategoryTab(
                  data: stats.incomeByCategory,
                  title: L.of(context).statsIncomeByCategory,
                  currency: stats.currency,
                  type: 'INCOME',
                ),
                CategoryTab(
                  data: stats.expenseByCategory,
                  title: L.of(context).statsExpenseByCategory,
                  currency: stats.currency,
                  type: 'EXPENSE',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, List<Account> accounts) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final r in TimeRange.values) ...[
            _rangeChip(context, r),
            const SizedBox(width: 8),
          ],
          _accountChip(context, accounts),
        ],
      ),
    );
  }

  Widget _rangeChip(BuildContext context, TimeRange r) {
    return ChoiceChip(
      label: Text(timeRangeLabel(L.of(context), r)),
      selected: _timeRange == r,
      onSelected: (selected) {
        if (r == TimeRange.custom) {
          unawaited(_pickCustomRange());
        } else if (selected) {
          setState(() => _timeRange = r);
        }
      },
    );
  }

  Widget _accountChip(BuildContext context, List<Account> accounts) {
    final selected = _accountById(accounts, _selectedAccountId);
    return InputChip(
      avatar: const Icon(Icons.account_balance_wallet_outlined, size: 18),
      label: Text(selected?.accountName ?? L.of(context).statsAllAccounts),
      onPressed: () => _openAccountSheet(context, accounts),
      onDeleted: selected != null
          ? () => setState(() => _selectedAccountId = null)
          : null,
    );
  }

  Account? _accountById(List<Account> accounts, int? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> _openAccountSheet(
    BuildContext context,
    List<Account> accounts,
  ) async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  L.of(context).commonAccount,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
            ),
            ListTile(
              title: Text(L.of(context).statsAllAccounts),
              onTap: () => Navigator.pop(ctx),
            ),
            for (final a in accounts)
              ListTile(
                title: Text(a.accountName),
                onTap: () => Navigator.pop(ctx, a.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _selectedAccountId = selected);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
