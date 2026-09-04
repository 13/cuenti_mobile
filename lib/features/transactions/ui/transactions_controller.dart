import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_controller.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transactions_controller.freezed.dart';
part 'transactions_controller.g.dart';

/// Whether a write reached the server or is waiting on the device.
enum SaveOutcome { sent, queued }

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

  /// Backends without a stable total order can repeat rows within and
  /// across pages (e.g. pre-v2.10.1) — dedupe on id so we never hand the
  /// UI duplicate ids, which would collide on ValueKey and crash.
  static List<Transaction> _dedupeById(Iterable<Transaction> items) {
    // id is nullable on Transaction (unsaved drafts); server rows always
    // carry one, and duplicate nulls would collide on ValueKey just the
    // same, so treat null as an id value too.
    final seen = <int?>{};
    return [
      for (final t in items)
        if (seen.add(t.id)) t,
    ];
  }

  @override
  Future<TransactionsState> build({
    TransactionFilter filter = defaultFilter,
  }) async {
    final page = await ref
        .read(transactionsRepositoryProvider)
        .getPage(filter: filter);
    return TransactionsState(
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
      final page = await ref
          .read(transactionsRepositoryProvider)
          .getPage(filter: current.filter, page: current.nextPage);
      state = AsyncData(
        current.copyWith(
          items: _dedupeById([...current.items, ...page.content]),
          nextPage: current.nextPage + 1,
          hasMore: current.nextPage + 1 < page.totalPages,
          loadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
      rethrow;
    }
  }

  /// Whether a write reached the server or is waiting on the device.
  Future<SaveOutcome> save(
    Transaction t, {
    bool splitsTouched = false,
    String? localId,
  }) async {
    try {
      await ref
          .read(transactionsRepositoryProvider)
          .save(t, splitsTouched: splitsTouched);
      if (localId != null) {
        await ref.read(transactionOutboxProvider).remove(localId);
      }
      ref
        ..invalidateSelf()
        // Balances changed server-side:
        ..invalidate(accountsControllerProvider);
      await future;
      return SaveOutcome.sent;
      // Only a connection failure is queued. Anything else means the server
      // answered and refused, and holding a refusal back until later just
      // delivers the bad news when the entry has been forgotten.
    } on NetworkException catch (_) {
      await _enqueue(t, localId: localId, splitsTouched: splitsTouched);
      ref.invalidateSelf();
      await future;
      return SaveOutcome.queued;
    }
  }

  /// The queued entry already standing for the server transaction [id], if
  /// there is one. Passing it to [_enqueue] replaces that entry rather than
  /// leaving an update and a delete both waiting for the same row.
  ///
  /// Reads the outbox rather than `state.value?.pending` (that projection
  /// doesn't exist until Task 5) -- the outbox is the authority on what is
  /// queued.
  Future<String?> _queuedIdFor(int id) async {
    final queued = await ref.read(transactionOutboxProvider).all();
    return queued.where((e) => e.transaction.id == id).firstOrNull?.localId;
  }

  /// Ids for queued writes. The timestamp keeps them sortable and
  /// debuggable; the counter keeps two saves in the same microsecond from
  /// becoming one entry, which would lose a transaction silently.
  static int _localIdSeq = 0;

  static String _newLocalId() =>
      'local-${DateTime.now().microsecondsSinceEpoch}-${_localIdSeq++}';

  /// Puts a write in the outbox, replacing the entry it came from so that
  /// editing something queued never leaves two entries for one transaction.
  Future<void> _enqueue(
    Transaction t, {
    String? localId,
    PendingOperation? operation,
    bool splitsTouched = false,
  }) async {
    final outbox = ref.read(transactionOutboxProvider);
    final existing = localId == null
        ? null
        : (await outbox.all()).where((e) => e.localId == localId).firstOrNull;
    final entry = PendingTransaction(
      localId: localId ?? _newLocalId(),
      // An edit of something never sent is still a create: the server has
      // nothing to update.
      operation:
          operation ??
          existing?.operation ??
          (t.id == null ? PendingOperation.create : PendingOperation.update),
      transaction: t,
      queuedAt: existing?.queuedAt ?? DateTime.now(),
      splitsTouched: splitsTouched,
    );
    await outbox.add(entry);
  }

  Future<SaveOutcome> delete(int id) async {
    final current = state.value;
    if (current == null) return SaveOutcome.sent;
    state = AsyncData(
      current.copyWith(items: current.items.where((t) => t.id != id).toList()),
    );
    try {
      await ref.read(transactionsRepositoryProvider).delete(id);
      ref
        ..invalidateSelf()
        ..invalidate(accountsControllerProvider);
      return SaveOutcome.sent;
    } on NetworkException catch (_) {
      await _enqueue(
        current.items
            .firstWhere(
              (t) => t.id == id,
              orElse: () =>
                  Transaction(amount: 0, transactionDate: DateTime.now()),
            )
            .copyWith(id: id),
        // A delete supersedes any edit of the same row already queued: the
        // outbox is keyed by localId, and _enqueue replaces in place.
        localId: await _queuedIdFor(id),
        operation: PendingOperation.delete,
      );
      return SaveOutcome.queued;
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
