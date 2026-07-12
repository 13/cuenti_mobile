import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/audit_repository.dart';
import '../domain/audit_entry.dart';

part 'audit_controller.freezed.dart';
part 'audit_controller.g.dart';

/// Immutable paged list state for the audit screen.
@freezed
abstract class AuditState with _$AuditState {
  const factory AuditState({
    @Default([]) List<AuditEntry> items,
    @Default(0) int nextPage,
    @Default(true) bool hasMore,
    @Default(false) bool loadingMore,
    String? filter,
  }) = _AuditState;
}

@riverpod
class AuditController extends _$AuditController {
  static const pageSize = 50;

  /// Backends without a stable total order can repeat rows within and
  /// across pages (e.g. pre-v2.10.1) — dedupe on id so we never hand the
  /// UI duplicate ids, which would collide on ValueKey and crash.
  static List<AuditEntry> _dedupeById(Iterable<AuditEntry> items) {
    final seen = <int>{};
    return [
      for (final e in items)
        if (seen.add(e.id)) e,
    ];
  }

  @override
  Future<AuditState> build({String? filter}) async {
    final page = await ref
        .read(auditRepositoryProvider)
        .getPage(filter: filter, page: 0, size: pageSize);
    return AuditState(
      items: _dedupeById(page.content),
      nextPage: 1,
      hasMore: page.totalPages > 1,
      filter: filter,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref.read(auditRepositoryProvider).getPage(
          filter: current.filter,
          page: current.nextPage,
          size: pageSize);
      state = AsyncData(current.copyWith(
        items: _dedupeById([...current.items, ...page.content]),
        nextPage: current.nextPage + 1,
        hasMore: current.nextPage + 1 < page.totalPages,
        loadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
      rethrow;
    }
  }
}
