# Outbox Ownership Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the transaction outbox record which account it belongs to, and refuse to be read by any other, so a stale queue can never be sent into someone else's books.

**Architecture:** A hidden `.owner.json` beside the entries holds one account key. A small pure helper file decides what is readable; every read of the outbox goes through it, and a structural guard test keeps it that way. Sign-out still clears, but correctness no longer depends on the clearing having happened.

**Tech Stack:** Flutter (Android only), Riverpod, Dio, freezed, `flutter gen-l10n` with three ARB catalogues.

**Spec:** `docs/superpowers/specs/2026-09-04-outbox-ownership-design.md`

## Global Constraints

- Every new user-facing string goes in `lib/l10n/app_en.arb`, `app_de.arb` and `app_it.arb`; then run `flutter gen-l10n`. `test/l10n/translations_test.dart` enforces parity across all three and will fail otherwise.
- Italian calls a transaction *movimento* (masculine). *Scarta* is discard, *Elimina* is delete — reuse `txDiscardPending` for discard rather than inventing a word.
- Never re-inspect `DioExceptionType` outside `lib/core/api/api_exception.dart`.
- `ApiException.message` stays "English, for logs and tests" with no UI reader. `test/l10n/error_localization_test.dart` bans `\b(?:e|error|err|exception)\.message\b`; after Task 6 it scans `lib/core` too.
- After any change touching a `@freezed` or `@riverpod` file, run `dart run build_runner build` (no `--delete-conflicting-outputs`; the flag is removed in Task 6 and is already a no-op that warns).
- Importing all of `package:flutter/foundation.dart` into a file holding a `@freezed` class makes freezed generate `DiagnosticableTreeMixin` surface. Use `show debugPrint`, as the two existing such imports do.
- Run with `export PATH="$HOME/flutter/bin:$PATH"`. Full gate: `flutter analyze`, `dart format --output=none --set-exit-if-changed lib test integration_test tool`, `flutter test`, `dart run tool/check_coverage.dart 80`.
- Baseline at the start of this plan: 1067 tests passing, coverage 88.1%.
- Run every test command in the FOREGROUND with a generous timeout. Do not background them and do not use monitors.

---

### Task 1: the outbox remembers an owner

**Files:**
- Modify: `lib/features/transactions/data/transaction_outbox.dart`
- Test: `test/features/transactions/transaction_outbox_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `Future<String?> TransactionOutbox.owner()` and `Future<void> TransactionOutbox.setOwner(String account)`. Tasks 2-5 use both.

**Note on the filename.** The spec calls this file `owner.json`. Use `.owner.json` — with the leading dot — instead, and skip dot-files in `all()`. Two reasons: `all()` filters on `.json` and would otherwise try to parse the owner file as a `PendingTransaction` on every read, logging a skip line each time; and entry filenames are base64url, an alphabet that *can* spell `owner`, so a plain `owner.json` is a real (if wildly unlikely) collision with an entry. A leading dot is outside base64url entirely, which removes the collision rather than making it improbable.

- [ ] **Step 1: Write the failing test**

Add to `test/features/transactions/transaction_outbox_test.dart`:

```dart
  test('a fresh store has no owner', () async {
    expect(await TransactionOutbox(dir).owner(), isNull);
  });

  test('an owner survives being written and read back', () async {
    final outbox = TransactionOutbox(dir);
    await outbox.setOwner('https://cuenti.muh#42');

    expect(await outbox.owner(), 'https://cuenti.muh#42');
  });

  test('setting an owner twice keeps the last one', () async {
    final outbox = TransactionOutbox(dir);
    await outbox.setOwner('https://cuenti.muh#42');
    await outbox.setOwner('https://other.example#7');

    expect(await outbox.owner(), 'https://other.example#7');
  });

  // The owner file lives in the same directory as the entries and ends in
  // .json like they do. If all() tried to parse it, every read would log a
  // skip line and the file would be one bad refactor away from being
  // mistaken for a queued transaction.
  test('the owner file is not mistaken for an entry', () async {
    final outbox = TransactionOutbox(dir);
    await outbox.setOwner('https://cuenti.muh#42');
    await outbox.add(
      PendingTransaction(
        localId: 'local-1',
        operation: PendingOperation.create,
        transaction: Transaction(
          amount: 1,
          transactionDate: DateTime(2026, 9, 4),
        ),
        queuedAt: DateTime(2026, 9, 4, 10),
      ),
    );

    final entries = await outbox.all();
    expect(entries, hasLength(1));
    expect(entries.single.localId, 'local-1');
  });

  test('clear() drops the owner along with the entries', () async {
    final outbox = TransactionOutbox(dir);
    await outbox.setOwner('https://cuenti.muh#42');

    await outbox.clear();

    expect(await outbox.owner(), isNull);
  });

  test('an unreadable owner file reads as unowned rather than throwing',
      () async {
    final outbox = TransactionOutbox(dir);
    await outbox.setOwner('https://cuenti.muh#42');
    File('${dir.path}/.owner.json').writeAsStringSync('{not json');

    expect(await outbox.owner(), isNull);
  });
```

Match `dir` and the `PendingTransaction` fixture to whatever that file already uses; read its existing tests first rather than introducing new fixtures.

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transaction_outbox_test.dart`
Expected: FAIL — `owner` and `setOwner` are not defined (compile error).

- [ ] **Step 3: Store the owner**

In `lib/features/transactions/data/transaction_outbox.dart`, beside `_fileFor`:

```dart
  /// Which account's queue this is.
  ///
  /// Named with a leading dot so it cannot collide with an entry: entry
  /// filenames are base64url, an alphabet that can spell "owner", and a
  /// dot is outside it. [all] skips dot-files for the same reason.
  File get _ownerFile => File('${_directory.path}/.owner.json');

  /// The account key this queue belongs to, or null when nothing has
  /// claimed it -- a fresh queue, or one written before ownership existed.
  ///
  /// An unreadable file reads as unowned rather than throwing. Unowned is
  /// the cautious answer: it makes the queue something to ask about, not
  /// something to send.
  Future<String?> owner() async {
    if (!_ownerFile.existsSync()) return null;
    try {
      final decoded = jsonDecode(_ownerFile.readAsStringSync());
      final account = decoded is Map<String, dynamic>
          ? decoded['account']
          : null;
      return account is String && account.isNotEmpty ? account : null;
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      debugPrint('TransactionOutbox: unreadable owner file: $e');
      return null;
    }
  }

  /// Claims this queue for [account]. Written the way entries are, so a
  /// torn write cannot leave a half-file that reads as a different owner.
  Future<void> setOwner(String account) async {
    if (!_directory.existsSync()) await _directory.create(recursive: true);
    final tempFile = File('${_ownerFile.path}.tmp');
    await tempFile.writeAsString(jsonEncode({'account': account}));
    await tempFile.rename(_ownerFile.path);
  }
```

In `all()`, skip dot-files. Change the loop's guard from:

```dart
      if (!file.path.endsWith('.json')) continue;
```

to:

```dart
      final name = file.uri.pathSegments.last;
      // Dot-files are the store's own bookkeeping, not entries.
      if (name.startsWith('.') || !name.endsWith('.json')) continue;
```

- [ ] **Step 4: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/data/transaction_outbox.dart \
        test/features/transactions/transaction_outbox_test.dart
git commit -m "feat(transactions): the outbox can record whose queue it is"
```

---

### Task 2: the ownership rules, as pure functions

**Files:**
- Create: `lib/features/transactions/data/outbox_ownership.dart`
- Test: `test/features/transactions/outbox_ownership_test.dart`

**Interfaces:**
- Consumes: `TransactionOutbox.owner()` / `setOwner()` (Task 1).
- Produces, all top-level functions in the new file:
  - `String? accountKeyFor(ApiClient client, AuthState auth)`
  - `Future<List<PendingTransaction>> ownedEntries(TransactionOutbox outbox, String? accountKey)`
  - `Future<List<PendingTransaction>> entriesIgnoringOwner(TransactionOutbox outbox)`
  - `Future<OutboxClaim> claimStateOf(TransactionOutbox outbox, String? accountKey)`
  - `Future<void> claimIfUnowned(TransactionOutbox outbox, String? accountKey)`
  - `enum OutboxClaim { ours, foreign, unowned, empty }`

Tasks 3-5 use these. They take an outbox and a key rather than a `Ref`, because `TransactionSync` holds its outbox by constructor injection and has no ref, while the controller has `Ref` and `sign_out.dart` has `WidgetRef` — three different shapes that a ref-taking helper would have to be written three times for.

- [ ] **Step 1: Write the failing test**

Create `test/features/transactions/outbox_ownership_test.dart`:

```dart
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
```

Note `accountKeyFor` takes the base URL as a plain `String`, not an `ApiClient`. Callers pass `ref.read(apiClientProvider).baseUrl`. That keeps this file free of any dependency on the API layer and makes the whole helper unit-testable with no fakes at all — which is why every test above is a plain `test`, not a `testWidgets` with a container.

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/outbox_ownership_test.dart`
Expected: FAIL — `outbox_ownership.dart` does not exist.

- [ ] **Step 3: Write the helper**

Create `lib/features/transactions/data/outbox_ownership.dart`:

```dart
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';

/// What the outbox on disk is, relative to whoever is signed in now.
enum OutboxClaim {
  /// Nothing queued. Whose it would be does not arise.
  empty,

  /// Queued, and claimed by the current account.
  ours,

  /// Queued, and claimed by somebody else -- or by somebody, while nobody
  /// is signed in. Not to be sent, and not to be shown.
  foreign,

  /// Queued, and claimed by nobody: written before ownership existed.
  unowned,
}

/// Which account a queue belongs to.
///
/// The server is part of the identity because this app is self-hosted: the
/// same user id on two different servers is two different accounts, and a
/// key of the id alone would let one server's queue drain into the other.
///
/// Null means the current account is not knowable -- nobody signed in, or a
/// profile that identifies nobody. That is deliberately not the same as "a
/// key that does not match", but it seals the queue just as firmly: a queue
/// we cannot attribute is a queue we do not send.
String? accountKeyFor(String baseUrl, AuthState auth) {
  final user = auth.user;
  if (user == null) return null;
  final identity = user.id?.toString() ??
      (user.username.isEmpty ? null : user.username);
  if (identity == null) return null;
  return '$baseUrl#$identity';
}

/// The entries the current account may see and send.
///
/// Every read of the outbox goes through here. `test/features/transactions/
/// outbox_reads_test.dart` enforces that, because the rule is only worth
/// anything if the next reader added obeys it too.
Future<List<PendingTransaction>> ownedEntries(
  TransactionOutbox outbox,
  String? accountKey,
) async {
  if (accountKey == null) return const [];
  final owner = await outbox.owner();
  if (owner != accountKey) return const [];
  return outbox.all();
}

/// Every entry, whoever owns it.
///
/// One legitimate caller: the sheet that asks the user what to do about a
/// queue that is not theirs. It has to count what it is asking about.
Future<List<PendingTransaction>> entriesIgnoringOwner(
  TransactionOutbox outbox,
) => outbox.all();

/// Whether the queue on disk is ours, somebody else's, unclaimed, or empty.
Future<OutboxClaim> claimStateOf(
  TransactionOutbox outbox,
  String? accountKey,
) async {
  if ((await outbox.all()).isEmpty) return OutboxClaim.empty;
  final owner = await outbox.owner();
  if (owner == null) return OutboxClaim.unowned;
  if (owner == accountKey) return OutboxClaim.ours;
  return OutboxClaim.foreign;
}

/// Claims the queue for the current account when nothing has claimed it.
Future<void> claimIfUnowned(
  TransactionOutbox outbox,
  String? accountKey,
) async {
  if (accountKey == null) return;
  if (await outbox.owner() != null) return;
  await outbox.setOwner(accountKey);
}
```

- [ ] **Step 4: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/outbox_ownership_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/data/outbox_ownership.dart \
        test/features/transactions/outbox_ownership_test.dart
git commit -m "feat(transactions): the rules for whose queue this is"
```

---

### Task 3: a queued entry claims the queue

**Files:**
- Modify: `lib/features/transactions/ui/transactions_controller.dart:255-285` (`_enqueue`)
- Test: `test/features/transactions/transactions_controller_test.dart`

**Interfaces:**
- Consumes: `claimIfUnowned`, `accountKeyFor` (Task 2).
- Produces: no new API.

Ownership starts meaning something the moment there is something to own, so `_enqueue` — the one place entries are added — claims the queue.

- [ ] **Step 1: Write the failing test**

In `test/features/transactions/transactions_controller_test.dart`, in the offline-save group:

```dart
    test('queueing a save claims the queue for the signed-in account',
        () async {
      when(() => repository.save(any(), splitsTouched: any(named: 'splitsTouched')))
          .thenThrow(const NetworkException('offline'));

      await controller.save(tx(amount: 12.34));

      expect(await outbox.owner(), isNotNull);
    });

    test('a second save does not re-claim an already owned queue', () async {
      await outbox.setOwner('someone-else');
      when(() => repository.save(any(), splitsTouched: any(named: 'splitsTouched')))
          .thenThrow(const NetworkException('offline'));

      await controller.save(tx(amount: 12.34));

      expect(await outbox.owner(), 'someone-else');
    });
```

Adapt `controller`, `repository`, `outbox` and `tx(...)` to that file's existing fixtures. The container will need `authControllerProvider` overridden with a signed-in state and `apiClientProvider` available — follow whatever that file already does for auth, and if it does nothing, override `authControllerProvider` with a fake returning `AuthState(user: UserProfile(id: 42, username: 'ben'))` the way `test/main_test.dart` does.

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transactions_controller_test.dart`
Expected: FAIL — the first test finds `owner()` null, because nothing claims the queue.

- [ ] **Step 3: Claim on enqueue**

In `_enqueue`, after `await outbox.add(entry);`:

```dart
    await outbox.add(entry);
    // Ownership starts mattering the moment there is something to own. An
    // already-claimed queue keeps its claim: the first account to queue
    // into it is the one it belongs to.
    await claimIfUnowned(
      outbox,
      accountKeyFor(
        ref.read(apiClientProvider).baseUrl,
        ref.read(authControllerProvider),
      ),
    );
```

Add the imports for `outbox_ownership.dart`, `dio_provider.dart` (for `apiClientProvider`) and `auth_controller.dart` if they are not already there.

- [ ] **Step 4: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/ui/transactions_controller.dart \
        test/features/transactions/transactions_controller_test.dart
git commit -m "feat(transactions): a queued write claims the queue"
```

---

### Task 4: nothing reads the outbox unguarded

**Files:**
- Modify: `lib/features/transactions/data/transaction_sync.dart:99` and its constructor and provider (`:153-158`)
- Modify: `lib/features/transactions/ui/transactions_controller.dart` lines 137, 155, 220, 241, 264
- Modify: `lib/features/auth/ui/sign_out.dart:29` and `:56`
- Create: `test/features/transactions/outbox_reads_test.dart`
- Test: `test/features/transactions/transaction_sync_test.dart`, `test/features/user/settings_screen_test.dart`

**Interfaces:**
- Consumes: `ownedEntries`, `accountKeyFor` (Task 2).
- Produces: `TransactionSync(outbox, repository, accountKey)` where `accountKey` is `String? Function()`.

There are eight `.all()` call sites across three components. This task routes every one through `ownedEntries` and adds the structural test that keeps the ninth honest.

- [ ] **Step 1: Write the structural guard test**

Create `test/features/transactions/outbox_reads_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The outbox may hold a queue belonging to a different account -- one left
/// behind by a fallback store, or by a session that expired before the next
/// person signed in. `ownedEntries` is what keeps such a queue from being
/// sent and from being shown; a bare `all()` bypasses it.
///
/// The rule is blunt on purpose: no `.all()` on an outbox outside the two
/// files that are allowed one. A reader added later without knowing about
/// ownership fails here rather than quietly leaking somebody's
/// transactions into somebody else's books.
void main() {
  const allowed = {
    // Defines the rule. `ownedEntries`, `entriesIgnoringOwner` and
    // `claimStateOf` are the three sanctioned reads.
    'lib/features/transactions/data/outbox_ownership.dart',
    // The store itself: markRejected reads its own entries to amend one.
    'lib/features/transactions/data/transaction_outbox.dart',
  };

  test('every outbox read goes through outbox_ownership.dart', () {
    final offenders = <String>[];
    final banned = RegExp(r'\.all\(\)');

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('.g.dart') ||
          file.path.endsWith('.freezed.dart')) {
        continue;
      }
      if (allowed.contains(file.path)) continue;
      final src = file.readAsStringSync();
      for (final match in banned.allMatches(src)) {
        final line =
            '\n'.allMatches(src.substring(0, match.start)).length + 1;
        offenders.add('${file.path}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'read the outbox through ownedEntries() in outbox_ownership.dart, '
          'or add a justified entry to the allow-list above:\n'
          '${offenders.join('\n')}',
    );
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/outbox_reads_test.dart`
Expected: FAIL, listing six offenders — `transaction_sync.dart:99`, `transactions_controller.dart` at 137, 155, 220, 241, 264, and `sign_out.dart` at 29 and 56.

- [ ] **Step 3: Give the sync an account key**

In `lib/features/transactions/data/transaction_sync.dart`, change the constructor and field:

```dart
  TransactionSync(this._outbox, this._repository, this._accountKey);

  final TransactionOutbox _outbox;
  final TransactionsRepository _repository;

  /// Read at the start of every pass rather than captured once: a drain can
  /// outlive the sign-in it started under.
  final String? Function() _accountKey;
```

Change line 99's loop:

```dart
    for (final entry in await ownedEntries(_outbox, _accountKey())) {
```

and the provider at the bottom of the file:

```dart
final transactionSyncProvider = Provider<TransactionSync>(
  (ref) => TransactionSync(
    ref.watch(transactionOutboxProvider),
    ref.watch(transactionsRepositoryProvider),
    () => accountKeyFor(
      ref.read(apiClientProvider).baseUrl,
      ref.read(authControllerProvider),
    ),
  ),
);
```

Add imports for `outbox_ownership.dart`, `dio_provider.dart` and `auth_controller.dart`.

- [ ] **Step 4: Route the controller's five reads**

In `lib/features/transactions/ui/transactions_controller.dart`, add a private helper beside the others:

```dart
  /// The queued entries this account may see. Foreign or unclaimed queues
  /// read as empty -- they are somebody else's amounts and payees, so they
  /// are not merged into the list any more than they are sent.
  Future<List<PendingTransaction>> _pending() => ownedEntries(
    ref.read(transactionOutboxProvider),
    accountKeyFor(
      ref.read(apiClientProvider).baseUrl,
      ref.read(authControllerProvider),
    ),
  );
```

Then replace each of the five reads. Lines 137, 155 and 220 currently read:

```dart
    final pending = await ref.read(transactionOutboxProvider).all();
```

and become:

```dart
    final pending = await _pending();
```

Line 241 currently reads `final queued = await ref.read(transactionOutboxProvider).all();` and becomes `final queued = await _pending();`.

Line 264, inside `_enqueue`, currently reads:

```dart
        : (await outbox.all()).where((e) => e.localId == localId).firstOrNull;
```

and becomes:

```dart
        : (await _pending()).where((e) => e.localId == localId).firstOrNull;
```

- [ ] **Step 5: Route sign-out's two reads, and clear only an owned queue**

In `lib/features/auth/ui/sign_out.dart`, replace the body of `confirmSignOut`'s read (line 29):

```dart
  final outbox = ref.read(transactionOutboxProvider);
  final accountKey = accountKeyFor(
    ref.read(apiClientProvider).baseUrl,
    ref.read(authControllerProvider),
  );
  final pending = await ownedEntries(outbox, accountKey);
```

and `signOut` (line 56):

```dart
  // Only an owned queue. clear() deletes the directory wholesale, so
  // calling it on a queue belonging to another account would delete data
  // the user was never warned about -- the message would describe one
  // thing while the code did another. A foreign queue is left where it is:
  // sealed on the read path, and not this session's to discard.
  final accountKey = accountKeyFor(
    ref.read(apiClientProvider).baseUrl,
    ref.read(authControllerProvider),
  );
  if ((await ownedEntries(outbox, accountKey)).isNotEmpty) {
    await outbox.clear();
  }
```

Add the imports for `outbox_ownership.dart`, `dio_provider.dart` and `auth_controller.dart`.

- [ ] **Step 6: Write the behaviour tests for both doors**

In `test/features/transactions/transaction_sync_test.dart`:

```dart
  group('a queue that is not ours', () {
    test('a foreign queue is not sent', () async {
      await queue('local-1');
      await outbox.setOwner('https://cuenti.muh#1');
      // The sync is built for account 2.

      expect(await sync.drain(), 0);
      verifyNever(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      );
      expect(await outbox.all(), hasLength(1));
    });

    test('an unclaimed queue is not sent either', () async {
      await queue('local-1');

      expect(await sync.drain(), 0);
      verifyNever(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      );
    });

    // The other half of the guard: it must seal foreign queues without
    // sealing everything, or the feature is just broken sending.
    test('our own queue is still sent', () async {
      await queue('local-1');
      await outbox.setOwner('https://cuenti.muh#2');

      expect(await sync.drain(), 1);
    });
  });

  // The two ways a stale queue reaches a new account. Both end at the same
  // guard, but they are named separately because they are the reason the
  // guard exists, and a future reader deleting one should have to argue
  // with the door it describes rather than with a generic case.
  group('the doors this closes', () {
    test('door 1: a real store that survived a fallback sign-out is not '
        'sent for the next account', () async {
      // Account 1 queued into the real store while a fallback was in use,
      // so sign-out cleared the fallback and left this untouched.
      await queue('local-1');
      await outbox.setOwner('https://cuenti.muh#1');

      expect(await sync.drain(), 0);
      expect(await outbox.all(), hasLength(1), reason: 'left, not deleted');
    });

    test('door 2: a queue kept across an expired session is not sent to '
        'whoever signs in next', () async {
      // _handleSessionExpired keeps the outbox deliberately -- the session
      // expired, the user did not ask to be forgotten. That is safe only
      // because the next account cannot read it.
      await queue('local-1');
      await outbox.setOwner('https://cuenti.muh#1');

      expect(await ownedEntries(outbox, 'https://cuenti.muh#2'), isEmpty);
      expect(await sync.drain(), 0);
    });

    test('but the same account signing back in still gets its queue',
        () async {
      await queue('local-1');
      await outbox.setOwner('https://cuenti.muh#2');

      expect(
        await ownedEntries(outbox, 'https://cuenti.muh#2'),
        hasLength(1),
      );
    });
  });
```

Build `sync` in this group with an account-key callback returning
`'https://cuenti.muh#2'`; follow the file's existing construction and add the
third argument.

- [ ] **Step 7: Run and watch everything pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test`
Expected: PASS, and `outbox_reads_test.dart` now green with no offenders.

This is the task most likely to break existing tests: every test that builds a `TransactionSync` needs the third constructor argument, and every controller or sign-out test whose container has no signed-in user will now see an empty queue where it saw entries. **Each such change is a real behaviour change to report** — say which test, what it asserted, and what it needed. Give those containers a signed-in account and an owned queue rather than weakening an assertion.

- [ ] **Step 8: Commit**

```bash
git add lib/features/transactions/data/transaction_sync.dart \
        lib/features/transactions/ui/transactions_controller.dart \
        lib/features/auth/ui/sign_out.dart \
        test/features/transactions/ test/features/user/
git commit -m "feat(transactions): a queue is only read by the account that owns it"
```

---

### Task 5: telling the user about a queue that is not theirs

**Files:**
- Create: `lib/features/transactions/ui/outbox_claim_prompt.dart`
- Modify: `lib/features/auth/ui/auth_controller.dart` (call the check after `_persistSuccessfulLogin` and after `_init`)
- Modify: `lib/l10n/app_en.arb`, `app_de.arb`, `app_it.arb`
- Test: `test/features/transactions/outbox_claim_prompt_test.dart`

**Interfaces:**
- Consumes: `claimStateOf`, `entriesIgnoringOwner`, `accountKeyFor`, `OutboxClaim` (Task 2); `TransactionOutbox.clear`, `setOwner` (Task 1).
- Produces: `Future<void> promptForForeignOutbox(BuildContext context, WidgetRef ref)`.

The dialog exists so the user knows, not so the code is safe — `ownedEntries` is what makes it safe. Declining leaves the queue sealed.

- [ ] **Step 1: Add the strings**

`lib/l10n/app_en.arb`:

```json
  "outboxForeignTitle": "Unsent transactions from another account",
  "@outboxForeignTitle": {},
  "outboxForeignBody": "{count} unsent transactions belong to a different account. They will not be sent.",
  "@outboxForeignBody": {"placeholders": {"count": {"type": "int"}}},
  "outboxUnknownTitle": "Unsent transactions from an earlier version",
  "@outboxUnknownTitle": {},
  "outboxUnknownBody": "{count} unsent transactions were saved before this version. Send them as {account}, or discard them?",
  "@outboxUnknownBody": {"placeholders": {"count": {"type": "int"}, "account": {"type": "String"}}},
  "outboxKeep": "Keep",
  "@outboxKeep": {},
  "outboxSendAsThisAccount": "Send as this account",
  "@outboxSendAsThisAccount": {},
```

`lib/l10n/app_de.arb`:

```json
  "outboxForeignTitle": "Nicht gesendete Buchungen eines anderen Kontos",
  "outboxForeignBody": "{count} nicht gesendete Buchungen gehören zu einem anderen Konto. Sie werden nicht gesendet.",
  "outboxUnknownTitle": "Nicht gesendete Buchungen aus einer früheren Version",
  "outboxUnknownBody": "{count} nicht gesendete Buchungen wurden vor dieser Version gespeichert. Als {account} senden oder verwerfen?",
  "outboxKeep": "Behalten",
  "outboxSendAsThisAccount": "Als dieses Konto senden",
```

`lib/l10n/app_it.arb`:

```json
  "outboxForeignTitle": "Operazioni non inviate di un altro account",
  "outboxForeignBody": "{count} operazioni non inviate appartengono a un altro account. Non verranno inviate.",
  "outboxUnknownTitle": "Operazioni non inviate di una versione precedente",
  "outboxUnknownBody": "{count} operazioni non inviate sono state salvate prima di questa versione. Inviarle come {account} o scartarle?",
  "outboxKeep": "Mantieni",
  "outboxSendAsThisAccount": "Invia come questo account",
```

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter gen-l10n`

- [ ] **Step 2: Write the failing test**

Create `test/features/transactions/outbox_claim_prompt_test.dart` with widget tests that pump a host widget calling `promptForForeignOutbox`, over a real temp-directory outbox, and assert:

```dart
  testWidgets('a foreign queue is named, and discarding empties it', (
    tester,
  ) async {
    await queue('local-1');
    await outbox.setOwner('https://cuenti.muh#1');
    await pumpHost(tester, accountKey: 'https://cuenti.muh#2');

    expect(find.text('Unsent transactions from another account'), findsOneWidget);
    expect(find.textContaining('1'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Scarta'));
    await tester.pumpAndSettle();

    expect(await outbox.all(), isEmpty);
  });

  testWidgets('keeping a foreign queue leaves it, still sealed', (
    tester,
  ) async {
    await queue('local-1');
    await outbox.setOwner('https://cuenti.muh#1');
    await pumpHost(tester, accountKey: 'https://cuenti.muh#2');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Keep'));
    await tester.pumpAndSettle();

    expect(await outbox.all(), hasLength(1));
    expect(await ownedEntries(outbox, 'https://cuenti.muh#2'), isEmpty);
  });

  testWidgets('an unclaimed queue offers to adopt it', (tester) async {
    await queue('local-1');
    await pumpHost(tester, accountKey: 'https://cuenti.muh#2');

    await tester.tap(
      find.widgetWithText(FilledButton, 'Send as this account'),
    );
    await tester.pumpAndSettle();

    expect(await outbox.owner(), 'https://cuenti.muh#2');
    expect(await ownedEntries(outbox, 'https://cuenti.muh#2'), hasLength(1));
  });

  testWidgets('our own queue asks nothing', (tester) async {
    await queue('local-1');
    await outbox.setOwner('https://cuenti.muh#2');
    await pumpHost(tester, accountKey: 'https://cuenti.muh#2');

    expect(find.byType(Dialog), findsNothing);
    expect(find.textContaining('another account'), findsNothing);
  });

  testWidgets('an empty queue asks nothing', (tester) async {
    await pumpHost(tester, accountKey: 'https://cuenti.muh#2');

    expect(find.textContaining('another account'), findsNothing);
  });
```

The discard button's label is the existing `txDiscardPending` — English "Discard", Italian "Scarta". Use whichever locale your host pumps; the snippet above mixes them to make the point that you must check the catalogue rather than guess. Outbox I/O inside a widget test needs `tester.runAsync`; follow the pattern already in `test/features/user/settings_screen_test.dart`.

- [ ] **Step 3: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/outbox_claim_prompt_test.dart`
Expected: FAIL — `promptForForeignOutbox` does not exist.

- [ ] **Step 4: Write the prompt**

Create `lib/features/transactions/ui/outbox_claim_prompt.dart`:

```dart
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/outbox_ownership.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tells the user about a queue that is not theirs, once, after a sign-in.
///
/// Nothing here is load-bearing for safety: [ownedEntries] already refuses
/// to send or show a queue the current account does not own. This exists so
/// that unsent work does not vanish from view with no explanation -- and so
/// that a queue left by an earlier version, which nobody has claimed, can
/// be adopted rather than stranded.
Future<void> promptForForeignOutbox(
  BuildContext context,
  WidgetRef ref,
) async {
  final outbox = ref.read(transactionOutboxProvider);
  final accountKey = accountKeyFor(
    ref.read(apiClientProvider).baseUrl,
    ref.read(authControllerProvider),
  );
  if (accountKey == null) return;

  final claim = await claimStateOf(outbox, accountKey);
  if (claim == OutboxClaim.empty || claim == OutboxClaim.ours) return;
  if (!context.mounted) return;

  final count = (await entriesIgnoringOwner(outbox)).length;
  if (!context.mounted) return;

  final l = L.of(context);
  switch (claim) {
    case OutboxClaim.foreign:
      final discard = await showConfirmSheet(
        context,
        title: l.outboxForeignTitle,
        message: l.outboxForeignBody(count),
        confirmLabel: l.txDiscardPending,
        cancelLabel: l.outboxKeep,
      );
      if (discard) await outbox.clear();
    case OutboxClaim.unowned:
      final adopt = await showConfirmSheet(
        context,
        title: l.outboxUnknownTitle,
        message: l.outboxUnknownBody(count, accountKey),
        confirmLabel: l.outboxSendAsThisAccount,
        cancelLabel: l.txDiscardPending,
      );
      if (adopt) {
        await outbox.setOwner(accountKey);
      } else {
        await outbox.clear();
      }
    case OutboxClaim.empty:
    case OutboxClaim.ours:
      return;
  }
}
```

If `showConfirmSheet` has no `cancelLabel` parameter, add one defaulting to the current label rather than building a second sheet — check `lib/core/widgets/confirm_sheet.dart` first and report what you found.

- [ ] **Step 5: Call it after a sign-in**

**Deviation from the spec, deliberate.** The spec put this call "after `_persistSuccessfulLogin` and after `AuthController._init`". Neither is reachable: both live in `AuthController`, which has no `BuildContext`, and this prompt shows a sheet. The call goes instead to `ShellScreen` — the first screen behind the router's signed-in redirect, so it is reached on both paths the spec named and on no others. Record this in your report.

In `lib/screens/shell_screen.dart`, add a one-shot beside the existing `_OutboxDrainOnReconnect`:

```dart
/// Asks about a queue belonging to another account, once per sign-in.
///
/// Here rather than in AuthController because it needs a BuildContext to
/// show a sheet. ShellScreen is the first screen behind the signed-in
/// redirect, so it is reached by a fresh login and by a restored session
/// alike -- the two arrivals the check has to cover.
class _OutboxClaimCheck extends ConsumerStatefulWidget {
  const _OutboxClaimCheck();

  @override
  ConsumerState<_OutboxClaimCheck> createState() => _OutboxClaimCheckState();
}

class _OutboxClaimCheckState extends ConsumerState<_OutboxClaimCheck> {
  bool _asked = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (!_asked && auth.initialized && auth.user != null) {
      _asked = true;
      // Not awaited: nothing about drawing this frame should wait on a
      // disk read, and the sheet opens on its own when it is ready.
      unawaited(promptForForeignOutbox(context, ref));
    }
    return const SizedBox.shrink();
  }
}
```

and add it to the column that already holds `_OutboxDrainOnReconnect`:

```dart
          const _OutboxClaimCheck(),
```

The `_asked` guard is the same shape as `main.dart`'s `_startupDrainAsked`: without it, every rebuild of the shell would re-run the check and could stack sheets.

- [ ] **Step 6: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/ test/screens/ test/l10n/`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/transactions/ui/outbox_claim_prompt.dart \
        lib/screens/shell_screen.dart lib/l10n/ \
        test/features/transactions/outbox_claim_prompt_test.dart
git commit -m "feat(transactions): say so when the queue belongs to another account"
```

---

### Task 6: two chores

**Files:**
- Modify: `CLAUDE.md`, `docs/superpowers/plans/2026-09-04-offline-transactions.md`, `docs/superpowers/plans/2026-09-04-error-display.md`, and any other file naming the flag
- Modify: `test/l10n/error_localization_test.dart`

**Interfaces:** none.

- [ ] **Step 1: Drop the deprecated flag**

`build_runner` now prints `W These options have been removed and were ignored: --delete-conflicting-outputs` on every codegen run — the behaviour is the default. Find every occurrence and remove just the flag, leaving `dart run build_runner build`:

Run: `grep -rn "delete-conflicting-outputs" --exclude-dir=.git . || true`

Edit each hit. Do not change the surrounding prose beyond dropping the flag.

- [ ] **Step 2: Extend the l10n guard to `lib/core`**

`test/l10n/error_localization_test.dart` scans `lib/features` and `lib/screens`, but the shared error-display widgets now live in `lib/core/widgets` (`feedback_snack.dart:82`, `entity_edit_sheet.dart:90`). Add `lib/core` to the scanned directories:

```dart
    for (final dir in ['lib/core', 'lib/features', 'lib/screens']) {
```

and add the one honest allow-list entry it needs:

```dart
    // Reads `e.message` off a DioException, not an ApiException -- it is
    // the code that turns the former into the latter, so there is no
    // localized half to prefer yet.
    'lib/core/api/api_exception.dart',
```

- [ ] **Step 3: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/l10n/`
Expected: PASS. If it lists offenders in `lib/core` other than `api_exception.dart`, they are real findings — fix them to use `localizedMessage`, and report each.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md docs/ test/l10n/error_localization_test.dart
git commit -m "chore: drop a removed build_runner flag, widen the l10n guard"
```

---

### Task 7: the whole gate

**Files:** none — this task only runs and reports.

- [ ] **Step 1: Regenerate**

Run: `export PATH="$HOME/flutter/bin:$PATH" && dart run build_runner build && flutter gen-l10n`

Commit any churn on its own:

```bash
git add -A lib/
git commit -m "chore: regenerate" || echo "nothing to regenerate"
```

- [ ] **Step 2: Run the full gate**

```bash
export PATH="$HOME/flutter/bin:$PATH"
flutter analyze
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter test
dart run tool/check_coverage.dart 80
```

Expected: all four clean. Report the final test count and coverage figure.
