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

  // Only the two behaviours the fix round for Task 4b (F1/F2) added:
  // that a foreign queue is set aside rather than destroyed, and that
  // concurrent claims of one do not corrupt it. claimForWriting's other
  // branches (already ours, unowned, no account key) are exercised
  // through transactions_controller_test.dart's ownership tests; a full
  // direct unit group here is deferred to the broad review.
  group('claimForWriting', () {
    test(
      'a foreign queue is set aside, not destroyed: its entries stay on '
      'disk after another account claims the queue for a write',
      () async {
        await queue('local-a');
        await outbox.setOwner('key-a');

        await claimForWriting(outbox, 'key-b');
        // The write claimForWriting exists to make room for -- mirroring
        // what _enqueue does right after resolving ownership.
        await queue('local-b');

        expect(
          (await outbox.all()).map((e) => e.localId),
          ['local-b'],
          reason: "b's own entry is the only one a normal read returns",
        );

        final sidelined = dir.listSync().whereType<Directory>().toList();
        expect(
          sidelined,
          hasLength(1),
          reason: 'exactly one subdirectory, not a deleted queue',
        );
        final sidelinedNames = sidelined.single
            .listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last)
            .toList();
        expect(
          sidelinedNames,
          hasLength(2),
          reason: "local-a's entry plus the old owner file, both spared",
        );
        expect(
          sidelinedNames,
          contains('.owner.json'),
          reason:
              'key-a is still recoverable from the file, not just '
              'the entry',
        );
      },
    );

    // Mirrors transaction_outbox_test.dart's 'two concurrent claims of an
    // unowned queue do not collide on the same temp file': same shape
    // (Future.wait of two calls against one target), applied to
    // claimForWriting's sideline-then-claim sequence instead of
    // setOwner's rename. Before serializing the calls, an interleaved
    // pair of sideline() moves could throw (the second finds nothing left
    // to move) or silently drop whichever call's work landed in between.
    test(
      'two concurrent claims of a foreign queue do not throw and leave a '
      'coherent queue',
      () async {
        await queue('local-a');
        await outbox.setOwner('key-a');

        await Future.wait([
          claimForWriting(outbox, 'key-b'),
          claimForWriting(outbox, 'key-b'),
        ]);

        expect(await outbox.owner(), 'key-b');
        expect(await outbox.all(), isEmpty);
      },
    );
  });
}
