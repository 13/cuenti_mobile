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

    // Somebody claimed this queue and we cannot tell who. That is not the
    // same as nobody having claimed it, and it must not read as the
    // gentler of the two: the upgrade sheet would offer to adopt a queue
    // that may be another account's.
    test('a queue whose owner file will not parse reads as foreign', () async {
      await queue('local-1');
      await outbox.setOwner('key-a');
      File('${dir.path}/.owner.json').writeAsStringSync('{not json');

      expect(await claimStateOf(outbox, 'key-a'), OutboxClaim.foreign);
      expect(await ownedEntries(outbox, 'key-a'), isEmpty);
    });
  });

  // Was preceded by a `claimIfUnowned` group. That function had no caller
  // left in lib -- claimForWriting superseded it -- while holding the
  // only direct unit tests of anything in this file's write path, so its
  // three cases now sit below against the function that actually runs:
  // an empty queue is claimed, a queue already ours is left alone, and
  // nobody signed in claims nothing.
  //
  // One rule, stated once: a queue this account has not claimed is never
  // written into and never taken. Foreign, unowned and unattributable all
  // end at the same answer -- set aside -- and only the sheet adopts.
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

    // The composition I1 and I2 close together. An unowned queue used to
    // be adopted wholesale by the next write -- so an interrupted
    // sideline, a corrupt owner file, or a user who tapped "Not now"
    // handed one account's entries to another the moment that other
    // account saved anything. The sheet is now the only way a queue
    // becomes yours.
    test(
      'an unowned queue is set aside by a write, not adopted by it',
      () async {
        await queue('local-theirs');

        await claimForWriting(outbox, 'key-b');
        await queue('local-b');

        expect(
          (await ownedEntries(outbox, 'key-b')).map((e) => e.localId),
          ['local-b'],
          reason: 'b sees what b saved, and nothing it did not claim',
        );
        expect(
          dir.listSync().whereType<Directory>(),
          hasLength(1),
          reason: 'set aside, not destroyed',
        );
      },
    );

    test('a queue whose owner file will not parse is set aside too', () async {
      await queue('local-theirs');
      await outbox.setOwner('key-a');
      File('${dir.path}/.owner.json').writeAsStringSync('{not json');

      await claimForWriting(outbox, 'key-b');

      expect(await outbox.all(), isEmpty);
      expect(await outbox.owner(), 'key-b');
      expect(dir.listSync().whereType<Directory>(), hasLength(1));
    });

    // The other half: a queue that is genuinely fresh costs nothing and
    // leaves no empty subdirectory behind.
    test('an empty queue is claimed without a subdirectory', () async {
      await claimForWriting(outbox, 'key-b');

      expect(await outbox.owner(), 'key-b');
      expect(dir.listSync().whereType<Directory>(), isEmpty);
    });

    test('a queue already ours is left exactly as it is', () async {
      await queue('local-a');
      await outbox.setOwner('key-a');

      await claimForWriting(outbox, 'key-a');

      expect((await outbox.all()).map((e) => e.localId), ['local-a']);
      expect(dir.listSync().whereType<Directory>(), isEmpty);
    });

    test('with nobody signed in nothing is claimed and nothing set '
        'aside', () async {
      await queue('local-a');
      await outbox.setOwner('key-a');

      await claimForWriting(outbox, null);

      expect(await outbox.owner(), 'key-a');
      expect(await outbox.all(), hasLength(1));
    });

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

  group('reclaimSidelined', () {
    Future<void> sidelineAs(String owner, List<String> ids) async {
      for (final id in ids) {
        await queue(id);
      }
      await outbox.setOwner(owner);
      await outbox.sideline();
    }

    test('brings back a queue this account set aside, into its own '
        'root', () async {
      await sidelineAs('key-a', ['a-1', 'a-2']);
      await outbox.setOwner('key-a');

      expect(await reclaimSidelined(outbox, 'key-a'), 1);
      expect(
        (await ownedEntries(outbox, 'key-a')).map((e) => e.localId),
        containsAll(['a-1', 'a-2']),
      );
      expect(await outbox.sidelinedQueues(), isEmpty);
    });

    test('claims an empty unowned root when it restores into it', () async {
      await sidelineAs('key-a', ['a-1']);
      // The root is now empty and has no owner file.

      expect(await reclaimSidelined(outbox, 'key-a'), 1);
      expect(await outbox.owner(), 'key-a');
    });

    // Never merge into somebody else's queue. The sheet handles the
    // foreign root; once that is resolved, the next write reclaims.
    test('does nothing while the root belongs to another account', () async {
      await sidelineAs('key-a', ['a-1']);
      await queue('b-1');
      await outbox.setOwner('key-b');

      expect(await reclaimSidelined(outbox, 'key-a'), 0);
      expect(await outbox.sidelinedQueues(), hasLength(1));
      expect((await ownedEntries(outbox, 'key-b')).single.localId, 'b-1');
    });

    // An unowned root that still holds entries is the upgrade case, and
    // the sheet owns it.
    test('does nothing into an unowned root that still holds '
        'entries', () async {
      await sidelineAs('key-a', ['a-1']);
      await queue('legacy-1');

      expect(await reclaimSidelined(outbox, 'key-a'), 0);
      expect(await outbox.owner(), isNull);
      expect(await outbox.sidelinedQueues(), hasLength(1));
    });

    test('never restores a queue with no readable owner', () async {
      await sidelineAs('key-a', ['a-1']);
      final sub = (await outbox.sidelinedQueues()).single.directory;
      File('${sub.path}/.owner.json').writeAsStringSync('{broken');
      await outbox.setOwner('key-a');

      expect(await reclaimSidelined(outbox, 'key-a'), 0);
      expect(await outbox.sidelinedQueues(), hasLength(1));
    });

    test('restores every queue this account owns', () async {
      await sidelineAs('key-a', ['a-1']);
      await sidelineAs('key-a', ['a-2']);
      await outbox.setOwner('key-a');

      expect(await reclaimSidelined(outbox, 'key-a'), 2);
      expect(await ownedEntries(outbox, 'key-a'), hasLength(2));
    });

    test("leaves another account's sidelined queue alone", () async {
      await sidelineAs('key-b', ['b-1']);
      await sidelineAs('key-a', ['a-1']);
      await outbox.setOwner('key-a');

      expect(await reclaimSidelined(outbox, 'key-a'), 1);
      expect((await outbox.sidelinedQueues()).single.owner, 'key-b');
    });

    test('does nothing with no current account', () async {
      await sidelineAs('key-a', ['a-1']);

      expect(await reclaimSidelined(outbox, null), 0);
      expect(await outbox.sidelinedQueues(), hasLength(1));
    });

    // The first write after a queue was set aside is when it comes back.
    test("a claim reclaims the new owner's sidelined queue", () async {
      await sidelineAs('key-a', ['a-1']);
      await queue('b-1');
      await outbox.setOwner('key-b');

      await claimForWriting(outbox, 'key-a');

      expect(await outbox.owner(), 'key-a');
      expect((await ownedEntries(outbox, 'key-a')).single.localId, 'a-1');
      // b's queue was set aside by the claim; it is still there.
      expect(
        (await outbox.sidelinedQueues()).map((q) => q.owner),
        contains('key-b'),
      );
    });

    // Both move files. They must not interleave.
    test('a reclaim racing a claim does not throw and leaves one coherent '
        'queue', () async {
      await sidelineAs('key-a', ['a-1']);
      await queue('b-1');
      await outbox.setOwner('key-b');

      await Future.wait([
        claimForWriting(outbox, 'key-a'),
        reclaimSidelined(outbox, 'key-a'),
      ]);

      expect(await outbox.owner(), 'key-a');
      expect((await ownedEntries(outbox, 'key-a')).single.localId, 'a-1');
    });
  });
}
