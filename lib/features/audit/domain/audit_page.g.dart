// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuditPage _$AuditPageFromJson(Map<String, dynamic> json) => _AuditPage(
  content:
      (json['content'] as List<dynamic>?)
          ?.map((e) => AuditEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  page: (json['page'] as num?)?.toInt() ?? 0,
  size: (json['size'] as num?)?.toInt() ?? 50,
  totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
  totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AuditPageToJson(_AuditPage instance) =>
    <String, dynamic>{
      'content': instance.content,
      'page': instance.page,
      'size': instance.size,
      'totalElements': instance.totalElements,
      'totalPages': instance.totalPages,
    };
