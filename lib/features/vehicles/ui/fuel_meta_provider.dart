import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/vehicles_repository.dart';

/// Whether a category holds fuel entries, and the newest known odometer
/// reading — derived from the existing /vehicles/report endpoint so the
/// transaction dialog needs no new server API.
class FuelMeta {
  const FuelMeta({required this.isFuel, this.lastOdometer});

  final bool isFuel;
  final double? lastOdometer;
}

final fuelMetaProvider = FutureProvider.family<FuelMeta, int>((
  ref,
  categoryId,
) async {
  final repo = ref.watch(vehiclesRepositoryProvider);
  try {
    final report = await repo.getReport(
      categoryId: categoryId,
      start: DateTime(2000, 1, 1),
      end: DateTime.now(),
    );
    double? lastOdometer;
    for (final e in report.entries) {
      if (e.odometer != null) {
        lastOdometer = e.odometer;
        break;
      }
    }
    return FuelMeta(
      isFuel: report.entries.isNotEmpty,
      lastOdometer: lastOdometer,
    );
  } catch (_) {
    // Offline or server error: fall back to "not fuel" — the dialog still
    // shows the fuel section when the memo itself parses.
    return const FuelMeta(isFuel: false);
  }
});
