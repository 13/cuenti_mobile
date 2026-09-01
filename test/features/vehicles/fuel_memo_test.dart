import 'package:cuentimobile/features/vehicles/domain/fuel_memo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseFuelTokens', () {
    test('parses tokens and preserves remainder text', () {
      final t = parseFuelTokens('d=45210 l=41.3 full Aral Autobahn');
      expect(t.odometer, 45210);
      expect(t.liters, 41.3);
      expect(t.fullTank, isTrue);
      expect(t.remainderText, 'Aral Autobahn');
      expect(t.hasFuelData, isTrue);
    });

    test('null and empty memo yield empty tokens', () {
      for (final memo in [null, '']) {
        final t = parseFuelTokens(memo);
        expect(t.odometer, isNull);
        expect(t.liters, isNull);
        expect(t.fullTank, isFalse);
        expect(t.remainderText, isEmpty);
        expect(t.hasFuelData, isFalse);
      }
    });

    test('parses legacy secondary notation', () {
      final t = parseFuelTokens('45210 km 40 l');
      expect(t.odometer, 45210);
      expect(t.liters, 40);
      expect(t.fullTank, isFalse);
    });

    test('parses v= liters and comma decimals', () {
      final t = parseFuelTokens('d=195885 v~13,51');
      expect(t.odometer, 195885);
      expect(t.liters, 13.51);
    });
  });

  group('buildFuelMemo', () {
    test('builds canonical memo', () {
      expect(
        buildFuelMemo(45210, 41.3, true, 'Aral'),
        'd=45210 l=41.3 full Aral',
      );
    });

    test('skips missing parts and trailing zeros', () {
      expect(buildFuelMemo(null, 40, false, ''), 'l=40');
      expect(buildFuelMemo(45210, null, false, ''), 'd=45210');
      expect(buildFuelMemo(null, null, false, 'just a note'), 'just a note');
      expect(buildFuelMemo(null, null, false, ''), isEmpty);
    });

    test('round-trip is stable', () {
      final built = buildFuelMemo(100500, 38.5, true, 'Shell');
      final t = parseFuelTokens(built);
      expect(t.odometer, 100500);
      expect(t.liters, 38.5);
      expect(t.fullTank, isTrue);
      expect(t.remainderText, 'Shell');
      expect(
        buildFuelMemo(t.odometer, t.liters, t.fullTank, t.remainderText),
        built,
      );
    });
  });
}
