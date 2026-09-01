import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncomeExpenseDonut extends ConsumerWidget {
  const IncomeExpenseDonut({
    required this.income,
    required this.expense,
    super.key,
  });
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(privacyModeProvider);
    if (income == 0 && expense == 0) {
      return SizedBox(
        height: 200,
        child: EmptyState(
          icon: Icons.pie_chart_outline,
          message: L.of(context).commonNoData,
        ),
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
              // Slice titles are painted TEXT inside the fl_chart canvas,
              // not real widgets — PrivacyBlur (an ImageFiltered wrapper)
              // can't reach into the chart painter, so keep the '•••••'
              // string substitution here.
              sections: [
                PieChartSectionData(
                  value: income,
                  title: hidden ? '•••••' : formatNumber(income),
                  color: colors.income,
                  radius: 40,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: expense,
                  title: hidden ? '•••••' : formatNumber(expense),
                  color: colors.expense,
                  radius: 40,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
