// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forecast_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MonthForecast _$MonthForecastFromJson(Map<String, dynamic> json) =>
    _MonthForecast(
      month: json['month'] as String,
      income: json['income'] == null ? 0 : jsonToDouble(json['income']),
      expense: json['expense'] == null ? 0 : jsonToDouble(json['expense']),
      net: json['net'] == null ? 0 : jsonToDouble(json['net']),
    );

Map<String, dynamic> _$MonthForecastToJson(_MonthForecast instance) =>
    <String, dynamic>{
      'month': instance.month,
      'income': instance.income,
      'expense': instance.expense,
      'net': instance.net,
    };

_ForecastData _$ForecastDataFromJson(Map<String, dynamic> json) =>
    _ForecastData(
      year: (json['year'] as num).toInt(),
      months:
          (json['months'] as List<dynamic>?)
              ?.map((e) => MonthForecast.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalIncome: json['totalIncome'] == null
          ? 0
          : jsonToDouble(json['totalIncome']),
      totalExpense: json['totalExpense'] == null
          ? 0
          : jsonToDouble(json['totalExpense']),
      netForecast: json['netForecast'] == null
          ? 0
          : jsonToDouble(json['netForecast']),
      currency: json['currency'] as String? ?? 'EUR',
    );

Map<String, dynamic> _$ForecastDataToJson(_ForecastData instance) =>
    <String, dynamic>{
      'year': instance.year,
      'months': instance.months,
      'totalIncome': instance.totalIncome,
      'totalExpense': instance.totalExpense,
      'netForecast': instance.netForecast,
      'currency': instance.currency,
    };
