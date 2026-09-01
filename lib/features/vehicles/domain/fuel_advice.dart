import 'package:cuentimobile/features/vehicles/domain/fuel_memo.dart';
import 'package:cuentimobile/features/vehicles/ui/fuel_meta_provider.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';

/// Odometer comparison baseline: the newest reading strictly before
/// [transactionDate] (web parity — `VehicleReportService.lastOdometer`).
///
/// Using the newest reading overall would compare a fill-up against itself
/// when editing the most recent entry, giving distance 0 and a false "not
/// increasing" warning. Server dates are date-only, so only the date part
/// is compared.
double? fuelBaseline(FuelMeta? meta, DateTime transactionDate) {
  if (meta == null) return null;
  final day = DateTime(
    transactionDate.year,
    transactionDate.month,
    transactionDate.day,
  );
  for (final reading in meta.readings) {
    if (reading.date.isBefore(day)) return reading.odometer;
  }
  return null;
}

/// Complaint about an implausible fill-up volume, or null when it is fine
/// (or the field is empty).
String? fuelLitersWarning(L l, double? liters) {
  if (liters == null) return null;
  return (liters <= 0 || liters > 200) ? l.fuelImplausibleLiters : null;
}

/// The line shown under the fuel fields as (message, isWarning), or null
/// when there is nothing to say. First matching rule wins, mirroring the
/// web app.
(String, bool)? fuelInfoLine({
  required L l,
  required double? odometer,
  required double? lastOdometer,
  required double? liters,
  required bool fullTank,
}) {
  if (odometer == null || lastOdometer == null) return null;
  final distance = odometer - lastOdometer;
  if (distance <= 0) {
    return (l.fuelNotIncreasing(formatFuelNumber(lastOdometer)), true);
  }
  if (distance > 2000) {
    return (l.fuelLargeJump(formatFuelNumber(distance)), true);
  }
  if (fullTank && liters != null && liters > 0) {
    final consumption = (liters / distance * 100).toStringAsFixed(1);
    return (
      l.fuelConsumption(formatFuelNumber(distance), consumption),
      false,
    );
  }
  return (l.fuelDistanceOnly(formatFuelNumber(distance)), false);
}
