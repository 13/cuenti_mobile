import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cuentimobile/features/json_converters.dart';

part 'vehicle_report.freezed.dart';
part 'vehicle_report.g.dart';

@freezed
abstract class FuelEntry with _$FuelEntry {
  const factory FuelEntry({
    required DateTime date, // backend sends yyyy-MM-dd (LocalDate)
    @JsonKey(fromJson: jsonToDoubleN) double? odometer,
    @JsonKey(fromJson: jsonToDoubleN) double? liters,
    @JsonKey(fromJson: jsonToDoubleN) double? amount,
    String? currency,
    String? station,
    String? memo,
    @Default(false) bool fullTank,
    @JsonKey(fromJson: jsonToDoubleN) double? distance,
    @JsonKey(fromJson: jsonToDoubleN) double? pricePerLiter,
    @JsonKey(fromJson: jsonToDoubleN) double? consumption,
  }) = _FuelEntry;
  factory FuelEntry.fromJson(Map<String, dynamic> json) =>
      _$FuelEntryFromJson(json);
}

@freezed
abstract class VehicleReport with _$VehicleReport {
  const factory VehicleReport({
    @Default([]) List<FuelEntry> entries,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double totalCost,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double totalLiters,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double totalDistance,
    @JsonKey(fromJson: jsonToDoubleN) double? avgConsumption,
    @JsonKey(fromJson: jsonToDoubleN) double? avgPricePerLiter,
    @Default('EUR') String currency,
  }) = _VehicleReport;
  factory VehicleReport.fromJson(Map<String, dynamic> json) =>
      _$VehicleReportFromJson(json);
}
