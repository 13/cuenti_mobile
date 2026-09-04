// test/features/transactions/pending_transaction_test.dart
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final entry = PendingTransaction(
    localId: 'abc',
    operation: PendingOperation.create,
    transaction: Transaction(
      amount: 12.34,
      transactionDate: DateTime(2026, 9, 4),
    ),
    queuedAt: DateTime(2026, 9, 4, 10),
  );

  test('survives a round trip through JSON, since it lives on disk', () {
    final restored = PendingTransaction.fromJson(entry.toJson());

    expect(restored.localId, 'abc');
    expect(restored.operation, PendingOperation.create);
    expect(restored.transaction.amount, 12.34);
    expect(restored.queuedAt, DateTime(2026, 9, 4, 10));
    expect(restored.rejection, isNull);
  });

  test(
    'a rejection survives it too, or the reason would be lost on restart',
    () {
      final refused = entry.copyWith(rejection: 'Account is closed');

      expect(
        PendingTransaction.fromJson(refused.toJson()).rejection,
        'Account is closed',
      );
      expect(refused.isRejected, isTrue);
      expect(entry.isRejected, isFalse);
    },
  );
}
