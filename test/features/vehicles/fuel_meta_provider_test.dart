import 'package:cuentimobile/features/vehicles/data/vehicles_repository.dart';
import 'package:cuentimobile/features/vehicles/domain/vehicle_report.dart';
import 'package:cuentimobile/features/vehicles/ui/fuel_meta_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVehiclesRepository extends Mock implements VehiclesRepository {}

void main() {
  late MockVehiclesRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockVehiclesRepository();
    container = ProviderContainer(
      overrides: [vehiclesRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('entries present: isFuel with date-descending readings list', () async {
    when(
      () => repo.getReport(
        categoryId: 5,
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer(
      (_) async => VehicleReport(
        entries: [
          // Server sends date-descending; newest first has no odometer,
          // the next one does — the readings list must skip null odometers
          // but preserve the server's date-descending order.
          FuelEntry(date: DateTime(2026, 8, 1), liters: 40),
          FuelEntry(date: DateTime(2026, 7, 1), odometer: 44870, liters: 38),
          FuelEntry(date: DateTime(2026, 6, 1), odometer: 44000, liters: 41),
        ],
      ),
    );

    final meta = await container.read(fuelMetaProvider(5).future);
    expect(meta.isFuel, isTrue);
    expect(meta.readings, [
      (date: DateTime(2026, 7, 1), odometer: 44870.0),
      (date: DateTime(2026, 6, 1), odometer: 44000.0),
    ]);
    expect(meta.lastOdometer, 44870);
  });

  test(
    'entries with no parseable fuel data (non-fuel memos in category): '
    'not a fuel category',
    () async {
      when(
        () => repo.getReport(
          categoryId: 8,
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer(
        // Server returns a FuelEntry for every expense in the category,
        // including ones whose memo carries no fuel data at all.
        (_) async => VehicleReport(
          entries: [
            FuelEntry(date: DateTime(2026, 8, 1)),
            FuelEntry(date: DateTime(2026, 7, 1)),
          ],
        ),
      );

      final meta = await container.read(fuelMetaProvider(8).future);
      expect(meta.isFuel, isFalse);
      expect(meta.readings, isEmpty);
      expect(meta.lastOdometer, isNull);
    },
  );

  test('no entries: not a fuel category', () async {
    when(
      () => repo.getReport(
        categoryId: 7,
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) async => const VehicleReport());

    final meta = await container.read(fuelMetaProvider(7).future);
    expect(meta.isFuel, isFalse);
    expect(meta.lastOdometer, isNull);
  });

  test('repository error resolves to not-fuel (offline-safe)', () async {
    when(
      () => repo.getReport(
        categoryId: 9,
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenThrow(Exception('offline'));

    final meta = await container.read(fuelMetaProvider(9).future);
    expect(meta.isFuel, isFalse);
    expect(meta.lastOdometer, isNull);
  });
}
