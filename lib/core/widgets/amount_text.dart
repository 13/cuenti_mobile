import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/cuenti_colors.dart';
import '../../utils/number_format.dart';
import '../privacy/privacy_mode.dart';
import 'privacy_blur.dart';

/// Renders a monetary amount with tabular figures and, optionally, a
/// semantic color + sign based on the transaction [type]
/// (`EXPENSE` / `INCOME` / other → transfer). Blurred app-wide via
/// [PrivacyBlur] when privacy mode is on — the real text stays in the
/// tree (so layout/size don't jump), but is excluded from semantics so
/// screen readers don't read the number out.
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

    final textWidget = Text(text, style: colored);

    if (ref.watch(privacyModeProvider)) {
      return ExcludeSemantics(
        child: PrivacyBlur(child: textWidget),
      );
    }

    return textWidget;
  }
}
