import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:cuentimobile/utils/number_format.dart';

/// Formats [value] the way [currency] says it should be written.
///
/// The server sends each currency's fraction digits and separators, the
/// currencies screen lets the user edit them, and until now nothing that
/// rendered an amount read any of it: every figure in the app was two
/// decimals in the app locale's punctuation. That is wrong for a currency
/// with no minor unit (yen, forint) or with three (dinar), and it made the
/// separators on that screen decorative.
///
/// A null [currency] -- unknown code, or the list not loaded yet -- falls
/// back to [formatNumber], which is exactly what every amount did before.
///
/// [fractionDigits] overrides the currency's own count, for the figures that
/// are not a sum of money in that currency: a fuel price per litre is quoted
/// to a tenth of a cent, and rounding it to the currency's two digits would
/// turn 1.859 into 1.86.
String formatMoney(double value, Currency? currency, {int? fractionDigits}) {
  if (currency == null) {
    return formatNumber(value, decimals: fractionDigits ?? 2);
  }

  final requested = fractionDigits ?? currency.fracDigits;
  final digits = requested < 0 ? 0 : requested;
  final fixed = value.abs().toStringAsFixed(digits);
  final parts = fixed.split('.');
  final grouped = _group(parts.first, currency.groupingChar);
  final sign = value.isNegative && double.parse(fixed) != 0 ? '-' : '';

  return parts.length == 1
      ? '$sign$grouped'
      : '$sign$grouped${currency.decimalChar}${parts[1]}';
}

/// Inserts [separator] every three digits from the right.
String _group(String digits, String separator) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(separator);
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// The currency [code] names, or null when nothing describes it.
///
/// Matched case-insensitively: the code on an account and the code on a
/// currency come from different endpoints and need not agree on case.
Currency? currencyFor(List<Currency> currencies, String? code) {
  if (code == null || code.isEmpty) return null;
  final wanted = code.trim().toLowerCase();
  for (final currency in currencies) {
    if (currency.code.trim().toLowerCase() == wanted) return currency;
  }
  return null;
}

/// What to write after an amount: the configured symbol, or the code when
/// there is none to fall back on.
String currencyLabel(Currency? currency, String code) {
  final symbol = currency?.symbol.trim() ?? '';
  return symbol.isEmpty ? code : symbol;
}
