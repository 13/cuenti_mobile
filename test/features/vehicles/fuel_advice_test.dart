import 'package:cuentimobile/features/vehicles/domain/fuel_advice.dart';
import 'package:cuentimobile/features/vehicles/ui/fuel_meta_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fuelBaseline', () {
    final meta = FuelMeta(
      isFuel: true,
      readings: [
        (date: DateTime(2026, 3, 10), odometer: 45000),
        (date: DateTime(2026, 2, 10), odometer: 44000),
        (date: DateTime(2026, 1, 10), odometer: 43000),
      ],
    );

    test('takes the newest reading strictly before the transaction', () {
      expect(fuelBaseline(meta, DateTime(2026, 3, 2)), 44000);
    });

    test('ignores a reading on the same day, so editing the newest entry '
        'does not compare it against itself', () {
      expect(fuelBaseline(meta, DateTime(2026, 3, 10)), 44000);
    });

    test('compares on the date part only', () {
      expect(fuelBaseline(meta, DateTime(2026, 3, 10, 23, 59)), 44000);
    });

    test('is null when nothing precedes the transaction', () {
      expect(fuelBaseline(meta, DateTime(2026)), isNull);
    });

    test('is null without meta', () {
      expect(fuelBaseline(null, DateTime(2026, 3, 2)), isNull);
    });
  });

  group('fuelLitersWarning', () {
    test('accepts a plausible fill-up', () {
      expect(fuelLitersWarning(41.3), isNull);
    });

    test('rejects zero, negative and absurd volumes', () {
      expect(fuelLitersWarning(0), isNotNull);
      expect(fuelLitersWarning(-1), isNotNull);
      expect(fuelLitersWarning(200.1), isNotNull);
    });

    test('says nothing when the field is empty', () {
      expect(fuelLitersWarning(null), isNull);
    });
  });

  group('fuelInfoLine', () {
    test('warns when the odometer did not increase', () {
      final line = fuelInfoLine(
        odometer: 44000,
        lastOdometer: 44000,
        liters: 40,
        fullTank: true,
      );
      expect(line?.$2, isTrue);
      expect(line?.$1, contains('not higher'));
    });

    test('warns on an implausibly large jump', () {
      final line = fuelInfoLine(
        odometer: 47001,
        lastOdometer: 44000,
        liters: 40,
        fullTank: true,
      );
      expect(line?.$2, isTrue);
      expect(line?.$1, contains('Very large jump'));
    });

    test('reports consumption for a full tank', () {
      final line = fuelInfoLine(
        odometer: 44500,
        lastOdometer: 44000,
        liters: 40,
        fullTank: true,
      );
      expect(line?.$2, isFalse);
      expect(line?.$1, contains('8.0 L/100km'));
    });

    test('reports distance only when the tank was not filled', () {
      final line = fuelInfoLine(
        odometer: 44500,
        lastOdometer: 44000,
        liters: 40,
        fullTank: false,
      );
      expect(line?.$1, contains('500 km since last fill-up'));
    });

    test('is null without an odometer or a baseline', () {
      expect(
        fuelInfoLine(
          odometer: null,
          lastOdometer: 44000,
          liters: 40,
          fullTank: true,
        ),
        isNull,
      );
      expect(
        fuelInfoLine(
          odometer: 44500,
          lastOdometer: null,
          liters: 40,
          fullTank: true,
        ),
        isNull,
      );
    });
  });
}
