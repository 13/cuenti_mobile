import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/statistics_donut.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/number_format.dart';
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
    final l = L.of(context);
    if (income == 0 && expense == 0) {
      return SizedBox(
        height: 200,
        child: EmptyState(
          icon: Icons.pie_chart_outline,
          message: l.commonNoData,
        ),
      );
    }
    final colors = context.cuentiColors;
    // Slice titles are painted TEXT inside the fl_chart canvas, not real
    // widgets -- PrivacyBlur (an ImageFiltered wrapper) can't reach into
    // the chart painter, so keep the '•••••' string substitution here.
    String figure(double amount) => hidden ? '•••••' : formatNumber(amount);
    return StatisticsDonut(
      height: 180,
      // The figures themselves are read from the summary card above it.
      semanticsLabel: l.a11yChartIncomeExpense,
      slices: [
        DonutSlice(
          value: income,
          label: l.commonIncome,
          color: colors.income,
          title: figure(income),
        ),
        DonutSlice(
          value: expense,
          label: l.commonExpense,
          color: colors.expense,
          title: figure(expense),
        ),
      ],
      centre: (context, index) => _CentreReading(
        label: index == 0 ? l.commonIncome : l.commonExpense,
        // Hidden here too: the slice titles are already masked, and a
        // reading that spelled the figure out would undo that the moment
        // anyone tapped.
        value: figure(index == 0 ? income : expense),
        color: index == 0 ? colors.income : colors.expense,
      ),
    );
  }
}

/// The touched slice's name and figure, shown in the donut's hole.
class _CentreReading extends StatelessWidget {
  const _CentreReading({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A dot carries the identity; the words stay in text ink, the way
        // every other figure in the app is written.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(backgroundColor: color, radius: 4),
            const SizedBox(width: 6),
            Text(label, style: text.labelSmall),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
