import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/data_provider.dart';
import '../../utils/number_format.dart';

enum TimeRange { daily, weekly, monthly, yearly, custom }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  late TabController _tabController;
  TimeRange _timeRange = TimeRange.monthly;
  int? _selectedAccountId;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final range = _computeDateRange();
      final fmt = DateFormat('yyyy-MM-dd');
      await context.read<DataProvider>().loadStatistics(
        start: fmt.format(range.start),
        end: fmt.format(range.end),
        accountId: _selectedAccountId,
      );
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
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
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final stats = dp.statistics;

    return Column(
      children: [
        // Time range selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: TimeRange.values.map((range) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(range == TimeRange.custom
                      ? 'Custom'
                      : range.name[0].toUpperCase() + range.name.substring(1)),
                  selected: _timeRange == range,
                  onSelected: (selected) {
                    if (range == TimeRange.custom) {
                      _pickCustomRange();
                    } else if (selected) {
                      setState(() => _timeRange = range);
                      _load();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        // Account filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : stats == null
                  ? const Center(child: Text('No data'))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _OverviewTab(stats: stats),
                        _CategoryTab(data: stats.incomeByCategory, title: 'Income by Category', currency: stats.currency, color: Colors.green),
                        _CategoryTab(data: stats.expenseByCategory, title: 'Expense by Category', currency: stats.currency, color: Colors.red),
                      ],
                    ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _OverviewTab extends StatelessWidget {
  final StatisticsData stats;
  const _OverviewTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DataProvider>().loadStatistics(),
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
          Text('Income vs Expense', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _IncomeExpenseDonut(income: stats.totalIncome, expense: stats.totalExpense),
          ),
          const SizedBox(height: 24),

          // Net Cash Flow Line Chart
          Text('Net Cash Flow Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _CashFlowLineChart(
              monthlyIncome: stats.monthlyIncome,
              monthlyExpense: stats.monthlyExpense,
            ),
          ),
          const SizedBox(height: 24),

          Text('Monthly Cash Flow', style: Theme.of(context).textTheme.titleMedium),
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
    if (income == 0 && expense == 0) return const Center(child: Text('No data'));
    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 50,
        sections: [
          PieChartSectionData(
            value: income,
            title: formatNumber(income),
            color: Colors.green,
            radius: 40,
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: expense,
            title: formatNumber(expense),
            color: Colors.red,
            radius: 40,
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
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
    if (allMonths.isEmpty) return const Center(child: Text('No data'));

    final netSpots = <FlSpot>[];
    for (int i = 0; i < allMonths.length; i++) {
      final m = allMonths[i];
      final net = (monthlyIncome[m] ?? 0) - (monthlyExpense[m] ?? 0);
      netSpots.add(FlSpot(i.toDouble(), net));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Theme.of(context).dividerColor.withAlpha(60),
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
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              formatNumber(s.y),
              TextStyle(color: s.y >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            )).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: netSpots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 4,
                color: spot.y >= 0 ? Colors.green : Colors.red,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withAlpha(30),
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
            _metric(context, 'Income', income, Colors.green),
            _metric(context, 'Expense', expense, Colors.red),
            _metric(context, 'Balance', balance, balance >= 0 ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(formatNumber(value),
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(currency, style: Theme.of(context).textTheme.bodySmall),
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
    if (allMonths.isEmpty) return const Center(child: Text('No data'));

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
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
              gradient: const LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 10,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: monthlyExpense[month] ?? 0,
              gradient: const LinearGradient(
                colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 10,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
        gridData: const FlGridData(show: false),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final Map<String, double> data;
  final String title;
  final String currency;
  final Color color;

  const _CategoryTab({
    required this.data,
    required this.title,
    required this.currency,
    required this.color,
  });

  List<Color> _generateColors(int count) {
    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      colors.add(HSLColor.fromAHSL(1.0, (i * 360 / max(count, 1)) % 360, 0.65, 0.55).toColor());
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<double>(0, (sum, e) => sum + e.value);
    final colors = _generateColors(sorted.length);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Text('Total: ${formatNumber(total)} $currency',
            style: Theme.of(context).textTheme.bodySmall),
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
            spacing: 12,
            runSpacing: 6,
            children: List.generate(sorted.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  Text(sorted[i].key, style: const TextStyle(fontSize: 12)),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
        ],

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
                  backgroundColor: colors[i].withAlpha(30),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
