import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_controller.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/outbox_ownership.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
    TransactionFilter filter,
  ) {
    final serverIds = {for (final t in fromServer) t.id};
    final deleted = {
      for (final e in pending)
        if (e.operation == PendingOperation.delete) e.transaction.id,
    };
    final updates = {
      for (final e in pending)
        if (e.operation == PendingOperation.update)
          e.transaction.id!: e.transaction,
    };
    // A refused update or delete whose row the server no longer returns has
    // nowhere else to appear: the overlay above only lands on rows the
    // server still has. Left out, it could never be shown, retried or
    // discarded -- a phantom that only the sign-out count ever sees. It is
    // shown as its own row, refused, so Discard can reach it. One still in
    // flight stays hidden: the drain will send it or refuse it.
    //
    // Keyed by id rather than a plain list: two refused pending entries can
    // exist for the same absent row (an outbox bug can put them there, and
    // this is the one place that would otherwise show the duplicate), and
    // this must surface one row for the row, not one per entry.
    final orphaned = {
      for (final e in pending)
        if (e.operation != PendingOperation.create &&
            e.isRejected &&
            !serverIds.contains(e.transaction.id) &&
            matchesFilter(e.transaction, filter))
          e.transaction.id!: e.transaction,
    };
    final merged = [
      for (final t in fromServer)
        if (!deleted.contains(t.id)) updates[t.id] ?? t,
      for (final e in pending)
        if (e.operation == PendingOperation.create &&
            matchesFilter(e.transaction, filter))
          e.transaction,
      ...orphaned.values,
    ]..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return merged;
  }

  /// Whether a queued create belongs in a list showing [filter].
  ///
  /// Only creates need asking about: an update overlays a server row that
  /// already matched, and a delete only takes one away. Without this a
  /// pending create appeared under every filter and every search -- a row
  /// that plainly does not match what the list says it is showing, which
  /// on the search screen reads as a broken search.
  ///
  /// Matched here rather than at the server for the obvious reason: the
  /// server has never seen this transaction. Where the two could disagree
  /// it is on [TransactionFilter.search], which is taken here as a
  /// case-insensitive substring of the payee or the memo -- narrower than
  /// the server may be, and narrow in the safe direction: an entry hidden
  /// from a search is still on the list with no search at all, still
  /// marked unsent, and still in the sign-out warning.
  static bool matchesFilter(Transaction t, TransactionFilter filter) {
    if (filter.accountId != null &&
        t.fromAccountId != filter.accountId &&
        t.toAccountId != filter.accountId) {
      return false;
    }
    if (filter.type != null && t.type != filter.type) return false;
    if (filter.categoryId != null && t.categoryId != filter.categoryId) {
      return false;
    }
    // start/end are date-only on the wire, so the comparison is too --
    // an entry made at 18:00 is inside a range ending that same day.
    DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
    final day = dayOf(t.transactionDate);
    final start = filter.start;
    if (start != null && day.isBefore(dayOf(start))) return false;
    final end = filter.end;
    if (end != null && day.isAfter(dayOf(end))) return false;
    final search = filter.search;
    if (search != null && search.isNotEmpty) {
      final needle = search.toLowerCase();
      final found = [
        t.payee,
        t.memo,
      ].whereType<String>().any((s) => s.toLowerCase().contains(needle));
      if (!found) return false;
    }
    return true;
  }

  /// The account signed in now, for attributing and claiming the queue.
  /// Read fresh every time rather than cached: the signed-in account can
  /// change between calls, and a stale key would claim or read the wrong
  /// queue.
  String? get _accountKey => accountKeyFor(
    ref.read(apiClientProvider).baseUrl,
    ref.read(authControllerProvider),
  );

  /// The queued entries this account may see. Foreign or unclaimed queues
  /// read as empty -- they are somebody else's amounts and payees, so they
  /// are not merged into the list any more than they are sent.
  Future<List<PendingTransaction>> _pending() =>
      ownedEntries(ref.read(transactionOutboxProvider), _accountKey);

  @override
  Future<TransactionsState> build({
    TransactionFilter filter = defaultFilter,
  }) async {
    final page = await ref
        .read(transactionsRepositoryProvider)
        .getPage(filter: filter);
    final pending = await _pending();
    return TransactionsState(
      items: mergePending(_dedupeById(page.content), pending, filter),
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
      final pending = await _pending();
      // current.items already carries pending creates merged in (they have
      // no server id); dropping those before adding the new page and
      // remerging keeps mergePending from doubling them up.
      final fromServerSoFar = current.items.where((t) => t.id != null).toList();
      state = AsyncData(
        current.copyWith(
          items: mergePending(
            _dedupeById([...fromServerSoFar, ...page.content]),
            pending,
            current.filter,
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
    final pending = await _pending();
    // Rows without an id are pending creates already merged in; dropping
    // them before remerging keeps mergePending from doubling them up, the
    // same bookkeeping loadMore does.
    final fromServer = current.items.where((t) => t.id != null).toList();
    state = AsyncData(
      current.copyWith(
        items: mergePending(fromServer, pending, current.filter),
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
    final queued = await _pending();
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
  ///
  /// [localId] is the entry this call already knows it replaces -- an edit
  /// of something the caller already has the queued local id for. A
  /// [PendingOperation.delete] never carries one: nothing hands `delete()`
  /// the local id of an edit that may already be queued for the same row,
  /// so it is found here instead, by the transaction's own id, and only
  /// **after** the claim below. Doing that lookup in the caller, before
  /// this call even starts, was the bug: it would run against whatever the
  /// queue was before this write resolved ownership -- a foreign root
  /// reads as having nothing queued for the row -- and then this claim
  /// could reclaim the very entry that lookup just missed, leaving two
  /// entries for one row instead of one replacing the other.
  Future<void> _enqueue(
    Transaction t, {
    String? localId,
    PendingOperation? operation,
    bool splitsTouched = false,
  }) async {
    final outbox = ref.read(transactionOutboxProvider);
    // Before the lookup below, not after the add: the lookup has to see
    // the queue it may be amending, and an entry written into somebody
    // else's queue would be sealed away from the person who just typed it.
    await claimForWriting(outbox, _accountKey);
    final resolvedLocalId =
        localId ??
        (operation == PendingOperation.delete && t.id != null
            ? await _queuedIdFor(t.id!)
            : null);
    final existing = resolvedLocalId == null
        ? null
        : (await _pending())
              .where((e) => e.localId == resolvedLocalId)
              .firstOrNull;
    final entry = PendingTransaction(
      localId: resolvedLocalId ?? _newLocalId(),
      // An edit of something never sent is still a create: the server has
      // nothing to update.
      operation:
          operation ??
          existing?.operation ??
          (t.id == null ? PendingOperation.create : PendingOperation.update),
      transaction: t,
      queuedAt: existing?.queuedAt ?? DateTime.now(),
      // Sticky, like the operation above it. The dialog starts every edit
      // at splitsTouched false -- it re-reads the splits from the
      // transaction it was handed but has no memory of who put them there
      // -- so taking the current call's flag alone would turn "these splits
      // were deliberately managed offline" into "leave the splits alone"
      // the moment the user reopened the entry to fix a typo. The
      // repository strips the splits key under a false flag, so the splits
      // would then never be sent at all.
      splitsTouched: splitsTouched || (existing?.splitsTouched ?? false),
    );
    await outbox.add(entry);
  }

  /// Drops a queued write the server has never seen, sending nothing.
  ///
  /// The spec's "deleting a queued create removes it from the queue
  /// outright, with no request ever made": there is no id to ask the server
  /// to delete, and leaving the entry queued would send, on the next drain,
  /// exactly the transaction the user just confirmed getting rid of.
  Future<void> discardPending(String localId) async {
    await ref.read(transactionOutboxProvider).remove(localId);
    await _remergeFromOutbox();
  }

  Future<SaveOutcome> delete(int id) async {
    final current = state.value;
    if (current == null) return SaveOutcome.sent;
    state = AsyncData(
      current.copyWith(items: current.items.where((t) => t.id != id).toList()),
    );
    try {
      await ref.read(transactionsRepositoryProvider).delete(id);
      // An edit of this row may still be queued from an offline spell.
      // Left there, the next drain PUTs a transaction the server no longer
      // has, takes a 404 and marks the entry refused -- and mergePending
      // only overlays updates onto rows the server still returns, so that
      // entry could never be shown, retried or discarded again. Its one
      // remaining effect would be a phantom in the sign-out warning.
      //
      // Guarded on its own: the server has already accepted the delete, so
      // a storage problem here is not a failed delete and must not roll the
      // row back on screen.
      try {
        final queued = await _queuedIdFor(id);
        if (queued != null) {
          await ref.read(transactionOutboxProvider).remove(queued);
        }
      } on Exception catch (e) {
        debugPrint('TransactionsController: stale queued edit left behind: $e');
      }
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
        // A delete supersedes any edit of the same row already queued.
        // _enqueue finds that entry itself, by row id, after its own claim
        // -- see its doc comment for why the lookup cannot run here
        // instead.
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
