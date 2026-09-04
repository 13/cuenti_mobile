# Offline-Safe Transactions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A transaction saved without a connection is queued on the device, shown in the list as not-yet-sent, and delivered when the connection returns.

**Architecture:** An explicit outbox — `TransactionOutbox` persists queued writes as JSON files in the app-support directory; `TransactionSync` drains them oldest-first; `TransactionsController` decides on save whether the write went to the server or the queue, and merges the queue into the list it hands the UI.

**Tech Stack:** Flutter, Riverpod (codegen via `riverpod_annotation`), freezed + json_serializable, Dio, `flutter_test` + `mocktail`.

**Spec:** `docs/superpowers/specs/2026-09-04-offline-transactions-design.md`

## Global Constraints

- **Scope is transactions only.** Never queue a category, payee, account, budget or scheduled write.
- **Offline is `e is NetworkException`.** Repositories run every call through `guardApi`, which maps connection/timeout Dio types to `NetworkException`. Never re-inspect `DioExceptionType` outside `api_exception.dart`.
- **A server rejection is never queued at save time.** The server answered; fail as today.
- **Account balances are never adjusted locally.**
- **Nothing entered is discarded without the user seeing it.** This governs rejection handling and logout.
- **Storage lives in `getApplicationSupportDirectory()`**, one JSON file per entry, mirroring `ResponseCache`.
- Every new user-facing string goes in `lib/l10n/app_en.arb`, `app_de.arb` and `app_it.arb`; run `flutter gen-l10n`. `test/l10n/translations_test.dart` enforces parity and will fail otherwise.
- After any change touching a `@freezed` or `@riverpod` file, run `dart run build_runner build --delete-conflicting-outputs`. CI fails on stale generated output.
- Run with `export PATH="$HOME/flutter/bin:$PATH"`. Full gate: `flutter analyze`, `dart format --output=none --set-exit-if-changed lib test integration_test tool`, `flutter test`, `dart run tool/check_coverage.dart 80`.

---

## File Structure

| File | Responsibility |
|---|---|
| `lib/features/transactions/domain/pending_transaction.dart` | The queued-write model: operation, transaction, local id, rejection |
| `lib/features/transactions/data/transaction_outbox.dart` | Durable storage of pending writes + its provider |
| `lib/features/transactions/data/transaction_sync.dart` | Draining the outbox against the repository + its provider |
| `lib/features/transactions/ui/transactions_controller.dart` | Routes saves to server-or-queue; merges pending into the list |
| `lib/features/transactions/ui/widgets/transaction_list_parts.dart` | The not-sent mark and the rejected row |
| `lib/screens/shell_screen.dart` | Sync on connection returning; logout confirmation |
| `lib/features/transactions/ui/transaction_dialog.dart` | Hide category/payee create rows while offline |

---

### Task 1: The pending-write model

**Files:**
- Create: `lib/features/transactions/domain/pending_transaction.dart`
- Test: `test/features/transactions/pending_transaction_test.dart`

**Interfaces:**
- Consumes: `Transaction` from `lib/features/transactions/domain/transaction.dart`
- Produces: `enum PendingOperation { create, update, delete }`; `class PendingTransaction` with fields `String localId`, `PendingOperation operation`, `Transaction transaction`, `DateTime queuedAt`, `String? rejection`; `PendingTransaction.fromJson(Map<String, dynamic>)`, `.toJson()`, `.copyWith(...)`; getter `bool get isRejected`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/transactions/pending_transaction_test.dart
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final entry = PendingTransaction(
    localId: 'abc',
    operation: PendingOperation.create,
    transaction: Transaction(amount: 12.34, transactionDate: DateTime(2026, 9, 4)),
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

  test('a rejection survives it too, or the reason would be lost on restart',
      () {
    final refused = entry.copyWith(rejection: 'Account is closed');

    expect(PendingTransaction.fromJson(refused.toJson()).rejection,
        'Account is closed');
    expect(refused.isRejected, isTrue);
    expect(entry.isRejected, isFalse);
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/pending_transaction_test.dart`
Expected: FAIL — `Error when reading 'lib/features/transactions/domain/pending_transaction.dart': No such file`

- [ ] **Step 3: Write the model**

```dart
// lib/features/transactions/domain/pending_transaction.dart
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_transaction.freezed.dart';
part 'pending_transaction.g.dart';

/// Which write is waiting to be sent.
enum PendingOperation { create, update, delete }

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
    required Transaction transaction,
    required DateTime queuedAt,

    /// The server's own words, once it has refused this entry. Null while
    /// the entry is merely waiting.
    String? rejection,
  }) = _PendingTransaction;

  const PendingTransaction._();

  factory PendingTransaction.fromJson(Map<String, dynamic> json) =>
      _$PendingTransactionFromJson(json);

  bool get isRejected => rejection != null;
}
```

- [ ] **Step 4: Generate and run**

Run: `export PATH="$HOME/flutter/bin:$PATH" && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/transactions/pending_transaction_test.dart`
Expected: PASS, 2 tests

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/domain/pending_transaction.dart \
        lib/features/transactions/domain/pending_transaction.freezed.dart \
        lib/features/transactions/domain/pending_transaction.g.dart \
        test/features/transactions/pending_transaction_test.dart
git commit -m "feat(transactions): a model for a write the server has not seen"
```

---

### Task 2: The outbox

**Files:**
- Create: `lib/features/transactions/data/transaction_outbox.dart`
- Test: `test/features/transactions/transaction_outbox_test.dart`

**Interfaces:**
- Consumes: `PendingTransaction`, `PendingOperation` from Task 1.
- Produces: `class TransactionOutbox` with `TransactionOutbox(Directory directory)`, `static Future<TransactionOutbox> open()`, `Future<void> add(PendingTransaction)`, `Future<List<PendingTransaction>> all()` (oldest `queuedAt` first), `Future<void> remove(String localId)`, `Future<void> replace(PendingTransaction)`, `Future<void> markRejected(String localId, String reason)`, `Future<void> clear()`. Also `final transactionOutboxProvider = Provider<TransactionOutbox>((ref) => throw UnimplementedError())` — overridden at app start, the way a repository provider is wired.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/transactions/transaction_outbox_test.dart
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
        transaction:
            Transaction(amount: 1, transactionDate: DateTime(2026, 9, 4)),
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

    await outbox.replace(entry('a').copyWith(
      transaction: Transaction(amount: 99, transactionDate: DateTime(2026, 9, 4)),
    ));

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
```

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transaction_outbox_test.dart`
Expected: FAIL — `No such file or directory` for `transaction_outbox.dart`

- [ ] **Step 3: Write the outbox**

```dart
// lib/features/transactions/data/transaction_outbox.dart
import 'dart:convert';
import 'dart:io';

import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Transaction writes the server has not accepted yet, kept on disk.
///
/// One JSON file per entry in the app-support directory -- the same store
/// ResponseCache uses, and for the same reason: the OS does not purge it
/// behind the app's back the way it may purge temp. Unlike that cache, what
/// is in here is work the user did and nothing else has a copy of.
class TransactionOutbox {
  TransactionOutbox(this._directory);

  static Future<TransactionOutbox> open() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/transaction_outbox');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return TransactionOutbox(dir);
  }

  final Directory _directory;

  File _fileFor(String localId) => File('${_directory.path}/$localId.json');

  Future<void> add(PendingTransaction entry) async =>
      _fileFor(entry.localId).writeAsString(jsonEncode(entry.toJson()));

  /// Oldest first, so entries send in the order they were made.
  Future<List<PendingTransaction>> all() async {
    if (!_directory.existsSync()) return [];
    final entries = <PendingTransaction>[];
    for (final file in _directory.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      try {
        entries.add(
          PendingTransaction.fromJson(
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
          ),
        );
        // One unreadable file must not cost the user every other entry
        // behind it, so it is skipped rather than thrown.
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {
        continue;
      }
    }
    entries.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    return entries;
  }

  Future<void> remove(String localId) async {
    final file = _fileFor(localId);
    if (file.existsSync()) await file.delete();
  }

  Future<void> replace(PendingTransaction entry) => add(entry);

  Future<void> markRejected(String localId, String reason) async {
    final entry = (await all()).where((e) => e.localId == localId).firstOrNull;
    if (entry == null) return;
    await replace(entry.copyWith(rejection: reason));
  }

  Future<void> clear() async {
    if (!_directory.existsSync()) return;
    await _directory.delete(recursive: true);
    await _directory.create(recursive: true);
  }
}

/// Overridden at app start with [TransactionOutbox.open], the way the API
/// client is: opening it needs an await that a provider cannot do inline.
final transactionOutboxProvider = Provider<TransactionOutbox>(
  (ref) => throw UnimplementedError('transactionOutboxProvider not overridden'),
);
```

- [ ] **Step 4: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transaction_outbox_test.dart`
Expected: PASS, 8 tests

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/data/transaction_outbox.dart \
        test/features/transactions/transaction_outbox_test.dart
git commit -m "feat(transactions): a durable outbox for writes made offline"
```

---

### Task 3: Draining the outbox

**Files:**
- Create: `lib/features/transactions/data/transaction_sync.dart`
- Test: `test/features/transactions/transaction_sync_test.dart`

**Interfaces:**
- Consumes: `TransactionOutbox` and `transactionOutboxProvider` (Task 2); `PendingTransaction`, `PendingOperation` (Task 1); `TransactionsRepository` with `Future<Transaction> save(Transaction, {bool splitsTouched})` and `Future<void> delete(int id)`; `NetworkException` from `lib/core/api/api_exception.dart`.
- Produces: `class TransactionSync` with `TransactionSync(TransactionOutbox outbox, TransactionsRepository repository)` and `Future<int> drain()` returning how many entries were delivered. `final transactionSyncProvider = Provider<TransactionSync>(...)`.

- [ ] **Step 1: Write the failing test**

```dart
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

  setUpAll(() => registerFallbackValue(
        Transaction(amount: 0, transactionDate: DateTime(2026)),
      ));

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
  }) =>
      outbox.add(
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
    when(() => repo.save(any(), splitsTouched: any(named: 'splitsTouched')))
        .thenAnswer((i) async => i.positionalArguments.first as Transaction);
    await queue('a');

    expect(await sync.drain(), 1);
    expect(await outbox.all(), isEmpty);
  });

  test('a delete entry is sent as a delete', () async {
    when(() => repo.delete(any())).thenAnswer((_) async {});
    await queue('a', operation: PendingOperation.delete, transactionId: 7);

    await sync.drain();

    verify(() => repo.delete(7)).called(1);
  });

  test('still offline stops the run and keeps everything queued', () async {
    when(() => repo.save(any(), splitsTouched: any(named: 'splitsTouched')))
        .thenThrow(const NetworkException('Cannot connect to server'));
    await queue('a');
    await queue('b', minute: 1);

    expect(await sync.drain(), 0);
    expect(await outbox.all(), hasLength(2));
  });

  test('a refusal marks that entry and the run carries on to the next: one '
      'bad entry must not hold up the rest', () async {
    var calls = 0;
    when(() => repo.save(any(), splitsTouched: any(named: 'splitsTouched')))
        .thenAnswer((i) async {
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
    when(() => repo.save(any(), splitsTouched: any(named: 'splitsTouched')))
        .thenAnswer((i) async => i.positionalArguments.first as Transaction);
    await outbox.add(
      PendingTransaction(
        localId: 'refused',
        operation: PendingOperation.create,
        transaction:
            Transaction(amount: 1, transactionDate: DateTime(2026, 9, 4)),
        queuedAt: DateTime(2026, 9, 4, 10),
        rejection: 'Account is closed',
      ),
    );

    expect(await sync.drain(), 0);
    verifyNever(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    );
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transaction_sync_test.dart`
Expected: FAIL — `No such file or directory` for `transaction_sync.dart`

- [ ] **Step 3: Write the sync**

```dart
// lib/features/transactions/data/transaction_sync.dart
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sends what the outbox is holding, oldest first.
class TransactionSync {
  TransactionSync(this._outbox, this._repository);

  final TransactionOutbox _outbox;
  final TransactionsRepository _repository;

  /// Returns how many entries reached the server.
  ///
  /// A [NetworkException] ends the run: the connection is still down, and
  /// walking the rest of the queue would only collect the same failure. Any
  /// other ApiException means the server answered and refused, so that one
  /// entry is marked with its reason and the run continues -- one bad entry
  /// must not hold up everything queued behind it.
  ///
  /// An entry already carrying a rejection is left alone. It is waiting for
  /// a person to fix or discard it, and retrying it would overwrite the
  /// reason they have not read yet.
  Future<int> drain() async {
    var delivered = 0;
    for (final entry in await _outbox.all()) {
      if (entry.isRejected) continue;
      try {
        await _send(entry);
        await _outbox.remove(entry.localId);
        delivered++;
      } on NetworkException catch (_) {
        return delivered;
      } on ApiException catch (e) {
        await _outbox.markRejected(entry.localId, e.message);
      }
    }
    return delivered;
  }

  Future<void> _send(PendingTransaction entry) async {
    switch (entry.operation) {
      case PendingOperation.create:
      case PendingOperation.update:
        await _repository.save(entry.transaction, splitsTouched: true);
      case PendingOperation.delete:
        await _repository.delete(entry.transaction.id!);
    }
  }
}

final transactionSyncProvider = Provider<TransactionSync>(
  (ref) => TransactionSync(
    ref.watch(transactionOutboxProvider),
    ref.watch(transactionsRepositoryProvider),
  ),
);
```

- [ ] **Step 4: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transaction_sync_test.dart`
Expected: PASS, 5 tests

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/data/transaction_sync.dart \
        test/features/transactions/transaction_sync_test.dart
git commit -m "feat(transactions): drain the outbox, telling offline from refused"
```

---

### Task 4: Saving offline queues instead of failing

**Files:**
- Modify: `lib/features/transactions/ui/transactions_controller.dart`
- Test: `test/features/transactions/transactions_controller_test.dart`

**Interfaces:**
- Consumes: `TransactionOutbox`, `transactionOutboxProvider` (Task 2); `PendingTransaction`, `PendingOperation` (Task 1).
- Produces: `enum SaveOutcome { sent, queued }`; `TransactionsController.save` returns `Future<SaveOutcome>` (was `Future<void>`); `TransactionsController.delete` returns `Future<SaveOutcome>`.

Note for the implementer: `save` currently returns `Future<void>`. Widening it to return a value does not break callers that ignore the result — `transaction_dialog.dart` awaits it and does not read it, and stays compiling untouched. It is read in Task 6.

- [ ] **Step 1: Write the failing test** (append inside the existing `main()`)

```dart
  group('saving without a connection', () {
    late Directory outboxDir;

    setUp(() {
      outboxDir = Directory.systemTemp.createTempSync('ctrl_outbox');
    });
    tearDown(() => outboxDir.deleteSync(recursive: true));

    ProviderContainer containerWithOutbox() {
      final container = ProviderContainer(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(repo),
          transactionOutboxProvider
              .overrideWithValue(TransactionOutbox(outboxDir)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('a connection failure queues the transaction and says so', () async {
      when(() => repo.save(any(), splitsTouched: any(named: 'splitsTouched')))
          .thenThrow(const NetworkException('Cannot connect to server'));
      final container = containerWithOutbox();
      await container.read(transactionsControllerProvider().future);

      final outcome = await container
          .read(transactionsControllerProvider().notifier)
          .save(Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)));

      expect(outcome, SaveOutcome.queued);
      final queued =
          await container.read(transactionOutboxProvider).all();
      expect(queued.single.transaction.amount, 5);
      expect(queued.single.operation, PendingOperation.create);
    });

    test('a server refusal is not queued: the server answered, so deferring '
        'the bad news helps nobody', () async {
      when(() => repo.save(any(), splitsTouched: any(named: 'splitsTouched')))
          .thenThrow(const ValidationException('Amount is required'));
      final container = containerWithOutbox();
      await container.read(transactionsControllerProvider().future);

      await expectLater(
        container
            .read(transactionsControllerProvider().notifier)
            .save(Transaction(amount: 0, transactionDate: DateTime(2026, 9, 4))),
        throwsA(isA<ValidationException>()),
      );
      expect(await container.read(transactionOutboxProvider).all(), isEmpty);
    });

    test('a successful save queues nothing', () async {
      when(() => repo.save(any(), splitsTouched: any(named: 'splitsTouched')))
          .thenAnswer((i) async => i.positionalArguments.first as Transaction);
      final container = containerWithOutbox();
      await container.read(transactionsControllerProvider().future);

      final outcome = await container
          .read(transactionsControllerProvider().notifier)
          .save(Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)));

      expect(outcome, SaveOutcome.sent);
      expect(await container.read(transactionOutboxProvider).all(), isEmpty);
    });

    test('editing something still queued rewrites that entry rather than '
        'queueing an update against a transaction the server never saw',
        () async {
      when(() => repo.save(any(), splitsTouched: any(named: 'splitsTouched')))
          .thenThrow(const NetworkException('Cannot connect to server'));
      final container = containerWithOutbox();
      await container.read(transactionsControllerProvider().future);
      final notifier =
          container.read(transactionsControllerProvider().notifier);

      await notifier
          .save(Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)));
      final localId =
          (await container.read(transactionOutboxProvider).all()).single.localId;
      await notifier.save(
        Transaction(amount: 9, transactionDate: DateTime(2026, 9, 4)),
        localId: localId,
      );

      final queued = await container.read(transactionOutboxProvider).all();
      expect(queued, hasLength(1));
      expect(queued.single.transaction.amount, 9);
      expect(queued.single.operation, PendingOperation.create);
    });
  });
```

Add these imports to the top of the test file:

```dart
import 'dart:io';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
```

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transactions_controller_test.dart`
Expected: FAIL — `Undefined name 'SaveOutcome'` and `transactionOutboxProvider` not overridden

- [ ] **Step 3: Route the save**

Replace `TransactionsController.save` and `delete` with:

```dart
  /// Whether a write reached the server or is waiting on the device.
  Future<SaveOutcome> save(
    Transaction t, {
    bool splitsTouched = false,
    String? localId,
  }) async {
    try {
      await ref
          .read(transactionsRepositoryProvider)
          .save(t, splitsTouched: splitsTouched);
      if (localId != null) {
        await ref.read(transactionOutboxProvider).remove(localId);
      }
      ref
        ..invalidateSelf()
        // Balances changed server-side:
        ..invalidate(accountsControllerProvider);
      await future;
      return SaveOutcome.sent;
      // Only a connection failure is queued. Anything else means the server
      // answered and refused, and holding a refusal back until later just
      // delivers the bad news when the entry has been forgotten.
    } on NetworkException catch (_) {
      await _enqueue(t, localId: localId);
      ref.invalidateSelf();
      await future;
      return SaveOutcome.queued;
    }
  }

  /// The queued entry already standing for the server transaction [id], if
  /// there is one. Passing it to [_enqueue] replaces that entry rather than
  /// leaving an update and a delete both waiting for the same row.
  String? _queuedIdFor(int id) => state.value?.pending
      .where((e) => e.transaction.id == id)
      .firstOrNull
      ?.localId;

  /// Puts a write in the outbox, replacing the entry it came from so that
  /// editing something queued never leaves two entries for one transaction.
  Future<void> _enqueue(
    Transaction t, {
    String? localId,
    PendingOperation? operation,
  }) async {
    final outbox = ref.read(transactionOutboxProvider);
    final existing = localId == null
        ? null
        : (await outbox.all()).where((e) => e.localId == localId).firstOrNull;
    final entry = PendingTransaction(
      localId: localId ?? 'local-${DateTime.now().microsecondsSinceEpoch}',
      // An edit of something never sent is still a create: the server has
      // nothing to update.
      operation: operation ??
          existing?.operation ??
          (t.id == null ? PendingOperation.create : PendingOperation.update),
      transaction: t,
      queuedAt: existing?.queuedAt ?? DateTime.now(),
    );
    await outbox.add(entry);
  }

  Future<SaveOutcome> delete(int id) async {
    final current = state.value;
    if (current == null) return SaveOutcome.sent;
    state = AsyncData(
      current.copyWith(items: current.items.where((t) => t.id != id).toList()),
    );
    try {
      await ref.read(transactionsRepositoryProvider).delete(id);
      ref
        ..invalidateSelf()
        ..invalidate(accountsControllerProvider);
      return SaveOutcome.sent;
    } on NetworkException catch (_) {
      await _enqueue(
        current.items
            .firstWhere(
              (t) => t.id == id,
              orElse: () =>
                  Transaction(amount: 0, transactionDate: DateTime.now()),
            )
            .copyWith(id: id),
        // A delete supersedes any edit of the same row already queued: the
        // outbox is keyed by localId, and _enqueue replaces in place.
        localId: _queuedIdFor(id),
        operation: PendingOperation.delete,
      );
      return SaveOutcome.queued;
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
```

Add above the class:

```dart
/// Whether a write reached the server or is waiting on the device.
enum SaveOutcome { sent, queued }
```

and these imports:

```dart
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
```

- [ ] **Step 4: Generate, run**

Run: `export PATH="$HOME/flutter/bin:$PATH" && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/transactions/transactions_controller_test.dart`
Expected: PASS, including the 4 new tests

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/ui/transactions_controller.dart \
        lib/features/transactions/ui/transactions_controller.g.dart \
        test/features/transactions/transactions_controller_test.dart
git commit -m "feat(transactions): queue a save the connection could not carry"
```

---

### Task 5: Pending entries in the list

**Files:**
- Modify: `lib/features/transactions/ui/transactions_controller.dart`
- Test: `test/features/transactions/transactions_controller_test.dart`

**Interfaces:**
- Consumes: everything from Task 4.
- Produces: `TransactionsState` gains `@Default([]) List<PendingTransaction> pending`; the `items` the UI reads already have pending creates merged in, pending updates overlaid, and pending deletes removed.

- [ ] **Step 1: Write the failing test** (append inside the same group)

```dart
    test('a queued create appears in the list, in date order', () async {
      when(() => repo.save(any(), splitsTouched: any(named: 'splitsTouched')))
          .thenThrow(const NetworkException('Cannot connect to server'));
      when(() => repo.getPage(
            page: any(named: 'page'),
            size: any(named: 'size'),
            filter: any(named: 'filter'),
          )).thenAnswer(
        (_) async => TransactionPage(
          content: [
            Transaction(
              id: 1,
              amount: 10,
              transactionDate: DateTime(2026, 9, 1),
            ),
          ],
          page: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
        ),
      );
      final container = containerWithOutbox();
      await container.read(transactionsControllerProvider().future);

      await container
          .read(transactionsControllerProvider().notifier)
          .save(Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)));

      final state = container.read(transactionsControllerProvider()).value!;
      expect(state.items.map((t) => t.amount), [5, 10]);
      expect(state.pending, hasLength(1));
    });

    test('deleting a row that already has an edit queued replaces it, so '
        'the server is not sent an update and then a delete', () async {
      when(() => repo.save(any(), splitsTouched: any(named: 'splitsTouched')))
          .thenThrow(const NetworkException('Cannot connect to server'));
      when(() => repo.delete(any()))
          .thenThrow(const NetworkException('Cannot connect to server'));
      when(() => repo.getPage(
            page: any(named: 'page'),
            size: any(named: 'size'),
            filter: any(named: 'filter'),
          )).thenAnswer(
        (_) async => TransactionPage(
          content: [
            Transaction(
              id: 1,
              amount: 10,
              transactionDate: DateTime(2026, 9, 1),
            ),
          ],
          page: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
        ),
      );
      final container = containerWithOutbox();
      await container.read(transactionsControllerProvider().future);
      final notifier =
          container.read(transactionsControllerProvider().notifier);

      await notifier.save(
        Transaction(id: 1, amount: 99, transactionDate: DateTime(2026, 9, 1)),
      );
      await notifier.delete(1);

      final queued = await container.read(transactionOutboxProvider).all();
      expect(queued, hasLength(1));
      expect(queued.single.operation, PendingOperation.delete);
    });

    test('a queued delete hides the row it removes', () async {
      when(() => repo.delete(any()))
          .thenThrow(const NetworkException('Cannot connect to server'));
      when(() => repo.getPage(
            page: any(named: 'page'),
            size: any(named: 'size'),
            filter: any(named: 'filter'),
          )).thenAnswer(
        (_) async => TransactionPage(
          content: [
            Transaction(
              id: 1,
              amount: 10,
              transactionDate: DateTime(2026, 9, 1),
            ),
          ],
          page: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
        ),
      );
      final container = containerWithOutbox();
      await container.read(transactionsControllerProvider().future);

      await container.read(transactionsControllerProvider().notifier).delete(1);

      expect(
        container.read(transactionsControllerProvider()).value!.items,
        isEmpty,
      );
    });
```

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transactions_controller_test.dart`
Expected: FAIL — `state.pending` undefined; the queued create is absent from `items`

- [ ] **Step 3: Merge the queue into the list**

Add to `TransactionsState`:

```dart
    /// Writes the server has not taken yet. The [items] above already
    /// reflect them; this is here so the UI can mark the rows.
    @Default([]) List<PendingTransaction> pending,
```

Add to the controller, and call it wherever `state` is built from a page:

```dart
  /// Folds the outbox into a server page: queued creates take their place
  /// by date, queued updates replace the row they edit, and queued deletes
  /// take theirs away. Without this an entry made offline would vanish the
  /// moment it was saved, which reads as losing it.
  static List<Transaction> mergePending(
    List<Transaction> fromServer,
    List<PendingTransaction> pending,
  ) {
    final deleted = {
      for (final e in pending)
        if (e.operation == PendingOperation.delete) e.transaction.id,
    };
    final updates = {
      for (final e in pending)
        if (e.operation == PendingOperation.update) e.transaction.id!:
            e.transaction,
    };
    final merged = [
      for (final t in fromServer)
        if (!deleted.contains(t.id)) updates[t.id] ?? t,
      for (final e in pending)
        if (e.operation == PendingOperation.create) e.transaction,
    ]..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return merged;
  }
```

- [ ] **Step 4: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transactions_controller_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/ui/transactions_controller.dart \
        lib/features/transactions/ui/transactions_controller.freezed.dart \
        test/features/transactions/transactions_controller_test.dart
git commit -m "feat(transactions): show what is still waiting to be sent"
```

---

### Task 6: The pending and rejected marks

**Files:**
- Modify: `lib/features/transactions/ui/widgets/transaction_list_parts.dart`
- Modify: `lib/features/transactions/ui/transaction_dialog.dart`
- Modify: `lib/l10n/app_en.arb`, `app_de.arb`, `app_it.arb`
- Test: `test/features/transactions/transactions_screen_test.dart`

**Interfaces:**
- Consumes: `TransactionsState.pending` (Task 5), `SaveOutcome` (Task 4).
- Produces: no new public API; UI only.

New strings — add to all three catalogues and run `flutter gen-l10n`:

| Key | en | de | it |
|---|---|---|---|
| `txPendingNotSent` | Not sent yet | Noch nicht gesendet | Non ancora inviata |
| `txPendingRejected` | Refused: {reason} | Abgelehnt: {reason} | Rifiutata: {reason} |
| `txSavedOnDevice` | Saved on this device — it will send when there is a connection | Auf diesem Gerät gespeichert — wird gesendet, sobald eine Verbindung besteht | Salvata su questo dispositivo — verrà inviata quando ci sarà connessione |
| `txDiscardPending` | Discard | Verwerfen | Elimina |
| `txRetryPending` | Try again | Erneut versuchen | Riprova |

`txPendingRejected` needs `"@txPendingRejected": {"placeholders": {"reason": {"type": "String"}}}` in `app_en.arb`.

- [ ] **Step 1: Write the failing test**

Extend this file's `pumpScreen` to accept an outbox directory and override
`transactionOutboxProvider` with `TransactionOutbox(dir)`, then:

```dart
  group('what has not been sent', () {
    late Directory outboxDir;

    setUp(() => outboxDir = Directory.systemTemp.createTempSync('screen_ob'));
    tearDown(() => outboxDir.deleteSync(recursive: true));

    Future<void> queue({String? rejection}) => TransactionOutbox(outboxDir).add(
          PendingTransaction(
            localId: 'local-1',
            operation: PendingOperation.create,
            transaction: Transaction(
              amount: 12.34,
              transactionDate: DateTime(2026, 9, 4),
              payee: 'Aldi',
            ),
            queuedAt: DateTime(2026, 9, 4, 10),
            rejection: rejection,
          ),
        );

    testWidgets('a transaction that has not been sent says so', (tester) async {
      await queue();

      await pumpScreen(tester, outboxDir: outboxDir);

      expect(find.text('Aldi'), findsOneWidget);
      expect(find.text('Not sent yet'), findsOneWidget);
    });

    testWidgets('a refused one shows the reason, and offers to try again or '
        'discard it', (tester) async {
      await queue(rejection: 'Account is closed');

      await pumpScreen(tester, outboxDir: outboxDir);

      expect(find.textContaining('Account is closed'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('discarding removes it from the queue and the list', (
      tester,
    ) async {
      await queue(rejection: 'Account is closed');
      await pumpScreen(tester, outboxDir: outboxDir);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Aldi'), findsNothing);
      expect(await TransactionOutbox(outboxDir).all(), isEmpty);
    });
  });
```

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transactions_screen_test.dart`
Expected: FAIL — no such text

- [ ] **Step 3: Add the marks**

In the transaction row, when the row's id appears in `state.pending`, add beneath the memo line:

```dart
if (pendingFor(t) case final entry?)
  Row(
    children: [
      Icon(
        entry.isRejected ? Icons.error_outline : Icons.schedule_send,
        size: 14,
        color: entry.isRejected
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).textTheme.labelSmall?.color,
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          entry.isRejected
              ? L.of(context).txPendingRejected(entry.rejection!)
              : L.of(context).txPendingNotSent,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
      if (entry.isRejected) ...[
        TextButton(
          onPressed: () => onRetry(entry),
          child: Text(L.of(context).txRetryPending),
        ),
        TextButton(
          onPressed: () => onDiscard(entry),
          child: Text(L.of(context).txDiscardPending),
        ),
      ],
    ],
  ),
```

**Edit** is the row itself: tapping a pending row opens the transaction
dialog as any other row does. For an entry that has never reached the server
the dialog must carry its `localId` through to `save`, or saving the edit
would queue a second entry beside the first. Pass it from the row:

```dart
  onTap: () => showTransactionDialog(
    context,
    transaction: t,
    localId: pendingFor(t)?.localId,
  ),
```

In `transaction_dialog.dart`, read the outcome the save now returns:

```dart
final outcome = await ref
    .read(transactionsControllerProvider(filter: widget.filter).notifier)
    .save(transaction, splitsTouched: _splitsTouched);
if (!mounted) return;
showSuccessSnack(
  messenger,
  outcome == SaveOutcome.queued
      ? L.of(context).txSavedOnDevice
      : L.of(context).txSaved,
);
```

- [ ] **Step 4: Generate l10n, run**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter gen-l10n && flutter test test/features/transactions/ test/l10n/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/ui/ lib/l10n/ \
        test/features/transactions/transactions_screen_test.dart
git commit -m "feat(transactions): mark what has not been sent, and why one was refused"
```

---

### Task 7: Running the sync

**Files:**
- Modify: `lib/main.dart` (override `transactionOutboxProvider`)
- Modify: `lib/screens/shell_screen.dart` (drain when the connection returns)
- Test: `test/screens/shell_screen_test.dart`

**Interfaces:**
- Consumes: `TransactionSync.drain()` (Task 3), `TransactionOutbox.open()` (Task 2).
- Produces: no new API.

- [ ] **Step 1: Write the failing test**

```dart
class _RecordingSync implements TransactionSync {
  int drains = 0;

  @override
  Future<int> drain() async {
    drains++;
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

  testWidgets('the queue is sent when the connection comes back', (
    tester,
  ) async {
    final sync = _RecordingSync();
    final interceptor = OfflineCacheInterceptor(
      ResponseCache(Directory.systemTemp.createTempSync('shell_cache')),
    );
    await pumpShell(
      tester,
      overrides: [transactionSyncProvider.overrideWithValue(sync)],
      offlineCache: interceptor,
    );

    interceptor.stale.value = true;
    await tester.pump();
    final before = sync.drains;

    interceptor.stale.value = false;
    await tester.pumpAndSettle();

    expect(sync.drains, before + 1);
  });

  testWidgets('a connection that stays down does not drain on every frame', (
    tester,
  ) async {
    final sync = _RecordingSync();
    final interceptor = OfflineCacheInterceptor(
      ResponseCache(Directory.systemTemp.createTempSync('shell_cache2')),
    );
    await pumpShell(
      tester,
      overrides: [transactionSyncProvider.overrideWithValue(sync)],
      offlineCache: interceptor,
    );

    interceptor.stale.value = true;
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(sync.drains, 0);
  });
```

`pumpShell` needs two new optional parameters — `overrides` appended to the
`ProviderScope`, and `offlineCache` used in place of the real client's.

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/screens/shell_screen_test.dart`
Expected: FAIL — `drainCalls` is 0

- [ ] **Step 3: Open the outbox at start and drain on reconnect**

In `main()`, before `runApp`:

```dart
  final outbox = await TransactionOutbox.open();
  runApp(
    ProviderScope(
      overrides: [transactionOutboxProvider.overrideWithValue(outbox)],
      child: const CuentiApp(),
    ),
  );
```

In `ShellScreen.build`, alongside the existing `offlineCache` read:

```dart
    // The banner already knows when the connection came back; that edge is
    // the moment to send what was made while it was gone.
    if (offlineCache != null)
      ValueListenableBuilder<bool>(
        valueListenable: offlineCache.stale,
        builder: (context, stale, child) {
          if (!stale) {
            unawaited(ref.read(transactionSyncProvider).drain());
          }
          return child!;
        },
        child: const SizedBox.shrink(),
      ),
```

Also drain once at app start, from `CuentiApp.initState`:

```dart
    unawaited(ref.read(transactionSyncProvider).drain());
```

The spec names four triggers. The remaining two:

**A manual refresh.** In `invalidateAllData` (`lib/core/widgets/refresh_all.dart`),
pulling to refresh or tapping the refresh button should also try the queue —
that gesture means "get me up to date", and an unsent entry is part of that:

```dart
  unawaited(ref.read(transactionSyncProvider).drain());
```

Add `'transactionSyncProvider'` to the `deliberatelyOmitted` set in
`test/core/refresh_all_test.dart` if that structural test flags it — it is
not a data provider to invalidate, it is an action to run.

**From the row itself.** A rejected entry's row gets a retry alongside
Discard, which clears the rejection and drains again:

```dart
  Future<void> retry(PendingTransaction entry) async {
    await ref
        .read(transactionOutboxProvider)
        .replace(entry.copyWith(rejection: null));
    await ref.read(transactionSyncProvider).drain();
    ref.invalidateSelf();
  }
```

- [ ] **Step 4: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/screens/shell_screen_test.dart test/main_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/screens/shell_screen.dart \
        test/screens/shell_screen_test.dart
git commit -m "feat(transactions): send the queue when the connection returns"
```

---

### Task 8: Offline, there is nothing to create into

**Files:**
- Modify: `lib/features/transactions/ui/transaction_dialog.dart`
- Test: `test/features/transactions/transaction_dialog_test.dart`

**Interfaces:**
- Consumes: `CategoryPickerField.onCreate` and `PayeePickerField.onCreate` (already shipped).
- Produces: no new API.

- [ ] **Step 1: Write the failing test**

```dart
  testWidgets('offline, there is no offer to create a category: a queued '
      'transaction cannot reference one the server has never issued an id '
      'for', (tester) async {
    // Pump with the offline notifier already true.
    await pumpDialogOffline(tester);
    await tester.tap(find.byType(CategoryPickerField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Werkstatt');
    await tester.pumpAndSettle();

    expect(find.textContaining('Create'), findsNothing);
  });
```

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transaction_dialog_test.dart`
Expected: FAIL — the create row is offered

- [ ] **Step 3: Withhold the callbacks while offline**

```dart
    final offline =
        ref.watch(apiClientProvider).offlineCache?.stale.value ?? false;
```

then

```dart
                      onCreate: _type == 'TRANSFER' || offline
                          ? null
                          : (typed) => _createCategory(typed, ofType),
```

and

```dart
                  onCreate: offline ? null : _createPayee,
```

- [ ] **Step 4: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/ui/transaction_dialog.dart \
        test/features/transactions/transaction_dialog_test.dart
git commit -m "feat(transactions): no create rows offline, where there is no id to get"
```

---

### Task 9: Signing out must not discard the queue silently

**Files:**
- Modify: `lib/features/user/ui/settings_screen.dart`
- Modify: `lib/core/api/api_client.dart:150-155` (`clearToken`)
- Modify: `lib/l10n/app_en.arb`, `app_de.arb`, `app_it.arb`
- Test: `test/features/user/settings_screen_test.dart`

**Interfaces:**
- Consumes: `TransactionOutbox.all()`, `.clear()` (Task 2).
- Produces: no new API.

New strings:

| Key | en | de | it |
|---|---|---|---|
| `logoutPendingTitle` | Unsent transactions | Nicht gesendete Buchungen | Operazioni non inviate |
| `logoutPendingBody` | {count} transactions have not reached the server. Signing out will discard them. | {count} Buchungen haben den Server nicht erreicht. Beim Abmelden gehen sie verloren. | {count} operazioni non hanno raggiunto il server. Uscendo andranno perse. |

`logoutPendingBody` needs `"placeholders": {"count": {"type": "int"}}`.

- [ ] **Step 1: Write the failing test**

Extend `pumpSettings` to take an outbox directory and override
`transactionOutboxProvider`, then:

```dart
  group('signing out with unsent transactions', () {
    late Directory outboxDir;

    setUp(() => outboxDir = Directory.systemTemp.createTempSync('logout_ob'));
    tearDown(() => outboxDir.deleteSync(recursive: true));

    Future<void> queueOne() => TransactionOutbox(outboxDir).add(
          PendingTransaction(
            localId: 'local-1',
            operation: PendingOperation.create,
            transaction: Transaction(
              amount: 12.34,
              transactionDate: DateTime(2026, 9, 4),
            ),
            queuedAt: DateTime(2026, 9, 4, 10),
          ),
        );

    testWidgets('asks first, naming how many would be lost', (tester) async {
      await queueOne();
      await pumpSettings(tester, outboxDir: outboxDir);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(find.text('Unsent transactions'), findsOneWidget);
      expect(find.textContaining('1'), findsWidgets);
    });

    testWidgets('cancelling leaves the queue and the session alone', (
      tester,
    ) async {
      await queueOne();
      final auth = await pumpSettings(tester, outboxDir: outboxDir);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(auth.logoutCalls, 0);
      expect(await TransactionOutbox(outboxDir).all(), hasLength(1));
    });

    testWidgets('an empty queue signs out without asking', (tester) async {
      final auth = await pumpSettings(tester, outboxDir: outboxDir);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(find.text('Unsent transactions'), findsNothing);
      expect(auth.logoutCalls, 1);
    });
  });
```

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/user/settings_screen_test.dart`
Expected: FAIL — no confirmation appears; `logoutCalls` is 1

- [ ] **Step 3: Ask before discarding**

In `_LogoutButton.onPressed`, before calling `logout()`:

```dart
          final pending = await ref.read(transactionOutboxProvider).all();
          if (pending.isNotEmpty) {
            if (!context.mounted) return;
            final confirmed = await showConfirmSheet(
              context,
              title: L.of(context).logoutPendingTitle,
              message: L.of(context).logoutPendingBody(pending.length),
            );
            if (!confirmed || !context.mounted) return;
          }
```

In `ApiClient.clearToken`, next to the cache clear, add a comment pointing at
the caller that has already asked:

```dart
    // The outbox is cleared by the sign-out flow, which asks first: unlike
    // the cache, it holds work the server has never seen.
```

and clear the outbox from the logout flow after the confirmation.

- [ ] **Step 4: Generate l10n, run**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter gen-l10n && flutter test test/features/user/ test/l10n/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/user/ui/settings_screen.dart lib/core/api/api_client.dart \
        lib/l10n/ test/features/user/settings_screen_test.dart
git commit -m "fix(auth): signing out asks before discarding unsent transactions"
```

---

## Final gate

- [ ] Run the whole gate and fix anything it finds

```bash
export PATH="$HOME/flutter/bin:$PATH"
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
dart format lib test
flutter analyze
flutter test
flutter test --coverage && dart run tool/check_coverage.dart 80
```

Expected: analyze clean, all tests pass, coverage at or above 80%.
