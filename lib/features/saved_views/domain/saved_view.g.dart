// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavedView _$SavedViewFromJson(Map<String, dynamic> json) => _SavedView(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String,
  params: json['params'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$SavedViewToJson(_SavedView instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'params': instance.params,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
