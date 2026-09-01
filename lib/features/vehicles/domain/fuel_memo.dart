/// Fuel memo token parsing/building, mirroring the server's
/// `VehicleReportService`: `d=<km> l=<liters> [full] <free text>`.
class FuelTokens {
  const FuelTokens({
    this.odometer,
    this.liters,
    this.fullTank = false,
    this.remainderText = '',
  });

  final double? odometer;
  final double? liters;
  final bool fullTank;
  final String remainderText;

  bool get hasFuelData => odometer != null || liters != null;
}

final _odometerPattern = RegExp(r'd[=:]\s*(\d+(?:[.,]\d+)?)');
final _litersPattern = RegExp(r'[vl][~=:]\s*(\d+(?:[.,]\d+)?)');
final _fullTankPattern = RegExp(r'\bfull\b', caseSensitive: false);
final _secondaryOdometerPattern = RegExp(r'(\d{4,})\s*km');
final _secondaryLitersPattern = RegExp(r'(\d+(?:[.,]\d+)?)\s*[lL](?:\s|$|\))');

double? _extract(String memo, RegExp primary, RegExp secondary) {
  final m = primary.firstMatch(memo) ?? secondary.firstMatch(memo);
  if (m == null) return null;
  return double.tryParse(m.group(1)!.replaceAll(',', '.'));
}

FuelTokens parseFuelTokens(String? memo) {
  final safe = memo ?? '';
  final odometer = _extract(safe, _odometerPattern, _secondaryOdometerPattern);
  final liters = _extract(safe, _litersPattern, _secondaryLitersPattern);
  final fullTank = _fullTankPattern.hasMatch(safe);
  var remainder = safe
      .replaceAll(_odometerPattern, '')
      .replaceAll(_litersPattern, '')
      .replaceAll(_secondaryOdometerPattern, '')
      .replaceAllMapped(_secondaryLitersPattern, (_) => ' ')
      .replaceAll(_fullTankPattern, '');
  remainder = remainder.replaceAll(RegExp(r'\s+'), ' ').trim();
  return FuelTokens(
    odometer: odometer,
    liters: liters,
    fullTank: fullTank,
    remainderText: remainder,
  );
}

String formatFuelNumber(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Inverse of [parseFuelTokens]: canonical `d=… l=… full <text>`.
String buildFuelMemo(
  double? odometer,
  double? liters,
  String remainderText, {
  required bool fullTank,
}) {
  final parts = <String>[
    if (odometer != null) 'd=${formatFuelNumber(odometer)}',
    if (liters != null) 'l=${formatFuelNumber(liters)}',
    if (fullTank) 'full',
    if (remainderText.trim().isNotEmpty) remainderText.trim(),
  ];
  return parts.join(' ');
}
