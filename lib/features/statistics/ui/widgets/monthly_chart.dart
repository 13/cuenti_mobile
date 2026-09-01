import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonthlyChart extends ConsumerWidget {
  const MonthlyChart({
    required this.monthlyIncome,
    required this.monthlyExpense,
    super.key,
  });
  final Map<String, double> monthlyIncome;
  final Map<String, double> monthlyExpense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(privacyModeProvider);
    final allMonths = {...monthlyIncome.keys, ...monthlyExpense.keys}.toList()
      ..sort();
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
            // Tooltip text is painted inside the fl_chart canvas, not a
            // real widget — PrivacyBlur can't wrap it, so keep the
            // '•••••' string substitution here.
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Income' : 'Expense';
              return BarTooltipItem(
                '$label\n${hidden ? '•••••' : formatNumber(rod.toY)}',
                TextStyle(
                  color: rod.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(allMonths.length, (i) {
          final month = allMonths[i];
          return BarChartGroupData(
            x: i,
            barRods: [
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
            ],
          );
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
                    child: Text(
                      allMonths[idx].substring(5),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
      ),
    );
  }
}
