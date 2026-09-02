import 'package:cuentimobile/core/widgets/amount_text.dart';
import 'package:cuentimobile/features/statistics/domain/savings_rate.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:flutter/material.dart';

/// The period's headline figures, two to a row.
///
/// A single row of three could not hold real amounts: at six figures plus a
/// currency the values ran off the line. Half the width each, on their own
/// line under the label, leaves room for the numbers people actually have --
/// and for the savings rate as a fourth figure.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.income,
    required this.expense,
    required this.balance,
    required this.currency,
    super.key,
  });
  final double income;
  final double expense;
  final double balance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cell(context, l.commonIncome, _amount(income, 'INCOME')),
                _cell(context, l.commonExpense, _amount(expense, 'EXPENSE')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cell(
                  context,
                  l.commonBalance,
                  _amount(balance, balance >= 0 ? 'INCOME' : 'EXPENSE'),
                ),
                _cell(context, l.statsSavingsRate, _savingsRateText(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _amount(double value, String type) => AmountText(
    value,
    type: type,
    currency: currency,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  );

  /// An em dash when there was no income: the rate is undefined then, and
  /// "0 %" would read as having saved none of something never earned.
  Widget _savingsRateText(BuildContext context) {
    final rate = savingsRate(income: income, expense: expense);
    return Text(
      rate == null ? '—' : '${formatNumber(rate, decimals: 1)} %',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: rate != null && rate < 0
            ? Theme.of(context).colorScheme.error
            : null,
      ),
    );
  }

  /// Half the row, with the value shrinking only if it still cannot fit --
  /// an amount long enough to need it stays on one readable line rather
  /// than overflowing the card.
  Widget _cell(BuildContext context, String label, Widget value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: value,
            ),
          ),
        ],
      ),
    );
  }
}
