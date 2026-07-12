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

  @override
  Future<AuditState> build({String? filter}) async {
    final page = await ref
        .read(auditRepositoryProvider)
        .getPage(filter: filter, page: 0, size: pageSize);
    return AuditState(
      items: page.content,
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
        items: [...current.items, ...page.content],
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
