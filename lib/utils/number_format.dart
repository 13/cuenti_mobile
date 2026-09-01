import 'package:intl/intl.dart';

/// Formats a number with "," as decimal separator and "." as thousands separator.
/// Example: 1234.56 → "1.234,56"
String formatNumber(double value, {int decimals = 2}) {
  final formatter = NumberFormat.currency(
    locale: 'de_DE',
    symbol: '',
    decimalDigits: decimals,
  );
  return formatter.format(value).trim();
}

/// Parses an amount the way the app displays it: "." groups thousands and
/// "," is the decimal separator, so "1.234,56" is 1234.56. Null when the
/// text is empty or not a number.
double? parseAmountInput(String text) {
  if (text.isEmpty) return null;
  return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.'));
}

/// Parses a fuel figure, which accepts either separator as the decimal
/// point ("41,3" and "41.3" are both 41.3). Unlike [parseAmountInput] it
/// does not strip dots, because odometer and litre entries are never
/// grouped. Null when the text is empty or not a number.
double? parseFuelInput(String text) {
  if (text.isEmpty) return null;
  return double.tryParse(text.replaceAll(',', '.'));
}
