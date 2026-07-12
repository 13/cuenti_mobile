import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_entry.freezed.dart';
part 'audit_entry.g.dart';

@freezed
abstract class AuditEntry with _$AuditEntry {
  const factory AuditEntry({
    required int id,
    int? userId,
    String? username,
    required DateTime timestamp,
    String? entityType,
    int? entityId,
    String? action, // CREATE | UPDATE | DELETE
    String? details,
  }) = _AuditEntry;

  factory AuditEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditEntryFromJson(json);
}
