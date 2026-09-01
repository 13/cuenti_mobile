import 'package:cuentimobile/utils/number_format.dart';
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
}
