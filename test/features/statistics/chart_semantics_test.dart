import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/cash_flow_line_chart.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/income_expense_donut.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/monthly_chart.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// fl_chart paints its labels into a canvas rather than building widgets --
/// PieChart's renderer goes further and drops its children from the
/// semantics tree outright -- so a chart carries no name of its own. To a
/// screen reader the statistics screen was several hundred silent pixels.
/// Each chart names itself now, the way every icon-only button in this app
/// carries a tooltip.
void main() {
  const monthly = {'2026-01': 100.0, '2026-02': 200.0};

  Future<String> labelOf(
    WidgetTester tester,
    Widget child,
    Type chart, {
    Locale locale = const Locale('en'),
  }) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: Scaffold(body: SizedBox(height: 300, child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The container merges any real widgets in the subtree -- the axis
    // labels are Text -- so the chart's own name is a prefix, not the whole
    // string.
    final label = tester.getSemantics(find.byType(chart)).label;
    handle.dispose();
    return label;
  }

  testWidgets('the income/expense donut is announced', (tester) async {
    expect(
      await labelOf(
        tester,
        const IncomeExpenseDonut(income: 100, expense: 40),
        PieChart,
      ),
      startsWith('Income versus expense chart'),
    );
  });

  testWidgets('the monthly bar chart is announced', (tester) async {
    expect(
      await labelOf(
        tester,
        const MonthlyChart(monthlyIncome: monthly, monthlyExpense: monthly),
        BarChart,
      ),
      startsWith('Monthly cash flow chart'),
    );
  });

  testWidgets('the cash flow line chart is announced', (tester) async {
    expect(
      await labelOf(
        tester,
        const CashFlowLineChart(
          monthlyIncome: monthly,
          monthlyExpense: monthly,
        ),
        LineChart,
      ),
      startsWith('Net cash flow chart'),
    );
  });

  testWidgets('the label is translated, not English for everyone', (
    tester,
  ) async {
    expect(
      await labelOf(
        tester,
        const IncomeExpenseDonut(income: 100, expense: 40),
        PieChart,
        locale: const Locale('de'),
      ),
      startsWith('Diagramm: Einnahmen und Ausgaben'),
    );
  });
}
