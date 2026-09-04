import 'dart:io';

import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/outbox_ownership.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late TransactionOutbox outbox;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ownership');
    outbox = TransactionOutbox(dir);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> queue(String localId) => outbox.add(
    PendingTransaction(
      localId: localId,
      operation: PendingOperation.create,
      transaction: Transaction(
        amount: 1,
        transactionDate: DateTime(2026, 9, 4),
      ),
      queuedAt: DateTime(2026, 9, 4, 10),
    ),
  );

  group('accountKeyFor', () {
    test('is the server and the user id', () {
      expect(
        accountKeyFor(
          'https://cuenti.muh',
          const AuthState(user: UserProfile(id: 42, username: 'ben')),
        ),
        'https://cuenti.muh#42',
      );
    });

    // Two accounts can share an id on two different servers. This app is
    // self-hosted, so that is not a hypothetical.
    test('the same id on another server is another account', () {
      const auth = AuthState(user: UserProfile(id: 42, username: 'ben'));

      expect(
        accountKeyFor('https://a.example', auth),
        isNot(accountKeyFor('https://b.example', auth)),
      );
    });

    test('falls back to the username when there is no id', () {
      expect(
        accountKeyFor(
          'https://cuenti.muh',
          const AuthState(user: UserProfile(username: 'ben')),
        ),
        'https://cuenti.muh#ben',
      );
    });

    test('is null when nobody is signed in', () {
      expect(accountKeyFor('https://cuenti.muh', const AuthState()), isNull);
    });

    test('is null when the profile identifies nobody', () {
      expect(
        accountKeyFor(
          'https://cuenti.muh',
          const AuthState(user: UserProfile()),
        ),
        isNull,
      );
    });
  });

  group('ownedEntries', () {
    test('returns the entries when the queue is ours', () async {
      await queue('local-1');
      await outbox.setOwner('key-a');

      expect(await ownedEntries(outbox, 'key-a'), hasLength(1));
    });

    test('returns nothing when the queue belongs to someone else', () async {
      await queue('local-1');
      await outbox.setOwner('key-a');

      expect(await ownedEntries(outbox, 'key-b'), isEmpty);
    });

    // An unowned queue is an upgrade case, not ours to send. The dialog
    // asks; until it is answered nothing goes out.
    test('returns nothing when the queue has no owner', () async {
      await queue('local-1');

      expect(await ownedEntries(outbox, 'key-a'), isEmpty);
    });

    test('returns nothing when nobody is signed in', () async {
      await queue('local-1');
      await outbox.setOwner('key-a');

      expect(await ownedEntries(outbox, null), isEmpty);
    });
  });

  test('entriesIgnoringOwner sees a foreign queue', () async {
    await queue('local-1');
    await outbox.setOwner('key-a');

    expect(await entriesIgnoringOwner(outbox), hasLength(1));
  });

  group('claimStateOf', () {
    test('an empty queue is empty whoever asks', () async {
      expect(await claimStateOf(outbox, 'key-a'), OutboxClaim.empty);
    });

    test('ours', () async {
      await queue('local-1');
      await outbox.setOwner('key-a');

      expect(await claimStateOf(outbox, 'key-a'), OutboxClaim.ours);
    });

    test('foreign', () async {
      await queue('local-1');
      await outbox.setOwner('key-a');

      expect(await claimStateOf(outbox, 'key-b'), OutboxClaim.foreign);
    });

    test('unowned', () async {
      await queue('local-1');

      expect(await claimStateOf(outbox, 'key-a'), OutboxClaim.unowned);
    });

    test('a queue nobody can claim reads as foreign, not ours', () async {
      await queue('local-1');
      await outbox.setOwner('key-a');

      expect(await claimStateOf(outbox, null), OutboxClaim.foreign);
    });
  });

  group('claimIfUnowned', () {
    test('claims a queue with no owner', () async {
      await claimIfUnowned(outbox, 'key-a');

      expect(await outbox.owner(), 'key-a');
    });

    test('leaves an existing owner alone', () async {
      await outbox.setOwner('key-a');

      await claimIfUnowned(outbox, 'key-b');

      expect(await outbox.owner(), 'key-a');
    });

    test('does nothing when nobody is signed in', () async {
      await claimIfUnowned(outbox, null);

      expect(await outbox.owner(), isNull);
    });
  });
}
