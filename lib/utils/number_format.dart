import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// The locale used when the user has not chosen one, and the fallback when
/// they choose one intl does not know about.
const defaultLocaleTag = 'de-DE';

/// Points intl at the user's chosen locale, so numbers and dates are grouped
/// and marked the way that locale expects.
///
/// Accepts either the dash form the server stores ("de-DE") or the
/// underscore form intl uses ("de_DE"). An unknown locale falls back to
/// [defaultLocaleTag] rather than throwing at a call site far from here.
void applyLocale(String tag) {
  Intl.defaultLocale = Intl.verifiedLocale(
    tag.replaceAll('-', '_'),
    NumberFormat.localeExists,
    onFailure: (_) => defaultLocaleTag.replaceAll('-', '_'),
  );
}

/// Loads the date symbols for every locale the settings screen offers, so
/// [DateFormat] does not throw the first time one is selected.
Future<void> initLocales() => initializeDateFormatting();

/// Formats a number for display using the locale set by [applyLocale].
/// Example, under de-DE: 1234.56 → "1.234,56"
String formatNumber(double value, {int decimals = 2}) {
  final formatter = NumberFormat.currency(
    locale: Intl.defaultLocale ?? defaultLocaleTag.replaceAll('-', '_'),
    symbol: '',
    decimalDigits: decimals,
  );
  return formatter.format(value).trim();
}

/// Parses an amount from a text field. Deliberately locale-independent:
/// "." groups thousands and "," is the decimal separator regardless of the
/// display locale, because that is the convention the input fields document
/// and changing it under a user mid-entry would silently alter amounts.
/// Null when the text is empty or not a number.
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

/// The [Locale] matching a "de-DE"-style tag, for MaterialApp. Falls back to
/// [defaultLocaleTag] for anything unrecognised.
Locale localeOf(String tag) {
  final parts = tag.replaceAll('_', '-').split('-');
  if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    return Locale(parts[0], parts[1]);
  }
  if (parts.isNotEmpty && parts[0].isNotEmpty) return Locale(parts[0]);
  final fallback = defaultLocaleTag.split('-');
  return Locale(fallback[0], fallback[1]);
}
