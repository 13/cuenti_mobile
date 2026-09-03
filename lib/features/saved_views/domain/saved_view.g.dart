// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavedView _$SavedViewFromJson(Map<String, dynamic> json) => _SavedView(
  name: json['name'] as String,
  id: (json['id'] as num?)?.toInt(),
  params: json['params'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$SavedViewToJson(_SavedView instance) =>
    <String, dynamic>{
      'name': instance.name,
      'id': instance.id,
      'params': instance.params,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
