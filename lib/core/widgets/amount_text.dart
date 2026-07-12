import 'package:flutter/material.dart';
import '../theme/cuenti_colors.dart';
import '../../utils/number_format.dart';

/// Renders a monetary amount with tabular figures and, optionally, a
/// semantic color + sign based on the transaction [type]
/// (`EXPENSE` / `INCOME` / other → transfer).
class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    this.type,
    this.signed = false,
    this.currency,
    this.style,
    super.key,
  });

  final double amount;
  final String? type;
  final bool signed;
  final String? currency;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final formatted = formatNumber(amount.abs());
    final prefix = signed && type != null
        ? (type == 'EXPENSE'
              ? '−'
              : type == 'INCOME'
              ? '+'
              : '')
        : '';
    final text = currency != null
        ? '$prefix$formatted $currency'
        : '$prefix$formatted';

    final baseStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final colored = type != null
        ? baseStyle.copyWith(color: amountColorFor(context, type!))
        : baseStyle;

    return Text(text, style: colored);
  }
}
