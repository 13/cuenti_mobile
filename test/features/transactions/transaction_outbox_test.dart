import 'dart:io';

import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The outbox reaches for a platform channel in open(); the binding has to
  // exist for that call to fail the way it would on a device without one,
  // rather than for lack of a binding.
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('a store opened normally is not a fallback', () {
    expect(TransactionOutbox(dir).isFallback, isFalse);
  });

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

  test('an unreadable entry is logged, not dropped in silence: it is work '
      'the user typed and nothing else has a copy of', () async {
    await outbox.add(entry('good'));
    File('${dir.path}/broken.json').writeAsStringSync('{not json');
    final logged = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => logged.add(message ?? '');
    addTearDown(() => debugPrint = original);

    await outbox.all();

    expect(logged.where((l) => l.contains('broken.json')), hasLength(1));
  });

  test('openOrFallback still gives a working store when there is no '
      'platform channel to ask for one -- a crash there would be a crash '
      'before the first frame', () async {
    // No plugin mock is registered here, so getApplicationSupportDirectory
    // throws MissingPluginException: the "no platform channels at all"
    // case the fallback exists for.
    final fallback = await TransactionOutbox.openOrFallback();
    addTearDown(fallback.clear);

    await fallback.add(entry('a'));

    expect((await fallback.all()).map((e) => e.localId), ['a']);
  });

  test('clearing empties it', () async {
    await outbox.add(entry('a'));

    await outbox.clear();

    expect(await outbox.all(), isEmpty);
  });

  test('atomic write means a partial JSON file is skipped, and a '
      'well-formed entry written after is still returned, with no temp '
      'files left behind', () async {
    await outbox.add(entry('good'));
    File('${dir.path}/partial.json').writeAsStringSync('{incomplete');

    expect((await outbox.all()).map((e) => e.localId), ['good']);
    expect(
      dir.listSync().whereType<File>().where((f) => f.path.contains('.tmp')),
      isEmpty,
    );
  });

  test('a fresh store has no owner', () async {
    expect(await outbox.owner(), isNull);
  });

  test('an owner survives being written and read back', () async {
    await outbox.setOwner('https://cuenti.muh#42');

    expect(await outbox.owner(), 'https://cuenti.muh#42');
  });

  test('setting an owner twice keeps the last one', () async {
    await outbox.setOwner('https://cuenti.muh#42');
    await outbox.setOwner('https://other.example#7');

    expect(await outbox.owner(), 'https://other.example#7');
  });

  test(
    'two concurrent claims of an unowned queue do not collide on the same '
    'temp file: both writes land, and the owner afterwards is one of the '
    'two values, not lost to a rename racing another rename',
    () async {
      await Future.wait([
        outbox.setOwner('https://cuenti.muh#42'),
        outbox.setOwner('https://cuenti.muh#7'),
      ]);

      expect(
        await outbox.owner(),
        anyOf('https://cuenti.muh#42', 'https://cuenti.muh#7'),
      );
    },
  );

  // The owner file lives in the same directory as the entries and ends in
  // .json like they do. If all() tried to parse it, every read would log a
  // skip line and the file would be one bad refactor away from being
  // mistaken for a queued transaction.
  test('the owner file is not mistaken for an entry', () async {
    await outbox.setOwner('https://cuenti.muh#42');
    await outbox.add(entry('local-1'));
    final logged = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => logged.add(message ?? '');
    addTearDown(() => debugPrint = original);

    final entries = await outbox.all();

    expect(entries, hasLength(1));
    expect(entries.single.localId, 'local-1');
    expect(logged.where((l) => l.contains('owner.json')), isEmpty);
  });

  test('discardEntries drops the entries and the owner file', () async {
    await outbox.setOwner('https://cuenti.muh#42');
    await outbox.add(entry('a'));

    await outbox.discardEntries();

    expect(await outbox.all(), isEmpty);
    expect(await outbox.owner(), isNull);
  });

  test('discardEntries leaves a sidelined queue where it is', () async {
    await outbox.setOwner('https://cuenti.muh#42');
    await outbox.add(entry('a'));
    await outbox.sideline();
    await outbox.add(entry('b'));

    await outbox.discardEntries();

    expect(await outbox.all(), isEmpty);
    expect(
      dir.listSync().whereType<Directory>().single.listSync(),
      hasLength(2),
      reason: "the earlier owner's entry and owner file, both untouched",
    );
  });

  test('clear() drops the owner along with the entries', () async {
    await outbox.setOwner('https://cuenti.muh#42');

    await outbox.clear();

    expect(await outbox.owner(), isNull);
  });

  // Was 'an unreadable owner file reads as unowned rather than throwing',
  // asserting isNull. Unowned is the weaker of the two answers -- it is the
  // one claimForWriting adopts on the next write -- so a file we cannot
  // parse must not read as it. It still must not throw.
  test(
    'an unreadable owner file reads as unattributable, not as unowned',
    () async {
      await outbox.setOwner('https://cuenti.muh#42');
      File('${dir.path}/.owner.json').writeAsStringSync('{not json');

      expect(await outbox.owner(), TransactionOutbox.unattributableOwner);
      expect(
        await outbox.owner(),
        isNotNull,
        reason: 'null is the one answer that would let the next write take it',
      );
    },
  );

  test('an owner file naming no account is unattributable too', () async {
    File('${dir.path}/.owner.json').writeAsStringSync('{"account": ""}');

    expect(await outbox.owner(), TransactionOutbox.unattributableOwner);
  });

  test('the sentinel cannot be mistaken for an account key', () {
    expect(
      TransactionOutbox.unattributableOwner.contains('#'),
      isFalse,
      reason: 'every account key is "<baseUrl>#<identity>"',
    );
  });

  group('sideline', () {
    // The owner file has to be the LAST thing that moves. If it went first
    // -- listSync() order is the filesystem's, not ours -- a process killed
    // mid-sideline would leave a subset of A's entries in the root with no
    // owner file beside them: a queue that reads as unowned, which is the
    // one state this feature must never invent by accident.
    /// Sidelines [store] while watching its directory, and reports every
    /// moment the root held entries with no owner file beside them --
    /// the state an interruption there would freeze. `sideline` awaits a
    /// real rename per file, so this sampler runs about once between each
    /// of them.
    Future<List<int>> tornMomentsDuringSideline(
      TransactionOutbox store,
      Directory storeDir,
    ) async {
      final torn = <int>[];
      var samples = 0;
      var finished = false;
      final moving = store.sideline().whenComplete(() => finished = true);
      while (!finished) {
        final names = storeDir
            .listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last)
            .toList();
        samples++;
        if (names.isNotEmpty && !names.contains('.owner.json')) {
          torn.add(names.length);
        }
        await Future<void>.delayed(Duration.zero);
      }
      await moving;
      expect(samples, greaterThan(2), reason: 'the move must be observable');
      return torn;
    }

    // Both creation orders, because the directory order sideline() reads
    // is the filesystem's and not ours -- on this machine's /tmp it comes
    // back reverse-insertion, so which of the two is dangerous depends on
    // a detail no test should depend on. Under the fix neither is.
    for (final ownerFirst in [true, false]) {
      test(
        'never leaves entries behind without their owner file '
        '(owner file written ${ownerFirst ? 'before' : 'after'} the entries)',
        () async {
          if (ownerFirst) await outbox.setOwner('https://cuenti.muh#42');
          for (var i = 0; i < 60; i++) {
            await outbox.add(entry('local-$i'));
          }
          if (!ownerFirst) await outbox.setOwner('https://cuenti.muh#42');

          final torn = await tornMomentsDuringSideline(outbox, dir);

          expect(
            torn,
            isEmpty,
            reason:
                'saw the root holding entries with no owner file beside '
                'them (${torn.length} moments) -- an interruption at any '
                'of them leaves an unowned queue, which the next write '
                'used to adopt',
          );
        },
      );
    }

    test(
      'an interrupted sideline still reads as somebody has claimed it',
      () async {
        // What that ordering buys, stated as the invariant that matters: the
        // owner file outlives every entry it describes, so the queue stays
        // attributable however far the move got.
        await outbox.setOwner('https://cuenti.muh#42');
        await outbox.add(entry('local-1'));
        await outbox.add(entry('local-2'));
        final partial = Directory('${dir.path}/.sidelined-partial')
          ..createSync();
        // One entry moved, the owner file not yet: exactly where a kill
        // lands under the fixed ordering.
        final moved = dir.listSync().whereType<File>().firstWhere(
          (f) => !f.uri.pathSegments.last.startsWith('.'),
        );
        moved.renameSync('${partial.path}/${moved.uri.pathSegments.last}');

        expect(await outbox.owner(), 'https://cuenti.muh#42');
        expect(await outbox.all(), hasLength(1));
      },
    );
  });

  test('an entry whose localId contains / and .. round-trips: add(), all() '
      'returns it with that exact localId, remove() deletes it, and no file '
      'was created outside the outbox directory', () async {
    const specialId = 'path/with/../special';
    await outbox.add(entry(specialId));

    // Verify the entry is stored and retrieved with the exact localId
    final allBefore = await outbox.all();
    expect(allBefore.single.localId, specialId);

    // Verify all JSON files in the outbox directory are within bounds
    // (no path traversal occurred)
    final jsonFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();
    expect(jsonFiles, isNotEmpty);
    for (final file in jsonFiles) {
      expect(file.path.startsWith(dir.path), true);
    }

    // Remove the entry and verify it's gone
    await outbox.remove(specialId);
    expect(await outbox.all(), isEmpty);
  });
}
