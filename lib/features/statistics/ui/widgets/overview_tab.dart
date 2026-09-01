import 'package:cuentimobile/core/widgets/section_header.dart';
import 'package:cuentimobile/features/statistics/domain/statistics_data.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/cash_flow_line_chart.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/income_expense_donut.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/monthly_chart.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/summary_card.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({
    required this.stats,
    required this.onRefresh,
    super.key,
  });
  final StatisticsData stats;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SummaryCard(
            income: stats.totalIncome,
            expense: stats.totalExpense,
            balance: stats.balance,
            currency: stats.currency,
          ),
          const SizedBox(height: 24),

          // Income vs Expense Donut
          const SectionHeader('Income vs Expense'),
          const SizedBox(height: 8),
          IncomeExpenseDonut(
            income: stats.totalIncome,
            expense: stats.totalExpense,
          ),
          const SizedBox(height: 24),

          // Net Cash Flow Line Chart
          const SectionHeader('Net Cash Flow Trend'),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: CashFlowLineChart(
              monthlyIncome: stats.monthlyIncome,
              monthlyExpense: stats.monthlyExpense,
            ),
          ),
          const SizedBox(height: 24),

          const SectionHeader('Monthly Cash Flow'),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: MonthlyChart(
              monthlyIncome: stats.monthlyIncome,
              monthlyExpense: stats.monthlyExpense,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            L.of(context).statsTransactionsInPeriod(stats.transactionCount),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
