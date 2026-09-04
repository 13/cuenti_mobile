// test/features/transactions/transaction_sync_test.dart
import 'dart:io';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transaction_sync.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late Directory dir;
  late TransactionOutbox outbox;
  late MockTransactionsRepository repo;
  late TransactionSync sync;

  setUpAll(
    () => registerFallbackValue(
      Transaction(amount: 0, transactionDate: DateTime(2026)),
    ),
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('sync_test');
    outbox = TransactionOutbox(dir);
    repo = MockTransactionsRepository();
    sync = TransactionSync(outbox, repo);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> queue(
    String id, {
    int minute = 0,
    PendingOperation operation = PendingOperation.create,
    int? transactionId,
  }) => outbox.add(
    PendingTransaction(
      localId: id,
      operation: operation,
      transaction: Transaction(
        id: transactionId,
        amount: 1,
        transactionDate: DateTime(2026, 9, 4),
      ),
      queuedAt: DateTime(2026, 9, 4, 10, minute),
    ),
  );

  test('a delivered entry leaves the queue', () async {
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenAnswer((i) async => i.positionalArguments.first as Transaction);
    await queue('a');

    expect(await sync.drain(), 1);
    expect(await outbox.all(), isEmpty);
  });

  test(
    'two drains running at once send one queued entry exactly once',
    () async {
      var saves = 0;
      when(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      ).thenAnswer((i) async {
        saves++;
        // A real send is not instant, and the overlap is the whole point:
        // reconnect-then-pull-to-refresh is an ordinary gesture.
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return i.positionalArguments.first as Transaction;
      });
      await queue('a');

      final counts = await Future.wait([sync.drain(), sync.drain()]);

      expect(saves, 1, reason: 'a duplicate on the server, invisible here');
      expect(await outbox.all(), isEmpty);
      expect(counts, [1, 1]);
    },
  );

  test('a delete entry is sent as a delete', () async {
    when(() => repo.delete(any())).thenAnswer((_) async {});
    await queue('a', operation: PendingOperation.delete, transactionId: 7);

    await sync.drain();

    verify(() => repo.delete(7)).called(1);
  });

  test('still offline stops the run and keeps everything queued', () async {
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenThrow(const NetworkException('Cannot connect to server'));
    await queue('a');
    await queue('b', minute: 1);

    expect(await sync.drain(), 0);

    final left = await outbox.all();
    expect(left, hasLength(2));
    expect(
      left.every((e) => !e.isRejected),
      isTrue,
      reason: 'still offline means untried, not refused',
    );
    verify(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).called(1);
  });

  test('a refusal marks that entry and the run carries on to the next: one '
      'bad entry must not hold up the rest', () async {
    var calls = 0;
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenAnswer((i) async {
      calls++;
      if (calls == 1) throw const ValidationException('Account is closed');
      return i.positionalArguments.first as Transaction;
    });
    await queue('bad');
    await queue('good', minute: 1);

    expect(await sync.drain(), 1);

    final left = await outbox.all();
    expect(left.single.localId, 'bad');
    expect(left.single.rejection, 'Account is closed');
  });

  test('an entry already refused is not tried again on the next run', () async {
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenAnswer((i) async => i.positionalArguments.first as Transaction);
    await outbox.add(
      PendingTransaction(
        localId: 'refused',
        operation: PendingOperation.create,
        transaction: Transaction(
          amount: 1,
          transactionDate: DateTime(2026, 9, 4),
        ),
        queuedAt: DateTime(2026, 9, 4, 10),
        rejection: 'Account is closed',
      ),
    );

    expect(await sync.drain(), 0);
    verifyNever(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    );
  });

  test('replays the splits flag as it was recorded, since an empty list '
      'under a true flag means delete them all', () async {
    final sent = <bool>[];
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenAnswer((i) async {
      sent.add(i.namedArguments[#splitsTouched] as bool);
      return i.positionalArguments.first as Transaction;
    });
    await outbox.add(
      PendingTransaction(
        localId: 'a',
        operation: PendingOperation.update,
        transaction: Transaction(
          id: 3,
          amount: 1,
          transactionDate: DateTime(2026, 9, 4),
        ),
        queuedAt: DateTime(2026, 9, 4, 10),
      ),
    );

    await sync.drain();

    expect(sent, [false], reason: 'not touched, so not sent');
  });

  test('replays a true splits flag too, since an offline edit that did '
      'manage splits must not sync as if it never touched them', () async {
    final sent = <bool>[];
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenAnswer((i) async {
      sent.add(i.namedArguments[#splitsTouched] as bool);
      return i.positionalArguments.first as Transaction;
    });
    await outbox.add(
      PendingTransaction(
        localId: 'a',
        operation: PendingOperation.update,
        transaction: Transaction(
          id: 3,
          amount: 1,
          transactionDate: DateTime(2026, 9, 4),
        ),
        queuedAt: DateTime(2026, 9, 4, 10),
        splitsTouched: true,
      ),
    );

    await sync.drain();

    expect(sent, [true], reason: 'touched, so sent as touched');
  });
}
