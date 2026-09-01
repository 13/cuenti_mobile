import 'package:cuentimobile/features/vehicles/data/vehicles_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart';

/// Whether a category holds fuel entries, and the known odometer readings —
/// derived from the existing /vehicles/report endpoint so the transaction
/// dialog needs no new server API.
class FuelMeta {
  const FuelMeta({required this.isFuel, this.readings = const []});

  final bool isFuel;

  /// Non-null odometer readings, date-descending (newest first) — mirrors
  /// the server's report ordering. The dialog picks the first reading
  /// strictly before the transaction's date as the comparison baseline
  /// (web parity), not simply the newest overall.
  final List<({DateTime date, double odometer})> readings;

  /// Convenience: newest known odometer reading, regardless of date.
  double? get lastOdometer => readings.isEmpty ? null : readings.first.odometer;
}

final FutureProviderFamily<FuelMeta, int> fuelMetaProvider =
    FutureProvider.family<FuelMeta, int>((
      ref,
      categoryId,
    ) async {
      final repo = ref.watch(vehiclesRepositoryProvider);
      try {
        final report = await repo.getReport(
          categoryId: categoryId,
          start: DateTime(2000),
          end: DateTime.now(),
        );
        // The server returns a FuelEntry for every expense in the category,
        // including ones whose memo carries no fuel data (null odometer AND
        // liters) — isFuel must require at least one entry that actually
        // parsed as fuel, otherwise the fuel section would appear for every
        // used category.
        final isFuel = report.entries.any(
          (e) => e.odometer != null || e.liters != null,
        );
        final readings = [
          for (final e in report.entries)
            if (e.odometer != null) (date: e.date, odometer: e.odometer!),
        ];
        return FuelMeta(isFuel: isFuel, readings: readings);
      } on Exception catch (_) {
        // Offline or server error: fall back to "not fuel" — the dialog still
        // shows the fuel section when the memo itself parses.
        return const FuelMeta(isFuel: false);
      }
    });
