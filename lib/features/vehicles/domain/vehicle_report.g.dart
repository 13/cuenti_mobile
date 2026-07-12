// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FuelEntry _$FuelEntryFromJson(Map<String, dynamic> json) => _FuelEntry(
  date: DateTime.parse(json['date'] as String),
  odometer: jsonToDoubleN(json['odometer']),
  liters: jsonToDoubleN(json['liters']),
  amount: jsonToDoubleN(json['amount']),
  currency: json['currency'] as String?,
  station: json['station'] as String?,
  memo: json['memo'] as String?,
  fullTank: json['fullTank'] as bool? ?? false,
  distance: jsonToDoubleN(json['distance']),
  pricePerLiter: jsonToDoubleN(json['pricePerLiter']),
  consumption: jsonToDoubleN(json['consumption']),
);

Map<String, dynamic> _$FuelEntryToJson(_FuelEntry instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'odometer': instance.odometer,
      'liters': instance.liters,
      'amount': instance.amount,
      'currency': instance.currency,
      'station': instance.station,
      'memo': instance.memo,
      'fullTank': instance.fullTank,
      'distance': instance.distance,
      'pricePerLiter': instance.pricePerLiter,
      'consumption': instance.consumption,
    };

_VehicleReport _$VehicleReportFromJson(Map<String, dynamic> json) =>
    _VehicleReport(
      entries:
          (json['entries'] as List<dynamic>?)
              ?.map((e) => FuelEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalCost: json['totalCost'] == null
          ? 0
          : jsonToDouble(json['totalCost']),
      totalLiters: json['totalLiters'] == null
          ? 0
          : jsonToDouble(json['totalLiters']),
      totalDistance: json['totalDistance'] == null
          ? 0
          : jsonToDouble(json['totalDistance']),
      avgConsumption: jsonToDoubleN(json['avgConsumption']),
      avgPricePerLiter: jsonToDoubleN(json['avgPricePerLiter']),
      currency: json['currency'] as String? ?? 'EUR',
    );

Map<String, dynamic> _$VehicleReportToJson(_VehicleReport instance) =>
    <String, dynamic>{
      'entries': instance.entries,
      'totalCost': instance.totalCost,
      'totalLiters': instance.totalLiters,
      'totalDistance': instance.totalDistance,
      'avgConsumption': instance.avgConsumption,
      'avgPricePerLiter': instance.avgPricePerLiter,
      'currency': instance.currency,
    };
