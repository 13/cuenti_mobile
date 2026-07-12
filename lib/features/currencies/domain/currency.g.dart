// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Currency _$CurrencyFromJson(Map<String, dynamic> json) => _Currency(
  id: (json['id'] as num?)?.toInt(),
  code: json['code'] as String? ?? '',
  name: json['name'] as String? ?? '',
  symbol: json['symbol'] as String? ?? '',
  decimalChar: json['decimalChar'] as String? ?? ',',
  fracDigits: (json['fracDigits'] as num?)?.toInt() ?? 2,
  groupingChar: json['groupingChar'] as String? ?? '.',
);

Map<String, dynamic> _$CurrencyToJson(_Currency instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'symbol': instance.symbol,
  'decimalChar': instance.decimalChar,
  'fracDigits': instance.fracDigits,
  'groupingChar': instance.groupingChar,
};
