import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/outbox_ownership.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sends what the outbox is holding, oldest first.
class TransactionSync {
  TransactionSync(this._outbox, this._repository, this._accountKey);

  final TransactionOutbox _outbox;
  final TransactionsRepository _repository;

  /// Read at the start of every pass rather than captured once: a drain can
  /// outlive the sign-in it started under.
  final String? Function() _accountKey;

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

  /// The follow-up run queued by [drainAgain], if one is waiting.
  Future<int>? _queued;

  /// Sends what is queued, starting a fresh pass if one is already running.
  ///
  /// A person tapping *Try again* has just changed the queue -- their
  /// entry's rejection was cleared a moment ago. [drain] would hand them
  /// the pass already in flight, and that pass read the outbox before the
  /// change, so it would skip the very entry they asked about: the row
  /// goes from "Refused" to "Not sent yet" with no request made. This
  /// waits for the current pass and then reads the outbox again.
  ///
  /// At most one follow-up is queued, so a burst of taps cannot fan out
  /// into a queue of passes -- they share the one that will see every
  /// change made before that follow-up starts. A tap that lands only once
  /// the follow-up is already running is too late for it -- the follow-up
  /// already read the outbox -- so it queues a fresh one of its own rather
  /// than joining a pass that cannot see it.
  Future<int> drainAgain() {
    final running = _inFlight;
    if (running == null) return drain();
    return _queued ??= _drainAfter(running);
  }

  /// The body of the follow-up [drainAgain] queues: wait for [running],
  /// then start a genuinely new pass.
  Future<int> _drainAfter(Future<int> running) async {
    try {
      await running;
    } on Object catch (_) {
      // The pass we waited on failed. That is not this retry's answer --
      // it read the outbox before this retry's change, so try regardless.
      // `Object` rather than `Exception`: an `Error` propagating from here
      // would skip the `return drain()` below and the retry the person
      // asked for would silently never run.
    } finally {
      // Released before the fresh pass starts, not after it finishes: a
      // retry tapped while that pass is running must queue its own
      // follow-up rather than join one that has already read the outbox.
      // In a `finally` rather than after the `try`, so the slot is
      // released on every path out of the await no matter what the catch
      // above is ever narrowed to -- never wedged shut forever.
      _queued = null;
    }
    return drain();
  }

  Future<int> _drain() async {
    var delivered = 0;
    for (final entry in await ownedEntries(_outbox, _accountKey())) {
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
    () => accountKeyFor(
      ref.read(apiClientProvider).baseUrl,
      ref.read(authControllerProvider),
    ),
  ),
);
