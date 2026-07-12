import 'package:freezed_annotation/freezed_annotation.dart';
import 'audit_entry.dart';

part 'audit_page.freezed.dart';
part 'audit_page.g.dart';

@freezed
abstract class AuditPage with _$AuditPage {
  const factory AuditPage({
    @Default([]) List<AuditEntry> content,
    @Default(0) int page,
    @Default(50) int size,
    @Default(0) int totalElements,
    @Default(0) int totalPages,
  }) = _AuditPage;

  factory AuditPage.fromJson(Map<String, dynamic> json) =>
      _$AuditPageFromJson(json);
}
