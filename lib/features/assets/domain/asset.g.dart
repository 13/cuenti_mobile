// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Asset _$AssetFromJson(Map<String, dynamic> json) => _Asset(
  id: (json['id'] as num?)?.toInt(),
  symbol: json['symbol'] as String? ?? '',
  name: json['name'] as String? ?? '',
  type: json['type'] as String? ?? 'STOCK',
  currentPrice: jsonToDoubleN(json['currentPrice']),
  currency: json['currency'] as String?,
  lastUpdate: json['lastUpdate'] == null
      ? null
      : DateTime.parse(json['lastUpdate'] as String),
);

Map<String, dynamic> _$AssetToJson(_Asset instance) => <String, dynamic>{
  'id': instance.id,
  'symbol': instance.symbol,
  'name': instance.name,
  'type': instance.type,
  'currentPrice': instance.currentPrice,
  'currency': instance.currency,
  'lastUpdate': instance.lastUpdate?.toIso8601String(),
};
