import 'package:cuentimobile/core/widgets/amount_text.dart';
import 'package:flutter/material.dart';

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _metric(context, 'Income', income, 'INCOME'),
            _metric(context, 'Expense', expense, 'EXPENSE'),
            _metric(
              context,
              'Balance',
              balance,
              balance >= 0 ? 'INCOME' : 'EXPENSE',
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    double value,
    String type,
  ) {
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
