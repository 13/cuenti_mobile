import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CashFlowLineChart extends ConsumerWidget {
  const CashFlowLineChart({
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
      return const EmptyState(icon: Icons.show_chart, message: 'No data');
    }

    final netSpots = <FlSpot>[];
    for (var i = 0; i < allMonths.length; i++) {
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
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (barData, indexes) => indexes.map((i) {
            final dotColor = barData.spots[i].y >= 0
                ? cuenti.income
                : cuenti.expense;
            return TouchedSpotIndicatorData(
              FlLine(color: dotColor),
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
            // Tooltip text is painted inside the fl_chart canvas, not a
            // real widget — PrivacyBlur can't wrap it, so keep the
            // '•••••' string substitution here.
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    hidden ? '•••••' : formatNumber(s.y),
                    TextStyle(
                      color: s.y >= 0 ? cuenti.income : cuenti.expense,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: netSpots,
            isCurved: true,
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
