import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/cuenti_colors.dart';
import '../../utils/number_format.dart';
import '../privacy/privacy_mode.dart';

/// Renders a monetary amount with tabular figures and, optionally, a
/// semantic color + sign based on the transaction [type]
/// (`EXPENSE` / `INCOME` / other → transfer). Masked to `•••••` app-wide
/// when privacy mode is on.
class AmountText extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final baseStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final colored = type != null
        ? baseStyle.copyWith(color: amountColorFor(context, type!))
        : baseStyle;

    if (ref.watch(privacyModeProvider)) {
      return Text('•••••', style: colored);
    }

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

    return Text(text, style: colored);
  }
}
