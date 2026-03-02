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
