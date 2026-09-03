import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncomeExpenseDonut extends ConsumerStatefulWidget {
  const IncomeExpenseDonut({
    required this.income,
    required this.expense,
    super.key,
  });
  final double income;
  final double expense;

  @override
  ConsumerState<IncomeExpenseDonut> createState() => _IncomeExpenseDonutState();
}

class _IncomeExpenseDonutState extends ConsumerState<IncomeExpenseDonut> {
  /// The slice whose figure is showing in the middle, or null for none.
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final income = widget.income;
    final expense = widget.expense;
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
          // The slice titles are painted into a canvas, so without this the
          // chart is silent to a screen reader. The figures themselves are
          // read from the summary card above it.
          child: Semantics(
            label: L.of(context).a11yChartIncomeExpense,
            container: true,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                    pieTouchData: PieTouchData(
                      // FlTapUpEvent, as the category chart already learned the
                      // hard way: isInterestedForInteractions admits the down
                      // events and excludes the up ones, so gating on it fires
                      // twice per tap and reacts before a finger has lifted.
                      touchCallback: (event, response) {
                        if (event is! FlTapUpEvent) return;
                        final index =
                            response?.touchedSection?.touchedSectionIndex;
                        if (index == null || index < 0 || index > 1) return;
                        // Tapping the showing slice puts the middle back, so a
                        // reading can be dismissed without hunting for a gap.
                        setState(
                          () => _touched = _touched == index ? null : index,
                        );
                      },
                    ),
                    // Slice titles are painted TEXT inside the fl_chart canvas,
                    // not real widgets — PrivacyBlur (an ImageFiltered wrapper)
                    // can't reach into the chart painter, so keep the '•••••'
                    // string substitution here.
                    sections: [
                      PieChartSectionData(
                        value: income,
                        title: hidden ? '•••••' : formatNumber(income),
                        color: colors.income,
                        radius: _touched == 0 ? 48 : 40,
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
                        radius: _touched == 1 ? 48 : 40,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // A pie has no tooltip layer in fl_chart, and the hole in
                // the middle is the one place a reading can sit without
                // covering the thing it describes.
                if (_touched != null)
                  _CentreReading(
                    label: _touched == 0
                        ? L.of(context).commonIncome
                        : L.of(context).commonExpense,
                    // Hidden here too: the slice titles are already masked,
                    // and a reading that spelled the figure out would undo
                    // that the moment anyone tapped.
                    value: hidden
                        ? '•••••'
                        : formatNumber(_touched == 0 ? income : expense),
                    color: _touched == 0 ? colors.income : colors.expense,
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
            _legendChip(L.of(context).commonIncome, colors.income),
            _legendChip(L.of(context).commonExpense, colors.expense),
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
