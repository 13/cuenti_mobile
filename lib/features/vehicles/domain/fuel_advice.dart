import 'package:cuentimobile/features/vehicles/domain/fuel_memo.dart';
import 'package:cuentimobile/features/vehicles/ui/fuel_meta_provider.dart';

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
String? fuelLitersWarning(double? liters) {
  if (liters == null) return null;
  return (liters <= 0 || liters > 200) ? 'Implausible liters value' : null;
}

/// The line shown under the fuel fields as (message, isWarning), or null
/// when there is nothing to say. First matching rule wins, mirroring the
/// web app.
(String, bool)? fuelInfoLine({
  required double? odometer,
  required double? lastOdometer,
  required double? liters,
  required bool fullTank,
}) {
  if (odometer == null || lastOdometer == null) return null;
  final distance = odometer - lastOdometer;
  if (distance <= 0) {
    return (
      'Odometer is not higher than the last reading '
          '(${formatFuelNumber(lastOdometer)})',
      true,
    );
  }
  if (distance > 2000) {
    return (
      'Very large jump since the last reading '
          '(${formatFuelNumber(distance)} km) — typo?',
      true,
    );
  }
  if (fullTank && liters != null && liters > 0) {
    final consumption = (liters / distance * 100).toStringAsFixed(1);
    return (
      '${formatFuelNumber(distance)} km since last, ~$consumption L/100km',
      false,
    );
  }
  return ('${formatFuelNumber(distance)} km since last fill-up', false);
}
