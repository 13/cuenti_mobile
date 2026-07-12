// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuditEntry _$AuditEntryFromJson(Map<String, dynamic> json) => _AuditEntry(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  username: json['username'] as String?,
  timestamp: DateTime.parse(json['timestamp'] as String),
  entityType: json['entityType'] as String?,
  entityId: (json['entityId'] as num?)?.toInt(),
  action: json['action'] as String?,
  details: json['details'] as String?,
);

Map<String, dynamic> _$AuditEntryToJson(_AuditEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'username': instance.username,
      'timestamp': instance.timestamp.toIso8601String(),
      'entityType': instance.entityType,
      'entityId': instance.entityId,
      'action': instance.action,
      'details': instance.details,
    };
