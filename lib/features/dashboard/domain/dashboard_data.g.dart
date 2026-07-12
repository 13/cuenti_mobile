// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DashboardData _$DashboardDataFromJson(Map<String, dynamic> json) =>
    _DashboardData(
      availableCash: jsonToDouble(json['availableCash']),
      portfolioValue: jsonToDouble(json['portfolioValue']),
      netWorth: jsonToDouble(json['netWorth']),
      defaultCurrency: json['defaultCurrency'] as String? ?? 'EUR',
      accounts:
          (json['accounts'] as List<dynamic>?)
              ?.map((e) => Account.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      assetPerformance:
          (json['assetPerformance'] as List<dynamic>?)
              ?.map((e) => AssetPerformance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DashboardDataToJson(_DashboardData instance) =>
    <String, dynamic>{
      'availableCash': instance.availableCash,
      'portfolioValue': instance.portfolioValue,
      'netWorth': instance.netWorth,
      'defaultCurrency': instance.defaultCurrency,
      'accounts': instance.accounts,
      'assetPerformance': instance.assetPerformance,
    };
