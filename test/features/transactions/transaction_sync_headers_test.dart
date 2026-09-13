import 'dart:io';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transaction_sync.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements TransactionsRepository {}

const _key = 'https://cuenti.muh#2';

/// What the drain tells the server so a resend is safe: the idempotency key
/// on a create, the edited-from version on an update or delete.
void main() {
  late Directory dir;
  late TransactionOutbox outbox;
  late _MockRepository repo;
  late TransactionSync sync;

  setUpAll(
    () => registerFallbackValue(
      Transaction(amount: 0, transactionDate: DateTime(2026)),
    ),
  );

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('sync_headers');
    outbox = TransactionOutbox(dir);
    await outbox.setOwner(_key);
    repo = _MockRepository();
    sync = TransactionSync(outbox, repo, () => _key);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> queue(
    String localId,
    PendingOperation operation, {
    int? id,
    String? version,
  }) => outbox.add(
    PendingTransaction(
      localId: localId,
      operation: operation,
      transaction: Transaction(
        id: id,
        amount: 1,
        transactionDate: DateTime(2026, 9, 4),
        version: version,
      ),
      queuedAt: DateTime(2026, 9, 4, 10),
    ),
  );

  test(
    'a queued create is sent with its local id as the idempotency key',
    () async {
      when(
        () => repo.save(
          any(),
          splitsTouched: any(named: 'splitsTouched'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((i) async => i.positionalArguments.first as Transaction);
      await queue('local-1', PendingOperation.create);

      expect(await sync.drain(), 1);

      verify(
        () => repo.save(
          any(),
          splitsTouched: any(named: 'splitsTouched'),
          idempotencyKey: 'local-1',
        ),
      ).called(1);
    },
  );

  test('a queued update keeps the version it was edited from', () async {
    when(
      () => repo.save(
        any(),
        splitsTouched: any(named: 'splitsTouched'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((i) async => i.positionalArguments.first as Transaction);
    await queue('local-2', PendingOperation.update, id: 5, version: '41');

    await sync.drain();

    final sent =
        verify(
              () => repo.save(
                captureAny(),
                splitsTouched: any(named: 'splitsTouched'),
                idempotencyKey: any(named: 'idempotencyKey', that: isNull),
              ),
            ).captured.single
            as Transaction;
    expect(sent.version, '41');
  });

  test('a queued delete is sent with its version', () async {
    when(
      () => repo.delete(any(), version: any(named: 'version')),
    ).thenAnswer((_) async {});
    await queue('local-3', PendingOperation.delete, id: 7, version: '12');

    expect(await sync.drain(), 1);

    verify(() => repo.delete(7, version: '12')).called(1);
  });

  test(
    'a delete answered 404 was already done: delivered, not refused',
    () async {
      when(() => repo.delete(any(), version: any(named: 'version'))).thenThrow(
        const ValidationException('Not found', statusCode: 404),
      );
      await queue('local-4', PendingOperation.delete, id: 7, version: '12');

      expect(await sync.drain(), 1);

      expect(await outbox.all(), isEmpty);
    },
  );

  test('an update refused as stale (409) is marked refused with the server '
      'reason', () async {
    when(
      () => repo.save(
        any(),
        splitsTouched: any(named: 'splitsTouched'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenThrow(
      const ValidationException(
        'Conflict',
        serverMessage: 'This transaction was changed after this edit was made.',
        statusCode: 409,
      ),
    );
    await queue('local-5', PendingOperation.update, id: 5, version: '1');

    expect(await sync.drain(), 0);

    final entry = (await outbox.all()).single;
    expect(entry.rejection, contains('changed after this edit'));
  });
}
