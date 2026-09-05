# Outbox Follow-ups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a refused outbox entry always reachable, make sidelining two-way, and clear four chores the ownership branch carried.

**Architecture:** `mergePending` gains one rule — a refused `update`/`delete` whose server row is gone is surfaced as its own row — so the existing Retry/Discard reach it. `TransactionOutbox` learns to list and restore its `.sidelined-*` subdirectories, and `outbox_ownership.dart` gains `reclaimSidelined`, gated on the root being ours or empty-and-unowned, called after a claim and at the sign-in check. The chores are independent.

**Tech Stack:** Flutter (Android only), Riverpod, Dio, freezed, `flutter gen-l10n` with three ARB catalogues.

**Spec:** `docs/superpowers/specs/2026-09-05-outbox-followups-design.md`

## Global Constraints

- Every new or changed user-facing string goes in `lib/l10n/app_en.arb`, `app_de.arb` and `app_it.arb`; then run `flutter gen-l10n`. `test/l10n/translations_test.dart` enforces parity including ICU placeholder sets.
- Italian calls a transaction *movimento* (masculine). The catalogue uses it fifteen times; nothing new may say *operazione*.
- `lib/features/transactions/data/outbox_ownership.dart` stays free of Riverpod.
- `test/features/transactions/outbox_reads_test.dart` bans `\.all\(\)` outside `outbox_ownership.dart` and `transaction_outbox.dart`. Do not add an allow-list entry; the new store methods are not reads of the queue.
- Do NOT import `package:flutter/foundation.dart` broadly into a file holding a `@freezed` class; use `show debugPrint`. `transactions_controller.dart` already does.
- After touching a `@freezed`/`@riverpod` file, run `dart run build_runner build` (no `--delete-conflicting-outputs`; removed). CI fails on stale generated output.
- Run with `export PATH="$HOME/flutter/bin:$PATH"`. Full gate: `flutter analyze`, `dart format --output=none --set-exit-if-changed lib test integration_test tool`, `flutter test --coverage`, `dart run tool/check_coverage.dart 80`. The `--coverage` matters: `check_coverage.dart` scores whatever `lcov.info` is on disk.
- Baseline: 1151 tests passing, coverage 88.2%.
- Run every test command in the FOREGROUND with a generous timeout. Do not background them and do not use monitors.
- Widget tests touching the outbox do real `dart:io`; wait for what you need inside `tester.runAsync` using the `waitFor`/`waitForOutbox` helpers in `transactions_screen_test.dart:516-540`, never a fixed delay or an iteration bound.

---

### Task 1: a refused orphan is a row

**Files:**
- Modify: `lib/features/transactions/ui/transactions_controller.dart:63-86` (`mergePending`)
- Test: `test/features/transactions/transactions_controller_test.dart`, `test/features/transactions/transactions_screen_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: no new API. `mergePending`'s contract widens: a rejected `update`/`delete` whose id is absent from the server rows is included.

- [ ] **Step 1: Write the failing unit tests**

In `test/features/transactions/transactions_controller_test.dart`, in the group that tests `mergePending` directly:

```dart
    test('a refused update whose row the server no longer has is surfaced',
        () {
      final orphan = PendingTransaction(
        localId: 'local-orphan',
        operation: PendingOperation.update,
        transaction: tx(id: 7, amount: 42),
        queuedAt: DateTime(2026, 9, 5, 10),
        rejection: 'Not found',
      );

      final merged = TransactionsController.mergePending(
        [tx(id: 1), tx(id: 2)],
        [orphan],
        const TransactionFilter(),
      );

      expect(merged.map((t) => t.id), contains(7));
      expect(merged.singleWhere((t) => t.id == 7).amount, 42);
    });

    // In flight, the drain will settle it one way or the other. Hiding it
    // until then is today's behaviour and it stays.
    test('an update for a missing row that is not refused stays hidden', () {
      final inFlight = PendingTransaction(
        localId: 'local-flight',
        operation: PendingOperation.update,
        transaction: tx(id: 7, amount: 42),
        queuedAt: DateTime(2026, 9, 5, 10),
      );

      final merged = TransactionsController.mergePending(
        [tx(id: 1)],
        [inFlight],
        const TransactionFilter(),
      );

      expect(merged.map((t) => t.id), isNot(contains(7)));
    });

    test('a refused delete for a missing row is surfaced too', () {
      final orphan = PendingTransaction(
        localId: 'local-del',
        operation: PendingOperation.delete,
        transaction: tx(id: 9, amount: 5),
        queuedAt: DateTime(2026, 9, 5, 10),
        rejection: 'Not found',
      );

      final merged = TransactionsController.mergePending(
        [tx(id: 1)],
        [orphan],
        const TransactionFilter(),
      );

      expect(merged.map((t) => t.id), contains(9));
    });

    // A refused update whose row the server STILL returns is not an
    // orphan; it is overlaid as before and must not be duplicated.
    test('a refused update whose row still exists is overlaid, not doubled',
        () {
      final refused = PendingTransaction(
        localId: 'local-still',
        operation: PendingOperation.update,
        transaction: tx(id: 1, amount: 99),
        queuedAt: DateTime(2026, 9, 5, 10),
        rejection: 'Invalid',
      );

      final merged = TransactionsController.mergePending(
        [tx(id: 1, amount: 10)],
        [refused],
        const TransactionFilter(),
      );

      expect(merged.where((t) => t.id == 1), hasLength(1));
      expect(merged.single.amount, 99);
    });

    test('a surfaced orphan obeys the active filter', () {
      final orphan = PendingTransaction(
        localId: 'local-orphan',
        operation: PendingOperation.update,
        transaction: tx(id: 7, amount: 42, fromAccountId: 1),
        queuedAt: DateTime(2026, 9, 5, 10),
        rejection: 'Not found',
      );

      final merged = TransactionsController.mergePending(
        const [],
        [orphan],
        const TransactionFilter(accountId: 999),
      );

      expect(merged, isEmpty);
    });
```

Adapt `tx(...)` and the filter constructor to the fixtures that file already uses.

- [ ] **Step 2: Run them and watch them fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transactions_controller_test.dart`
Expected: FAIL — the two "is surfaced" tests find no id 7 / 9; the others pass already (they pin current behaviour and must keep passing).

- [ ] **Step 3: Surface refused orphans**

In `lib/features/transactions/ui/transactions_controller.dart`, replace `mergePending`'s body:

```dart
  static List<Transaction> mergePending(
    List<Transaction> fromServer,
    List<PendingTransaction> pending,
    TransactionFilter filter,
  ) {
    final serverIds = {for (final t in fromServer) t.id};
    final deleted = {
      for (final e in pending)
        if (e.operation == PendingOperation.delete) e.transaction.id,
    };
    final updates = {
      for (final e in pending)
        if (e.operation == PendingOperation.update)
          e.transaction.id!: e.transaction,
    };
    final merged = [
      for (final t in fromServer)
        if (!deleted.contains(t.id)) updates[t.id] ?? t,
      for (final e in pending)
        if (e.operation == PendingOperation.create &&
            matchesFilter(e.transaction, filter))
          e.transaction,
      // A refused update or delete whose row the server no longer returns
      // has nowhere else to appear: the overlay above only lands on rows
      // the server still has. Left out, it could never be shown, retried or
      // discarded -- a phantom that only the sign-out count ever sees. It
      // is shown as its own row, refused, so Discard can reach it. One
      // still in flight stays hidden: the drain will send it or refuse it.
      for (final e in pending)
        if (e.operation != PendingOperation.create &&
            e.isRejected &&
            !serverIds.contains(e.transaction.id) &&
            matchesFilter(e.transaction, filter))
          e.transaction,
    ]..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return merged;
  }
```

- [ ] **Step 4: Run and watch them pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transactions_controller_test.dart`
Expected: PASS.

- [ ] **Step 5: Write the failing widget test**

In `test/features/transactions/transactions_screen_test.dart`, in the "what has not been sent" group, using that file's `queue(...)` helper with `rejection:` and its `pumpScreen`:

```dart
    testWidgets('a refused edit of a row the server no longer has is shown, '
        'and can be discarded', (tester) async {
      // The server page in this file has no id 777. The queued edit for it
      // was refused (the drain took a 404), so it is an orphan: nothing
      // the overlay could land on.
      await queue(
        tester,
        localId: 'local-orphan',
        operation: PendingOperation.update,
        id: 777,
        payee: 'Ghost',
        rejection: 'Not found',
      );
      await pumpScreen(tester);

      expect(find.text('Ghost'), findsOneWidget);
      expect(find.textContaining('Refused'), findsOneWidget);

      await tapAndWait(tester, find.text('Discard'));

      expect(find.text('Ghost'), findsNothing);
      expect(
        (await TransactionOutbox(outboxDir).all())
            .where((e) => e.localId == 'local-orphan'),
        isEmpty,
      );
    });
```

If `queue` cannot take `operation:`/`id:`, extend it the way its siblings are extended — do not add a parallel helper. Read the file's existing refused-row test for the discard tap pattern.

- [ ] **Step 6: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transactions_screen_test.dart`
Expected: FAIL on `find.text('Ghost')` — before Step 3 the row is never built. (If you ran Step 3 first this passes; the unit RED in Step 2 is the load-bearing one.)

- [ ] **Step 7: Run the transactions suites**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/transactions/ui/transactions_controller.dart \
        test/features/transactions/transactions_controller_test.dart \
        test/features/transactions/transactions_screen_test.dart
git commit -m "fix(transactions): a refused entry with no row is shown, so it can be discarded"
```

---

### Task 2: the store can list and restore what it set aside

**Files:**
- Modify: `lib/features/transactions/data/transaction_outbox.dart`
- Test: `test/features/transactions/transaction_outbox_test.dart`

**Interfaces:**
- Consumes: `sideline()` (exists).
- Produces: `class SidelinedQueue { final Directory directory; final String? owner; }`, `Future<List<SidelinedQueue>> TransactionOutbox.sidelinedQueues()`, `Future<bool> TransactionOutbox.restore(SidelinedQueue queue)` (true if the subdirectory was fully restored and removed). Task 3 uses all three.

- [ ] **Step 1: Write the failing tests**

In `test/features/transactions/transaction_outbox_test.dart`:

```dart
  group('sidelined queues', () {
    test('a fresh store has none', () async {
      expect(await TransactionOutbox(dir).sidelinedQueues(), isEmpty);
    });

    test('a sidelined queue is listed with its recorded owner', () async {
      final outbox = TransactionOutbox(dir);
      await outbox.add(entry('local-1'));
      await outbox.setOwner('key-a');

      await outbox.sideline();

      final queues = await outbox.sidelinedQueues();
      expect(queues, hasLength(1));
      expect(queues.single.owner, 'key-a');
      expect(queues.single.directory.existsSync(), isTrue);
    });

    test('a sidelined queue with no readable owner lists as null', () async {
      final outbox = TransactionOutbox(dir);
      await outbox.add(entry('local-1'));
      await outbox.setOwner('key-a');
      await outbox.sideline();
      final sub = (await outbox.sidelinedQueues()).single.directory;
      File('${sub.path}/.owner.json').writeAsStringSync('{broken');

      expect((await outbox.sidelinedQueues()).single.owner, isNull);
    });

    test('restore brings the entries back and removes the subdirectory',
        () async {
      final outbox = TransactionOutbox(dir);
      await outbox.add(entry('local-1'));
      await outbox.add(entry('local-2'));
      await outbox.setOwner('key-a');
      await outbox.sideline();
      expect(await outbox.all(), isEmpty);

      final queue = (await outbox.sidelinedQueues()).single;
      final done = await outbox.restore(queue);

      expect(done, isTrue);
      expect(
        (await outbox.all()).map((e) => e.localId),
        containsAll(['local-1', 'local-2']),
      );
      expect(queue.directory.existsSync(), isFalse);
      expect(await outbox.sidelinedQueues(), isEmpty);
    });

    // restore() moves entries, not ownership. Whoever owns the root keeps
    // it; the caller decides whether the root should be claimed.
    test('restore does not touch the root owner file', () async {
      final outbox = TransactionOutbox(dir);
      await outbox.add(entry('local-1'));
      await outbox.setOwner('key-a');
      await outbox.sideline();
      await outbox.setOwner('key-b');

      await outbox.restore((await outbox.sidelinedQueues()).single);

      expect(await outbox.owner(), 'key-b');
    });

    // Local ids are a timestamp and a counter, so this cannot happen. The
    // rule exists so the impossible case is a no-op and not a loss.
    test('restore never overwrites an entry already in the root', () async {
      final outbox = TransactionOutbox(dir);
      await outbox.add(entry('local-1', amount: 1));
      await outbox.setOwner('key-a');
      await outbox.sideline();
      await outbox.add(entry('local-1', amount: 2));

      final queue = (await outbox.sidelinedQueues()).single;
      final done = await outbox.restore(queue);

      expect(done, isFalse);
      expect((await outbox.all()).single.transaction.amount, 2);
      expect(queue.directory.existsSync(), isTrue,
          reason: 'the colliding entry stays where it was');
    });
  });
```

Match `dir`, `entry(...)` to the file's existing fixtures; if `entry` has no `amount:` parameter, add one the way its other parameters are added.

- [ ] **Step 2: Run them and watch them fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transaction_outbox_test.dart`
Expected: FAIL — `SidelinedQueue`, `sidelinedQueues`, `restore` undefined.

- [ ] **Step 3: Add the type and the two methods**

In `lib/features/transactions/data/transaction_outbox.dart`, add above the class:

```dart
/// A queue [TransactionOutbox.sideline] set aside: its subdirectory, and
/// the account it recorded as owner -- null when that record is missing or
/// unreadable, in which case nobody may reclaim it.
class SidelinedQueue {
  const SidelinedQueue(this.directory, this.owner);

  final Directory directory;
  final String? owner;
}
```

Inside the class, after `sideline()`:

```dart
  /// Reads one owner file, wherever it is. Shared by [owner] for the root
  /// and [sidelinedQueues] for each subdirectory, so the two cannot
  /// disagree about what counts as readable.
  static String? _readOwnerFile(File file) {
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      final account = decoded is Map<String, dynamic>
          ? decoded['account']
          : null;
      return account is String && account.isNotEmpty ? account : null;
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      debugPrint('TransactionOutbox: unreadable owner file ${file.path}: $e');
      return null;
    }
  }

  /// Every queue [sideline] has set aside, oldest first, each with the
  /// owner it recorded. Order is by directory name, which starts with the
  /// moment of the sideline.
  Future<List<SidelinedQueue>> sidelinedQueues() async {
    if (!_directory.existsSync()) return const [];
    final dirs =
        _directory
            .listSync()
            .whereType<Directory>()
            .where((d) => d.uri.pathSegments
                .lastWhere((s) => s.isNotEmpty)
                .startsWith('.sidelined-'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    return [
      for (final d in dirs)
        SidelinedQueue(d, _readOwnerFile(File('${d.path}/.owner.json'))),
    ];
  }

  /// Moves a sidelined queue's entries back into the root and removes the
  /// subdirectory. The owner file inside it is deleted, not moved: whether
  /// the root is claimed is the caller's decision, not this method's.
  ///
  /// Overwrites nothing. An entry whose filename already exists in the root
  /// is left in the subdirectory, the subdirectory is kept, and the return
  /// is false. Local ids are a timestamp plus a counter, so this cannot
  /// happen; the rule makes the impossible case a no-op rather than a loss.
  Future<bool> restore(SidelinedQueue queue) async {
    final sub = queue.directory;
    if (!sub.existsSync()) return true;
    var complete = true;
    for (final file in sub.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (name == '.owner.json') {
        await file.delete();
        continue;
      }
      final target = File('${_directory.path}/$name');
      if (target.existsSync()) {
        complete = false;
        continue;
      }
      await file.rename(target.path);
    }
    if (complete) await sub.delete(recursive: true);
    return complete;
  }
```

Then make `owner()` use the shared reader so the two never diverge, keeping its `unattributableOwner` behaviour for the root:

```dart
  Future<String?> owner() async {
    if (!_ownerFile.existsSync()) return null;
    return _readOwnerFile(_ownerFile) ?? unattributableOwner;
  }
```

Check the existing `owner()` tests still pass — in particular "an unreadable owner file reads as unattributable" and "owner file names no account". If the second relied on a specific `debugPrint` text, keep that text.

- [ ] **Step 4: Run and watch them pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transaction_outbox_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/data/transaction_outbox.dart \
        test/features/transactions/transaction_outbox_test.dart
git commit -m "feat(transactions): the outbox can list and restore what it set aside"
```

---

### Task 3: reclaiming, after a claim

**Files:**
- Modify: `lib/features/transactions/data/outbox_ownership.dart`
- Test: `test/features/transactions/outbox_ownership_test.dart`

**Interfaces:**
- Consumes: `sidelinedQueues()`, `restore()`, `SidelinedQueue` (Task 2); `_claimChains`, `_resolveOwnership` (exist).
- Produces: `Future<int> reclaimSidelined(TransactionOutbox outbox, String? accountKey)` — how many queues came back. Task 4 calls it.

- [ ] **Step 1: Write the failing tests**

In `test/features/transactions/outbox_ownership_test.dart`:

```dart
  group('reclaimSidelined', () {
    Future<void> sidelineAs(String owner, List<String> ids) async {
      for (final id in ids) {
        await queue(id);
      }
      await outbox.setOwner(owner);
      await outbox.sideline();
    }

    test('brings back a queue this account set aside, into its own root',
        () async {
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
    test('does nothing into an unowned root that still holds entries',
        () async {
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

    test('leaves another account\'s sidelined queue alone', () async {
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
    test('a claim reclaims the new owner\'s sidelined queue', () async {
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
```

Match `outbox`, `queue(...)` to the file's fixtures.

- [ ] **Step 2: Run them and watch them fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/outbox_ownership_test.dart`
Expected: FAIL — `reclaimSidelined` undefined.

- [ ] **Step 3: Add `reclaimSidelined` and call it after a claim**

In `lib/features/transactions/data/outbox_ownership.dart`, after `claimForWriting`:

```dart
/// Brings back every queue [TransactionOutbox.sideline] set aside for
/// [accountKey], when the root is that account's to fill.
///
/// The foreign-queue sheet promises that signing back in, or correcting a
/// mistyped server address, brings a set-aside queue back. That is only
/// true if something reads the sidelined directories, and this is it.
///
/// "That account's to fill" is the whole rule, and it is narrow on
/// purpose: the root must already be ours, or empty with no owner. Never
/// into a queue somebody else owns -- the sheet handles that root, and the
/// next write reclaims once it is resolved. Never into an unowned root
/// that still holds entries -- that is the upgrade case, and the sheet
/// owns it too. A sidelined queue with no readable owner is never
/// reclaimed by anyone.
///
/// Returns how many queues came back. Serialized with [claimForWriting]
/// on the same chain: both move files, and interleaving a restore with a
/// sideline could move an entry twice or drop it.
Future<int> reclaimSidelined(
  TransactionOutbox outbox,
  String? accountKey,
) {
  final previous = (_claimChains[outbox] ?? Future<void>.value())
      .catchError((_) {});
  final resolved = previous.then((_) => _reclaim(outbox, accountKey));
  _claimChains[outbox] = resolved.then((_) {}).catchError((_) {});
  return resolved;
}

Future<int> _reclaim(TransactionOutbox outbox, String? accountKey) async {
  if (accountKey == null) return 0;
  final owner = await outbox.owner();
  final rootIsOurs = owner == accountKey;
  final rootIsFree = owner == null && (await outbox.all()).isEmpty;
  if (!rootIsOurs && !rootIsFree) return 0;

  var restored = 0;
  for (final queue in await outbox.sidelinedQueues()) {
    if (queue.owner != accountKey) continue;
    if (await outbox.restore(queue)) restored++;
  }
  if (restored > 0 && rootIsFree) await outbox.setOwner(accountKey);
  return restored;
}
```

Then in `_resolveOwnership`, after the claim:

```dart
  await outbox.sideline();
  await outbox.setOwner(accountKey);
  // The root is now ours and empty: if this account had a queue set aside
  // earlier, this is the moment it comes back. Direct, not through
  // reclaimSidelined -- we are already on the chain.
  await _reclaim(outbox, accountKey);
```

Note the direct `_reclaim` call: `_resolveOwnership` already runs on the chain, and calling `reclaimSidelined` from inside it would chain on itself and deadlock.

`_reclaim` calls `outbox.all()` — that is inside `outbox_ownership.dart`, which is allow-listed by the structural guard. Do not move it elsewhere.

- [ ] **Step 4: Run and watch them pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/data/outbox_ownership.dart \
        test/features/transactions/outbox_ownership_test.dart
git commit -m "feat(transactions): a claim brings back what this account set aside"
```

---

### Task 4: reclaiming, at sign-in

**Files:**
- Modify: `lib/features/transactions/ui/outbox_claim_prompt.dart`
- Test: `test/features/transactions/outbox_claim_prompt_test.dart`, `test/screens/shell_screen_test.dart`

**Interfaces:**
- Consumes: `reclaimSidelined` (Task 3), `drainOutbox` (exists).
- Produces: no new API.

- [ ] **Step 1: Write the failing tests**

In `test/features/transactions/outbox_claim_prompt_test.dart`, using that file's `pumpHost`/`queue`/`outbox` fixtures:

```dart
  testWidgets('a returning account gets its set-aside queue back without '
      'saving anything, and nothing is asked', (tester) async {
    // Account 2 wrote while account 1's queue was current, so 1's queue
    // was set aside. Now 2 has signed out and 1 is back: the root is 2's,
    // empty after 2's own sign-out cleared it.
    await queue('one-1');
    await outbox.setOwner(keyFor(1));
    await outbox.sideline();
    // Sign-out of account 2 leaves an empty, unowned root.

    final sync = _RecordingSync();
    await pumpHost(tester, accountKey: keyFor(1), sync: sync);

    expect(find.byType(Dialog), findsNothing);
    expect(find.textContaining('another account'), findsNothing);
    expect((await ownedEntries(outbox, keyFor(1))).single.localId, 'one-1');
    expect(sync.drains, greaterThan(0),
        reason: 'the app-start drain already ran; this has to send');
  });

  testWidgets('a set-aside queue is not reclaimed into a root another '
      'account still owns, and that root is asked about', (tester) async {
    await queue('one-1');
    await outbox.setOwner(keyFor(1));
    await outbox.sideline();
    await queue('two-1');
    await outbox.setOwner(keyFor(2));

    await pumpHost(tester, accountKey: keyFor(1));

    expect(find.textContaining('another account'), findsOneWidget);
    expect(await ownedEntries(outbox, keyFor(1)), isEmpty);
    expect(await outbox.sidelinedQueues(), hasLength(1));
  });
```

`pumpHost` needs to accept a `sync` override for `transactionSyncProvider`; if it does not, add it the way `transactions_screen_test.dart`'s `pumpScreen` takes one. `_RecordingSync` exists in several test files — copy the one from `test/screens/shell_screen_test.dart`, including its `drainAgain`.

- [ ] **Step 2: Run them and watch them fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/outbox_claim_prompt_test.dart`
Expected: FAIL — the first finds `ownedEntries` empty and `drains == 0`.

- [ ] **Step 3: Reclaim before deciding what to ask**

In `lib/features/transactions/ui/outbox_claim_prompt.dart`, in `promptForForeignOutbox`, after the `accountKey == null` return and before `claimStateOf`:

```dart
  // Before deciding what to ask: if this account's own queue was set aside
  // by somebody else's write and the root is free again, it comes back
  // now -- which is what makes "correcting the server address brings them
  // back" true without the user having to save something first. The
  // app-start drain has already run, so a reclaimed queue has to be sent
  // from here.
  if (await reclaimSidelined(outbox, accountKey) > 0) drainOutbox(ref);
```

- [ ] **Step 4: Run and watch them pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/ test/screens/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/ui/outbox_claim_prompt.dart \
        test/features/transactions/outbox_claim_prompt_test.dart
git commit -m "feat(transactions): signing back in brings a set-aside queue back"
```

---

### Task 5: four chores

**Files:**
- Modify: `test/features/transactions/transaction_dialog_test.dart:747-761`
- Modify: `lib/l10n/app_en.arb`, `app_de.arb`, `app_it.arb` (`logoutPendingBody`)
- Modify: `test/features/user/settings_screen_test.dart:311`
- Modify: `lib/features/transactions/ui/transactions_controller.dart:352-358`
- Modify: `lib/features/transactions/ui/outbox_claim_prompt.dart:52` (comment)
- Modify: `docs/superpowers/specs/2026-09-04-outbox-ownership-design.md`

**Interfaces:** none.

- [ ] **Step 1: The latent flake**

In `test/features/transactions/transaction_dialog_test.dart`, replace the `runAsync` block at lines 747-761:

```dart
      await tester.runAsync(() async {
        await tester.tap(saveButton);
        // Not "until the entry hits disk": the save sheet is still up
        // then, with its spinner running, and a pumpAndSettle after
        // runAsync can never settle a spinner it cannot see the end of.
        // Wait for the sheet itself to close -- no spinner, no Save
        // button -- which is the moment the save chain is really done.
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
            find.widgetWithText(FilledButton, 'Save').evaluate().isNotEmpty) {
          if (DateTime.now().isAfter(deadline)) {
            fail('timed out waiting for the save sheet to close');
          }
          await tester.pump(const Duration(milliseconds: 10));
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();
```

Run that file five times in a row and confirm it passes every time:
`export PATH="$HOME/flutter/bin:$PATH" && for i in 1 2 3 4 5; do flutter test --coverage test/features/transactions/transaction_dialog_test.dart | tail -1; done`

- [ ] **Step 2: The ICU plural**

`lib/l10n/app_en.arb`:

```json
  "logoutPendingBody": "{count, plural, =1{1 transaction has not reached the server. Signing out will discard it.} other{{count} transactions have not reached the server. Signing out will discard them.}}",
```

`lib/l10n/app_de.arb`:

```json
  "logoutPendingBody": "{count, plural, =1{1 Buchung hat den Server nicht erreicht. Beim Abmelden geht sie verloren.} other{{count} Buchungen haben den Server nicht erreicht. Beim Abmelden gehen sie verloren.}}",
```

`lib/l10n/app_it.arb`:

```json
  "logoutPendingBody": "{count, plural, =1{1 movimento non ha raggiunto il server. Uscendo andrà perso.} other{{count} movimenti non hanno raggiunto il server. Uscendo andranno persi.}}",
```

The `@logoutPendingBody` placeholder block stays as it is. Run `flutter gen-l10n`.

In `test/features/user/settings_screen_test.dart:311`, the assertion `find.textContaining('1')` matched any "1" on the screen. Replace it with the rendered singular:

```dart
      expect(
        find.textContaining('1 transaction has not reached the server'),
        findsOneWidget,
      );
```

Add a sibling that queues two entries and asserts `'2 transactions have not reached'`, so the plural branch is pinned too.

- [ ] **Step 3: The falsified comment and its dead call**

In `lib/features/transactions/ui/transactions_controller.dart`, in `delete`'s `on NetworkException` branch, delete the comment block and the `await claimForWriting(...)` line at 352-358, leaving the `await _enqueue(` that follows. `_enqueue` resolves ownership itself; nothing that lookup could find is changed by a claim any more.

Run `flutter test test/features/transactions/` — the reviewer who found this confirmed all transaction tests stay green without the call; confirm that yourself.

In `lib/features/transactions/ui/outbox_claim_prompt.dart:52`, the doc says adopting is "`setOwner` or nothing at all". Change it to say adopting is `setOwner` followed by a drain, and declining is nothing at all.

- [ ] **Step 4: The stale spec**

In `docs/superpowers/specs/2026-09-04-outbox-ownership-design.md`, add a blockquote under the "Reading: one door in" section noting that `claimIfUnowned` was superseded by `claimForWriting` during execution and removed, and one under the string table noting that the Italian was corrected from *operazioni* to *movimenti* by the final review, with a pointer to `app_it.arb` as the authority. Match the style the error-display spec used for its own superseded strings.

- [ ] **Step 5: Run the affected suites**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/ test/features/user/ test/l10n/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add test/features/transactions/transaction_dialog_test.dart \
        lib/l10n/ test/features/user/settings_screen_test.dart \
        lib/features/transactions/ui/transactions_controller.dart \
        lib/features/transactions/ui/outbox_claim_prompt.dart \
        docs/superpowers/specs/2026-09-04-outbox-ownership-design.md
git commit -m "chore: four follow-ups from the ownership branch"
```

---

### Task 6: the whole gate

**Files:** none — this task only runs and reports.

- [ ] **Step 1: Regenerate**

Run: `export PATH="$HOME/flutter/bin:$PATH" && dart run build_runner build && flutter gen-l10n`

Commit any churn on its own: `git add -A lib/ && git commit -m "chore: regenerate" || echo "nothing to regenerate"`

- [ ] **Step 2: Run the full gate, three times**

```bash
export PATH="$HOME/flutter/bin:$PATH"
flutter analyze
dart format --output=none --set-exit-if-changed lib test integration_test tool
for i in 1 2 3; do flutter test --coverage | tail -1; done
dart run tool/check_coverage.dart 80
```

Expected: all clean, three consecutive full runs green. One clean run proved nothing about this suite last time; three is the bar. Report the final test count and coverage.
