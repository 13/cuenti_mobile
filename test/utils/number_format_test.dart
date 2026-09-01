import 'package:cuentimobile/utils/number_format.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAmountInput', () {
    test('reads a German decimal comma', () {
      expect(parseAmountInput('12,34'), 12.34);
    });

    test('strips dot thousands separators', () {
      expect(parseAmountInput('1.234,56'), 1234.56);
    });

    test('reads a plain integer', () {
      expect(parseAmountInput('40'), 40);
    });

    test('is null for empty or unparseable input', () {
      expect(parseAmountInput(''), isNull);
      expect(parseAmountInput('abc'), isNull);
    });
  });

  group('parseFuelInput', () {
    test('accepts comma or dot decimals', () {
      expect(parseFuelInput('41,3'), 41.3);
      expect(parseFuelInput('41.3'), 41.3);
    });

    test('keeps dots as decimals rather than thousands separators', () {
      expect(parseFuelInput('45.5'), 45.5);
    });

    test('is null for empty or unparseable input', () {
      expect(parseFuelInput(''), isNull);
      expect(parseFuelInput('x'), isNull);
    });
  });

  group('applyLocale', () {
    tearDown(() => applyLocale('de-DE'));

    test('German grouping and decimal marks are the default', () {
      applyLocale('de-DE');
      expect(formatNumber(1234.56), '1.234,56');
    });

    test('English swaps the separators, so the picker is not decorative', () {
      applyLocale('en-US');
      expect(formatNumber(1234.56), '1,234.56');
    });

    test('French uses its own grouping', () {
      applyLocale('fr-FR');
      // A narrow no-break space, not an ASCII one.
      expect(formatNumber(1234.56), contains('234,56'));
      expect(formatNumber(1234.56), isNot(contains('.')));
    });

    test('accepts the dash form the server stores and the underscore form '
        'intl expects', () {
      applyLocale('en-US');
      final dashed = formatNumber(1234.56);
      applyLocale('en_US');
      expect(formatNumber(1234.56), dashed);
    });

    test('falls back to German for a locale intl does not know', () {
      applyLocale('zz-ZZ');
      expect(formatNumber(1234.56), '1.234,56');
    });

    test('parsing stays locale-independent: the input format is the app own '
        'convention, not the display locale', () {
      applyLocale('en-US');
      expect(parseAmountInput('1.234,56'), 1234.56);
    });
  });

  group('localeOf', () {
    test('splits a language-region tag', () {
      expect(localeOf('en-US'), const Locale('en', 'US'));
    });

    test('accepts the underscore form too', () {
      expect(localeOf('fr_FR'), const Locale('fr', 'FR'));
    });

    test('handles a bare language', () {
      expect(localeOf('it'), const Locale('it'));
    });

    test('falls back for junk rather than building a broken Locale', () {
      expect(localeOf(''), const Locale('de', 'DE'));
    });
  });
}
