import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sends what the outbox is holding, oldest first.
class TransactionSync {
  TransactionSync(this._outbox, this._repository);

  final TransactionOutbox _outbox;
  final TransactionsRepository _repository;

  /// Returns how many entries reached the server.
  ///
  /// A [NetworkException] ends the run: the connection is still down, and
  /// walking the rest of the queue would only collect the same failure. Any
  /// other ApiException means the server answered and refused, so that one
  /// entry is marked with its reason and the run continues -- one bad entry
  /// must not hold up everything queued behind it.
  ///
  /// An entry already carrying a rejection is left alone. It is waiting for
  /// a person to fix or discard it, and retrying it would overwrite the
  /// reason they have not read yet.
  Future<int> drain() async {
    var delivered = 0;
    for (final entry in await _outbox.all()) {
      if (entry.isRejected) continue;
      try {
        await _send(entry);
        await _outbox.remove(entry.localId);
        delivered++;
      } on NetworkException catch (_) {
        return delivered;
      } on ApiException catch (e) {
        await _outbox.markRejected(entry.localId, e.message);
      }
    }
    return delivered;
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
