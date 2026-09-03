import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:cuentimobile/features/currencies/domain/money_format.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => applyLocale('de-DE'));

  const euro = Currency(code: 'EUR', symbol: '€');
  const yen = Currency(
    code: 'JPY',
    symbol: '¥',
    fracDigits: 0,
    decimalChar: '.',
    groupingChar: ',',
  );
  const dinar = Currency(code: 'KWD', symbol: 'د.ك', fracDigits: 3);

  group('formatMoney', () {
    test('a currency with no fraction digits shows none: 1200 yen is not '
        '1200.00 yen', () {
      expect(formatMoney(1200, yen), '1,200');
    });

    test('a three-decimal currency keeps all three', () {
      // dinar sets only fracDigits, so it keeps the model's default
      // separators -- comma for the decimal point.
      expect(formatMoney(12.3456, dinar), '12,346');
    });

    test('the currency decides the separators, which is what the currencies '
        'screen says it does', () {
      expect(formatMoney(1234.5, euro), '1.234,50');
      expect(formatMoney(1234.5, yen), '1,235');
    });

    test('grouping applies to every thousand, not just the first', () {
      expect(formatMoney(1234567.89, euro), '1.234.567,89');
    });

    test('a value under a thousand is not grouped', () {
      expect(formatMoney(999.5, euro), '999,50');
    });

    test('negatives keep their sign in front of the digits', () {
      expect(formatMoney(-1234.5, euro), '-1.234,50');
    });

    test('zero formats like any other value', () {
      expect(formatMoney(0, euro), '0,00');
      expect(formatMoney(0, yen), '0');
    });

    test('no currency falls back to the locale, which is what every amount '
        'did before currencies were consulted at all', () {
      expect(formatMoney(1234.5, null), formatNumber(1234.5));
    });

    test('rounds rather than truncates', () {
      expect(formatMoney(1.996, euro), '2,00');
      expect(formatMoney(1200.6, yen), '1,201');
    });

    test('a half-cent that is not really a half-cent rounds down, because '
        'amounts are doubles: 1.005 is stored as 1.00499...', () {
      expect(
        formatMoney(1.005, euro),
        '1,00',
        reason:
            'documenting what the type does, not endorsing it -- see '
            'the note on this in the file',
      );
    });
  });

  group('currencyFor', () {
    const list = [euro, yen];

    test('finds the currency by code', () {
      expect(currencyFor(list, 'JPY'), yen);
    });

    test('is case-insensitive, since the code arrives from two endpoints', () {
      expect(currencyFor(list, 'jpy'), yen);
    });

    test('a code nothing describes yields null, so the amount falls back '
        'rather than being formatted by the wrong rules', () {
      expect(currencyFor(list, 'CHF'), isNull);
    });

    test('no code at all yields null', () {
      expect(currencyFor(list, null), isNull);
    });
  });

  group('currencyLabel', () {
    test('prefers the symbol the server configured', () {
      expect(currencyLabel(euro, 'EUR'), '€');
    });

    test('falls back to the code when no symbol is set', () {
      expect(currencyLabel(const Currency(code: 'XYZ'), 'XYZ'), 'XYZ');
    });

    test('falls back to the code when the currency is unknown', () {
      expect(currencyLabel(null, 'CHF'), 'CHF');
    });
  });

  group('formatMoney with a fraction-digit override', () {
    test('a unit price can ask for more decimals than the currency uses', () {
      // Fuel is priced per litre to a tenth of a cent; the currency's own
      // two digits would round 1.859 away.
      expect(formatMoney(1.859, euro, fractionDigits: 3), '1,859');
    });

    test('the currency still supplies the punctuation', () {
      expect(formatMoney(1234.5678, euro, fractionDigits: 3), '1.234,568');
    });

    test('an override of zero is honoured, not treated as absent', () {
      expect(formatMoney(1234.5, euro, fractionDigits: 0), '1.235');
    });

    test('without an override the currency decides, as before', () {
      expect(formatMoney(1234.5, euro), '1.234,50');
    });

    test('an unknown currency with an override still gets the decimals', () {
      // The fallback keeps the locale's punctuation; what matters here is
      // that the third decimal survived rather than being rounded away.
      expect(formatMoney(1.859, null, fractionDigits: 3), endsWith('859'));
    });
  });
}
