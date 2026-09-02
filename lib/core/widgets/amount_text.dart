import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/privacy_blur.dart';
import 'package:cuentimobile/features/currencies/domain/money_format.dart';
import 'package:cuentimobile/features/currencies/ui/currencies_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders a monetary amount the way its currency says it should be
/// written -- its own fraction digits, punctuation and symbol, which the
/// server sends and the currencies screen edits -- with tabular figures
/// and, optionally, a
/// semantic color + sign based on the transaction [type]
/// (`EXPENSE` / `INCOME` / other → transfer). Blurred app-wide via
/// [PrivacyBlur] when privacy mode is on — the real text stays in the
/// tree (so layout/size don't jump), but is excluded from semantics so
/// screen readers don't read the number out.
///
/// Reading the currency list makes this leaf widget depend on a fetch. That
/// is deliberate: the alternative was threading a Currency through every one
/// of the hundred-odd call sites. A test that pumps an AmountText on its own
/// should override `currenciesRepositoryProvider`, or the request is still
/// in flight when the tree is torn down.
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

    // The currency decides its own fraction digits and punctuation. Until
    // the list arrives -- or for a code nothing describes -- formatMoney
    // falls back to the locale, which is how every amount used to read.
    final currencies =
        ref.watch(currenciesControllerProvider).value ?? const [];
    final resolved = currencyFor(currencies, currency);
    final formatted = formatMoney(amount.abs(), resolved);
    final prefix = signed && type != null
        ? (type == 'EXPENSE'
              ? '−'
              : type == 'INCOME'
              ? '+'
              : '')
        : '';
    final text = currency != null
        ? '$prefix$formatted ${currencyLabel(resolved, currency!)}'
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
