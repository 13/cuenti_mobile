import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/data_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await context.read<DataProvider>().loadStatistics();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final stats = dp.statistics;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (stats == null) return const Center(child: Text('No data'));

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
          ],
        ),
        Expanded(
          child: TabBarView(
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
        Text('${value.toStringAsFixed(2)}',
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
        barGroups: List.generate(allMonths.length, (i) {
          final month = allMonths[i];
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: monthlyIncome[month] ?? 0,
              color: Colors.green,
              width: 8,
            ),
            BarChartRodData(
              toY: monthlyExpense[month] ?? 0,
              color: Colors.red,
              width: 8,
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

  @override
  Widget build(BuildContext context) {
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<double>(0, (sum, e) => sum + e.value);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Text('Total: ${total.toStringAsFixed(2)} $currency',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        ...sorted.map((e) {
          final pct = total > 0 ? (e.value / total * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(e.key, overflow: TextOverflow.ellipsis)),
                    Text('${e.value.toStringAsFixed(2)} $currency (${pct.toStringAsFixed(1)}%)'),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: total > 0 ? e.value / total : 0,
                  color: color,
                  backgroundColor: color.withAlpha(30),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
