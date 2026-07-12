import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/cuenti_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../utils/number_format.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/ui/accounts_controller.dart';
import '../domain/statistics_data.dart';
import 'statistics_controller.dart';

enum TimeRange { daily, weekly, monthly, yearly, custom }

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TimeRange _timeRange = TimeRange.yearly;
  int? _selectedAccountId;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  DateTimeRange _computeDateRange() {
    final now = DateTime.now();
    switch (_timeRange) {
      case TimeRange.daily:
        return DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now);
      case TimeRange.weekly:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: DateTime(start.year, start.month, start.day), end: now);
      case TimeRange.monthly:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case TimeRange.yearly:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case TimeRange.custom:
        return _customRange ?? DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _customRange ?? DateTimeRange(
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
    final range = _computeDateRange();
    final fmt = DateFormat('yyyy-MM-dd');
    final start = fmt.format(range.start);
    final end = fmt.format(range.end);
    final statsProvider = statisticsProvider(
        start: start, end: end, accountId: _selectedAccountId);
    final statsAsync = ref.watch(statsProvider);

    return Column(
      children: [
        _buildFilterBar(context, accounts),
        const SizedBox(height: 4),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
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
                _OverviewTab(
                    stats: stats,
                    onRefresh: () {
                      ref.invalidate(statsProvider);
                      return ref.read(statsProvider.future);
                    }),
                _CategoryTab(data: stats.incomeByCategory, title: 'Income by Category', currency: stats.currency, type: 'INCOME'),
                _CategoryTab(data: stats.expenseByCategory, title: 'Expense by Category', currency: stats.currency, type: 'EXPENSE'),
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
    final label = r == TimeRange.custom
        ? 'Custom'
        : r.name[0].toUpperCase() + r.name.substring(1);
    return ChoiceChip(
      label: Text(label),
      selected: _timeRange == r,
      onSelected: (selected) {
        if (r == TimeRange.custom) {
          _pickCustomRange();
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
      label: Text(selected?.accountName ?? 'All Accounts'),
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
      BuildContext context, List<Account> accounts) async {
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
                child: Text('Account', style: Theme.of(ctx).textTheme.titleMedium),
              ),
            ),
            ListTile(
              title: const Text('All Accounts'),
              onTap: () => Navigator.pop(ctx, null),
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

class _OverviewTab extends StatelessWidget {
  final StatisticsData stats;
  final Future<void> Function() onRefresh;
  const _OverviewTab({required this.stats, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            income: stats.totalIncome,
            expense: stats.totalExpense,
            balance: stats.balance,
            currency: stats.currency,
          ),
          const SizedBox(height: 24),

          // Income vs Expense Donut
          const SectionHeader('Income vs Expense'),
          const SizedBox(height: 8),
          _IncomeExpenseDonut(income: stats.totalIncome, expense: stats.totalExpense),
          const SizedBox(height: 24),

          // Net Cash Flow Line Chart
          const SectionHeader('Net Cash Flow Trend'),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _CashFlowLineChart(
              monthlyIncome: stats.monthlyIncome,
              monthlyExpense: stats.monthlyExpense,
            ),
          ),
          const SizedBox(height: 24),

          const SectionHeader('Monthly Cash Flow'),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: _MonthlyChart(
              monthlyIncome: stats.monthlyIncome,
              monthlyExpense: stats.monthlyExpense,
            ),
          ),
          const SizedBox(height: 16),
          Text('${stats.transactionCount} transactions in period',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _IncomeExpenseDonut extends StatelessWidget {
  final double income, expense;
  const _IncomeExpenseDonut({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    if (income == 0 && expense == 0) {
      return const SizedBox(
        height: 200,
        child: EmptyState(icon: Icons.pie_chart_outline, message: 'No data'),
      );
    }
    final colors = context.cuentiColors;
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  value: income,
                  title: formatNumber(income),
                  color: colors.income,
                  radius: 40,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  value: expense,
                  title: formatNumber(expense),
                  color: colors.expense,
                  radius: 40,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _legendChip('Income', colors.income),
            _legendChip('Expense', colors.expense),
          ],
        ),
      ],
    );
  }

  Widget _legendChip(String label, Color color) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 6),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _CashFlowLineChart extends StatelessWidget {
  final Map<String, double> monthlyIncome;
  final Map<String, double> monthlyExpense;
  const _CashFlowLineChart({required this.monthlyIncome, required this.monthlyExpense});

  @override
  Widget build(BuildContext context) {
    final allMonths = {...monthlyIncome.keys, ...monthlyExpense.keys}.toList()..sort();
    if (allMonths.isEmpty) {
      return const EmptyState(icon: Icons.show_chart, message: 'No data');
    }

    final netSpots = <FlSpot>[];
    for (int i = 0; i < allMonths.length; i++) {
      final m = allMonths[i];
      final net = (monthlyIncome[m] ?? 0) - (monthlyExpense[m] ?? 0);
      netSpots.add(FlSpot(i.toDouble(), net));
    }

    final cuenti = context.cuentiColors;
    final colorScheme = Theme.of(context).colorScheme;
    final lineColor = cuenti.chartPalette.first;
    final gridColor = colorScheme.outlineVariant.withValues(alpha: 0.5);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: gridColor,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < allMonths.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(allMonths[idx].substring(5), style: const TextStyle(fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (barData, indexes) => indexes.map((i) {
            final dotColor = barData.spots[i].y >= 0 ? cuenti.income : cuenti.expense;
            return TouchedSpotIndicatorData(
              FlLine(color: dotColor, strokeWidth: 2),
              FlDotData(
                getDotPainter: (spot, percent, bar, idx) => FlDotCirclePainter(
                  radius: 4,
                  color: dotColor,
                  strokeWidth: 2,
                  strokeColor: colorScheme.surface,
                ),
              ),
            );
          }).toList(),
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colorScheme.surfaceContainerHighest,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              formatNumber(s.y),
              TextStyle(color: s.y >= 0 ? cuenti.income : cuenti.expense, fontWeight: FontWeight.bold),
            )).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: netSpots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.35),
                  lineColor.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double income, expense, balance;
  final String currency;

  const _SummaryCard({
    required this.income,
    required this.expense,
    required this.balance,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _metric(context, 'Income', income, 'INCOME'),
            _metric(context, 'Expense', expense, 'EXPENSE'),
            _metric(context, 'Balance', balance, balance >= 0 ? 'INCOME' : 'EXPENSE'),
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String label, double value, String type) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        AmountText(
          value,
          type: type,
          currency: currency,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final Map<String, double> monthlyIncome;
  final Map<String, double> monthlyExpense;

  const _MonthlyChart({required this.monthlyIncome, required this.monthlyExpense});

  @override
  Widget build(BuildContext context) {
    final allMonths = {...monthlyIncome.keys, ...monthlyExpense.keys}.toList()..sort();
    if (allMonths.isEmpty) {
      return const EmptyState(icon: Icons.bar_chart, message: 'No data');
    }

    final cuenti = context.cuentiColors;
    final colorScheme = Theme.of(context).colorScheme;
    final gridColor = colorScheme.outlineVariant.withValues(alpha: 0.5);

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => colorScheme.surfaceContainerHighest,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Income' : 'Expense';
              return BarTooltipItem(
                '$label\n${formatNumber(rod.toY)}',
                TextStyle(color: rod.color, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        barGroups: List.generate(allMonths.length, (i) {
          final month = allMonths[i];
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: monthlyIncome[month] ?? 0,
              color: cuenti.income,
              width: 14,
              borderRadius: BorderRadius.circular(6),
            ),
            BarChartRodData(
              toY: monthlyExpense[month] ?? 0,
              color: cuenti.expense,
              width: 14,
              borderRadius: BorderRadius.circular(6),
            ),
          ]);
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < allMonths.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(allMonths[idx].substring(5), style: const TextStyle(fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final Map<String, double> data;
  final String title;
  final String currency;
  final String type;

  const _CategoryTab({
    required this.data,
    required this.title,
    required this.currency,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<double>(0, (sum, e) => sum + e.value);
    final palette = context.cuentiColors.chartPalette;
    final colors = List.generate(sorted.length, (i) => palette[i % palette.length]);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(title),
        Row(
          children: [
            Text('Total: ', style: Theme.of(context).textTheme.bodySmall),
            AmountText(
              total,
              type: type,
              currency: currency,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Pie chart for categories
        if (sorted.isNotEmpty) ...[
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(sorted.length, (i) {
                  final pct = total > 0 ? (sorted[i].value / total * 100) : 0.0;
                  return PieChartSectionData(
                    value: sorted[i].value,
                    title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                    color: colors[i],
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(sorted.length, (i) {
              return Chip(
                avatar: CircleAvatar(backgroundColor: colors[i], radius: 6),
                label: Text(sorted[i].key, style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }),
          ),
          const SizedBox(height: 16),
        ] else
          const EmptyState(icon: Icons.pie_chart_outline, message: 'No data'),

        ...sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final pct = total > 0 ? (e.value / total * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Text(e.key, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Text('${formatNumber(e.value)} $currency (${pct.toStringAsFixed(1)}%)'),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: total > 0 ? e.value / total : 0,
                  color: colors[i],
                  backgroundColor: colors[i].withValues(alpha: 0.12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
