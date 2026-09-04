import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_transaction.freezed.dart';
part 'pending_transaction.g.dart';

/// Which write is waiting to be sent.
enum PendingOperation { create, update, delete }

Map<String, dynamic> _transactionToJson(Transaction transaction) =>
    transaction.toJson();

Transaction _transactionFromJson(Map<String, dynamic> json) =>
    Transaction.fromJson(json);

/// A transaction write the server has not seen yet.
///
/// [localId] is not decoration. TransactionsController dedupes on `id` and
/// keys rows by it, and a pending create has no server id -- two of them
/// would collide on a null key. This is the key that stands in until the
/// server issues a real one.
@freezed
abstract class PendingTransaction with _$PendingTransaction {
  const factory PendingTransaction({
    required String localId,
    required PendingOperation operation,
    @JsonKey(
      toJson: _transactionToJson,
      fromJson: _transactionFromJson,
    )
    required Transaction transaction,
    required DateTime queuedAt,

    /// The server's own words, once it has refused this entry. Null while
    /// the entry is merely waiting.
    String? rejection,

    /// Whether the edit that produced this entry managed splits itself.
    /// Replayed verbatim: the repository treats an empty list under a true
    /// flag as "remove them all", so guessing this wrong destroys splits the
    /// user never touched.
    @Default(false) bool splitsTouched,
  }) = _PendingTransaction;

  const PendingTransaction._();

  factory PendingTransaction.fromJson(Map<String, dynamic> json) =>
      _$PendingTransactionFromJson(json);

  bool get isRejected => rejection != null;
}
