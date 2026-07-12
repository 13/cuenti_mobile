// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Category _$CategoryFromJson(Map<String, dynamic> json) => _Category(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String? ?? '',
  fullName: json['fullName'] as String?,
  type: json['type'] as String? ?? 'EXPENSE',
  parentId: (json['parentId'] as num?)?.toInt(),
  parentName: json['parentName'] as String?,
);

Map<String, dynamic> _$CategoryToJson(_Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'fullName': instance.fullName,
  'type': instance.type,
  'parentId': instance.parentId,
  'parentName': instance.parentName,
};
