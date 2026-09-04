import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sends what the outbox is holding, oldest first.
class TransactionSync {
  TransactionSync(this._outbox, this._repository);

  final TransactionOutbox _outbox;
  final TransactionsRepository _repository;

  /// The run currently in progress, if any.
  ///
  /// Four things ask for a drain -- app start, the connection returning,
  /// a manual refresh, and a per-row retry -- and all four fire and forget.
  /// Reconnect-then-pull-to-refresh is an ordinary gesture, and two runs
  /// overlapping sent every queued entry twice: a duplicate on the server,
  /// invisible from the outbox, which is empty afterwards either way.
  /// Memoising the in-flight future is the single-flight guard
  /// `AuthController._initFuture` already uses for the same reason.
  Future<int>? _inFlight;

  /// Returns how many entries reached the server.
  ///
  /// Only a [ValidationException] or a [ServerException] marks an entry
  /// refused: those mean the server answered and said no, and holding the
  /// entry back to retry a permanent refusal for ever helps nobody. That
  /// one entry is marked with the server's own sentence -- [ApiException]'s
  /// `serverMessage` -- to be quoted beside the row later; an empty string
  /// means the server refused without saying why. The run carries on -- one
  /// bad entry must not hold up everything queued behind it.
  ///
  /// Everything else ends the run untouched. A [NetworkException] is the
  /// obvious one: still offline. But an [UnknownApiException] means the
  /// request got no answer at all, and an [UnauthorizedException] means
  /// the CREDENTIAL was refused, not the entry -- a session expiring while
  /// a queue is waiting would otherwise turn every entry into "Refused:
  /// Not authenticated". Since nothing retries a refused entry
  /// automatically, marking either of those would be permanent.
  ///
  /// An entry already carrying a rejection is left alone. It is waiting for
  /// a person to fix or discard it, and retrying it would overwrite the
  /// reason they have not read yet.
  Future<int> drain() =>
      _inFlight ??= _drain().whenComplete(() => _inFlight = null);

  Future<int> _drain() async {
    var delivered = 0;
    for (final entry in await _outbox.all()) {
      if (entry.isRejected) continue;
      try {
        await _send(entry);
      } on ValidationException catch (e) {
        await _record(
          () => _outbox.markRejected(entry.localId, e.serverMessage ?? ''),
        );
        continue;
      } on ServerException catch (e) {
        await _record(
          () => _outbox.markRejected(entry.localId, e.serverMessage ?? ''),
        );
        continue;
      } on ApiException catch (_) {
        return delivered;
      }
      delivered++;
      await _record(() => _outbox.remove(entry.localId));
    }
    return delivered;
  }

  /// The outbox bookkeeping that follows a send.
  ///
  /// A failure here -- an unwritable file, a directory that went away --
  /// used to throw out of the run and leave every entry behind this one
  /// untouched: one entry's storage problem stopping the whole queue. The
  /// entry is left as it stands and the run continues. (A send that
  /// succeeded but could not be recorded will be sent again on the next
  /// drain; the answer to that is a server-side idempotency key, which is
  /// a bigger change than this one.)
  Future<void> _record(Future<void> Function() write) async {
    try {
      await write();
    } on Exception catch (e) {
      debugPrint('TransactionSync: the outbox could not be updated: $e');
    }
  }

  Future<void> _send(PendingTransaction entry) async {
    switch (entry.operation) {
      case PendingOperation.create:
      case PendingOperation.update:
        await _repository.save(
          entry.transaction,
          splitsTouched: entry.splitsTouched,
        );
      case PendingOperation.delete:
        await _repository.delete(entry.transaction.id!);
    }
  }
}

final transactionSyncProvider = Provider<TransactionSync>(
  (ref) => TransactionSync(
    ref.watch(transactionOutboxProvider),
    ref.watch(transactionsRepositoryProvider),
  ),
);
