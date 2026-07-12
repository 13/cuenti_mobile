// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payee.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Payee _$PayeeFromJson(Map<String, dynamic> json) => _Payee(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String? ?? '',
  notes: json['notes'] as String?,
  defaultCategoryId: (json['defaultCategoryId'] as num?)?.toInt(),
  defaultCategoryName: json['defaultCategoryName'] as String?,
  defaultPaymentMethod: json['defaultPaymentMethod'] as String?,
);

Map<String, dynamic> _$PayeeToJson(_Payee instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'notes': instance.notes,
  'defaultCategoryId': instance.defaultCategoryId,
  'defaultCategoryName': instance.defaultCategoryName,
  'defaultPaymentMethod': instance.defaultPaymentMethod,
};
