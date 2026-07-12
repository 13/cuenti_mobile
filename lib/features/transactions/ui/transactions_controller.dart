import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../accounts/ui/accounts_controller.dart';
import '../data/transactions_repository.dart';
import '../domain/transaction.dart';
import '../domain/transaction_filter.dart';

part 'transactions_controller.freezed.dart';
part 'transactions_controller.g.dart';

/// Immutable paged list state for the transactions screen.
@freezed
abstract class TransactionsState with _$TransactionsState {
  const factory TransactionsState({
    @Default([]) List<Transaction> items,
    @Default(0) int nextPage,
    @Default(true) bool hasMore,
    @Default(false) bool loadingMore,
    @Default(TransactionFilter()) TransactionFilter filter,
  }) = _TransactionsState;
}

@riverpod
class TransactionsController extends _$TransactionsController {
  static const pageSize = 50;
  // riverpod_generator can't revive an inline `const TransactionFilter()`
  // constructor call as a build() default value (freezed's redirecting
  // factory constructor isn't revivable); a static const reference works.
  static const defaultFilter = TransactionFilter();

  @override
  Future<TransactionsState> build(
      {TransactionFilter filter = defaultFilter}) async {
    final page = await ref
        .read(transactionsRepositoryProvider)
        .getPage(filter: filter, page: 0, size: pageSize);
    return TransactionsState(
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
      final page = await ref.read(transactionsRepositoryProvider).getPage(
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

  Future<void> save(Transaction t) async {
    await ref.read(transactionsRepositoryProvider).save(t);
    ref.invalidateSelf();
    // Balances changed server-side:
    ref.invalidate(accountsControllerProvider);
    await future;
  }

  Future<void> delete(int id) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
        items: current.items.where((t) => t.id != id).toList()));
    try {
      await ref.read(transactionsRepositoryProvider).delete(id);
      ref
        ..invalidateSelf()
        ..invalidate(accountsControllerProvider);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
