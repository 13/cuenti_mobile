import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_entry.freezed.dart';
part 'audit_entry.g.dart';

@freezed
abstract class AuditEntry with _$AuditEntry {
  const factory AuditEntry({
    required int id,
    required DateTime timestamp,
    int? userId,
    String? username,
    String? entityType,
    int? entityId,
    String? action, // CREATE | UPDATE | DELETE
    String? details,
  }) = _AuditEntry;

  factory AuditEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditEntryFromJson(json);
}
