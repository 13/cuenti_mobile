import 'dart:io';

import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late TransactionOutbox outbox;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('outbox_test');
    outbox = TransactionOutbox(dir);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  PendingTransaction entry(String id, {int minute = 0, String? rejection}) =>
      PendingTransaction(
        localId: id,
        operation: PendingOperation.create,
        transaction: Transaction(
          amount: 1,
          transactionDate: DateTime(2026, 9, 4),
        ),
        queuedAt: DateTime(2026, 9, 4, 10, minute),
        rejection: rejection,
      );

  test('an added entry comes back', () async {
    await outbox.add(entry('a'));

    expect((await outbox.all()).single.localId, 'a');
  });

  test('entries survive a new outbox over the same directory, which is the '
      'point of writing them down', () async {
    await outbox.add(entry('a'));

    expect((await TransactionOutbox(dir).all()).single.localId, 'a');
  });

  test('they come back oldest first, so they send in the order they were '
      'made', () async {
    await outbox.add(entry('second', minute: 5));
    await outbox.add(entry('first', minute: 1));

    expect((await outbox.all()).map((e) => e.localId), ['first', 'second']);
  });

  test('removing takes one out and leaves the rest', () async {
    await outbox.add(entry('a'));
    await outbox.add(entry('b', minute: 1));

    await outbox.remove('a');

    expect((await outbox.all()).map((e) => e.localId), ['b']);
  });

  test('replacing overwrites in place rather than adding a second', () async {
    await outbox.add(entry('a'));

    await outbox.replace(
      entry('a').copyWith(
        transaction: Transaction(
          amount: 99,
          transactionDate: DateTime(2026, 9, 4),
        ),
      ),
    );

    final all = await outbox.all();
    expect(all, hasLength(1));
    expect(all.single.transaction.amount, 99);
  });

  test('marking a rejection records the reason', () async {
    await outbox.add(entry('a'));

    await outbox.markRejected('a', 'Account is closed');

    expect((await outbox.all()).single.rejection, 'Account is closed');
  });

  test('a file that cannot be read is skipped, not thrown: one bad entry '
      'must not block the whole queue', () async {
    await outbox.add(entry('good'));
    File('${dir.path}/broken.json').writeAsStringSync('{not json');

    expect((await outbox.all()).map((e) => e.localId), ['good']);
  });

  test('clearing empties it', () async {
    await outbox.add(entry('a'));

    await outbox.clear();

    expect(await outbox.all(), isEmpty);
  });
}
