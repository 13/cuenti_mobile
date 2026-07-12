// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_performance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssetPerformance _$AssetPerformanceFromJson(Map<String, dynamic> json) =>
    _AssetPerformance(
      assetName: json['assetName'] as String? ?? '',
      assetSymbol: json['assetSymbol'] as String? ?? '',
      totalUnits: jsonToDouble(json['totalUnits']),
      totalCost: jsonToDouble(json['totalCost']),
      currentValue: jsonToDouble(json['currentValue']),
      currentPrice: jsonToDouble(json['currentPrice']),
      gainLoss: jsonToDouble(json['gainLoss']),
      gainLossPercent: jsonToDouble(json['gainLossPercent']),
    );

Map<String, dynamic> _$AssetPerformanceToJson(_AssetPerformance instance) =>
    <String, dynamic>{
      'assetName': instance.assetName,
      'assetSymbol': instance.assetSymbol,
      'totalUnits': instance.totalUnits,
      'totalCost': instance.totalCost,
      'currentValue': instance.currentValue,
      'currentPrice': instance.currentPrice,
      'gainLoss': instance.gainLoss,
      'gainLossPercent': instance.gainLossPercent,
    };
