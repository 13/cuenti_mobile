import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/privacy/privacy_mode.dart';
import '../../../core/theme/cuenti_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../utils/number_format.dart';
import '../domain/forecast_data.dart';
import 'forecasts_controller.dart';

class ForecastsScreen extends ConsumerStatefulWidget {
  const ForecastsScreen({super.key});

  @override
  ConsumerState<ForecastsScreen> createState() => _ForecastsScreenState();
}

class _ForecastsScreenState extends ConsumerState<ForecastsScreen> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final forecastProv = forecastProvider(year: _selectedYear);
    final forecastAsync = ref.watch(forecastProv);

    return Column(
      children: [
        _buildYearChips(context),
        const SizedBox(height: 4),
        Expanded(
          child: AsyncValueWidget<ForecastData>(
            value: forecastAsync,
            skeleton: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SkeletonLoader.card(height: 96),
                const SizedBox(height: 24),
                SkeletonLoader.card(height: 250),
                const SizedBox(height: 24),
                SkeletonLoader.card(height: 220),
              ],
            ),
            onRetry: () => ref.invalidate(forecastProv),
            data: (forecast) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(
                  income: forecast.totalIncome,
                  expense: forecast.totalExpense,
                  net: forecast.netForecast,
                  currency: forecast.currency,
                ),
                const SizedBox(height: 24),

                // Monthly Chart
                const SectionHeader('Monthly Forecast'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 250,
                  child: _MonthlyForecastChart(
                    months: forecast.months,
                  ),
                ),
                const SizedBox(height: 24),

                // Breakdown List
                const SectionHeader('Breakdown'),
                const SizedBox(height: 8),
                _BreakdownList(
                  months: forecast.months,
                  currency: forecast.currency,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearChips(BuildContext context) {
    final now = DateTime.now();
    final years = [
      now.year - 1,
      now.year,
      now.year + 1,
      now.year + 2,
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final year in years) ...[
            ChoiceChip(
              label: Text(year.toString()),
              selected: _selectedYear == year,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedYear = year);
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double income, expense, net;
  final String currency;

  const _SummaryCard({
    required this.income,
    required this.expense,
    required this.net,
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
            _metric(context, 'Net', net, net >= 0 ? 'INCOME' : 'EXPENSE'),
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

class _MonthlyForecastChart extends ConsumerWidget {
  final List<MonthForecast> months;

  const _MonthlyForecastChart({required this.months});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(privacyModeProvider);
    if (months.isEmpty) {
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
            // Tooltip text is painted inside the fl_chart canvas, not a
            // real widget — PrivacyBlur can't wrap it, so keep the
            // '•••••' string substitution here.
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Income' : 'Expense';
              return BarTooltipItem(
                '$label\n${hidden ? '•••••' : formatNumber(rod.toY)}',
                TextStyle(color: rod.color, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        barGroups: List.generate(months.length, (i) {
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: months[i].income,
              color: cuenti.income,
              width: 14,
              borderRadius: BorderRadius.circular(6),
            ),
            BarChartRodData(
              toY: months[i].expense,
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
                if (idx >= 0 && idx < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(months[idx].month.substring(5), style: const TextStyle(fontSize: 10)),
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

class _BreakdownList extends StatelessWidget {
  final List<MonthForecast> months;
  final String currency;

  const _BreakdownList({required this.months, required this.currency});

  @override
  Widget build(BuildContext context) {
    final filtered = months.where((m) => m.income != 0 || m.expense != 0 || m.net != 0).toList();
    final fmt = DateFormat('MMM yyyy');

    if (filtered.isEmpty) {
      return const EmptyState(icon: Icons.list, message: 'No data');
    }

    return Column(
      children: filtered.map((month) {
        final date = DateTime.parse('${month.month}-01');
        final label = fmt.format(date);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Income', style: Theme.of(context).textTheme.bodySmall),
                          AmountText(
                            month.income,
                            type: 'INCOME',
                            currency: currency,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Expense', style: Theme.of(context).textTheme.bodySmall),
                          AmountText(
                            month.expense,
                            type: 'EXPENSE',
                            currency: currency,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Net', style: Theme.of(context).textTheme.bodySmall),
                          AmountText(
                            month.net,
                            type: month.net >= 0 ? 'INCOME' : 'EXPENSE',
                            currency: currency,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
