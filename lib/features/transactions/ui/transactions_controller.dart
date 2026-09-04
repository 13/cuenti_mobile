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

    /// Writes the server has not taken yet. The [items] above already
    /// reflect them; this is here so the UI can mark the rows.
    @Default([]) List<PendingTransaction> pending,
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

  /// Folds the outbox into a server page: queued creates take their place
  /// by date, queued updates replace the row they edit, and queued deletes
  /// take theirs away. Without this an entry made offline would vanish the
  /// moment it was saved, which reads as losing it.
  static List<Transaction> mergePending(
    List<Transaction> fromServer,
    List<PendingTransaction> pending,
  ) {
    final deleted = {
      for (final e in pending)
        if (e.operation == PendingOperation.delete) e.transaction.id,
    };
    final updates = {
      for (final e in pending)
        if (e.operation == PendingOperation.update)
          e.transaction.id!: e.transaction,
    };
    final merged = [
      for (final t in fromServer)
        if (!deleted.contains(t.id)) updates[t.id] ?? t,
      for (final e in pending)
        if (e.operation == PendingOperation.create) e.transaction,
    ]..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return merged;
  }

  @override
  Future<TransactionsState> build({
    TransactionFilter filter = defaultFilter,
  }) async {
    final page = await ref
        .read(transactionsRepositoryProvider)
        .getPage(filter: filter);
    final pending = await ref.read(transactionOutboxProvider).all();
    return TransactionsState(
      items: mergePending(_dedupeById(page.content), pending),
      nextPage: 1,
      hasMore: page.totalPages > 1,
      filter: filter,
      pending: pending,
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
      final pending = await ref.read(transactionOutboxProvider).all();
      // current.items already carries pending creates merged in (they have
      // no server id); dropping those before adding the new page and
      // remerging keeps mergePending from doubling them up.
      final fromServerSoFar = current.items.where((t) => t.id != null).toList();
      state = AsyncData(
        current.copyWith(
          items: mergePending(
            _dedupeById([...fromServerSoFar, ...page.content]),
            pending,
          ),
          nextPage: current.nextPage + 1,
          hasMore: current.nextPage + 1 < page.totalPages,
          loadingMore: false,
          pending: pending,
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
      // Deliberately NOT invalidateSelf(): build() fetches a page, and the
      // connection that just refused this write will refuse that too. The
      // provider would sit in AsyncLoading (Riverpod retries a failed async
      // build with backoff), `future` would never complete, and the sheet
      // would hang with the entry safely on disk and the user told nothing.
      // The outbox is the only thing that changed, so fold it in directly.
      await _remergeFromOutbox();
      return SaveOutcome.queued;
    }
  }

  /// Re-folds the outbox into the rows already on screen, without going
  /// back to the server. Used on the paths that only changed the queue --
  /// offline, a page fetch is exactly what cannot succeed.
  Future<void> _remergeFromOutbox() async {
    final current = state.value;
    if (current == null) return;
    final pending = await ref.read(transactionOutboxProvider).all();
    // Rows without an id are pending creates already merged in; dropping
    // them before remerging keeps mergePending from doubling them up, the
    // same bookkeeping loadMore does.
    final fromServer = current.items.where((t) => t.id != null).toList();
    state = AsyncData(
      current.copyWith(
        items: mergePending(fromServer, pending),
        pending: pending,
      ),
    );
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
      // Same reasoning as save()'s queued branch: only the queue changed,
      // and offline a page fetch is what cannot answer.
      await _remergeFromOutbox();
      return SaveOutcome.queued;
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
