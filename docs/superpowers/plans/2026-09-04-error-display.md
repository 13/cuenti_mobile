# Error Display and Offline Follow-ups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `ApiException` carry what the server actually said, show it to the user inside a translated frame, and clear the two follow-ups the offline-transactions branch parked.

**Architecture:** `ApiException.fromDio` already derives the server's explanation but discards it by passing it as the positional `message`. Threading `serverMessage:` and `statusCode:` through revives it and two dead `localizedMessage` branches. Because a populated `serverMessage` would otherwise replace every translation with raw server text, `localizedMessage` gains framed variants — a translated sentence quoting the server inside it — applied only where the server's words are actionable. The remaining tasks are independent local fixes.

**Tech Stack:** Flutter (Android only), Riverpod, Dio, freezed, `flutter gen-l10n` with three ARB catalogues.

**Spec:** `docs/superpowers/specs/2026-09-04-error-display-design.md`

## Global Constraints

- Every new user-facing string goes in `lib/l10n/app_en.arb`, `app_de.arb` and `app_it.arb`; then run `flutter gen-l10n`. `test/l10n/translations_test.dart` enforces parity across all three and will fail otherwise.
- Never re-inspect `DioExceptionType` outside `lib/core/api/api_exception.dart`.
- `ApiException.message` keeps its role: "English, for logs and tests." Nothing in this plan changes what it holds or adds a UI reader of it.
- `test/l10n/error_localization_test.dart` bans `\b(?:e|error|err|exception)\.message\b` anywhere under `lib/features` or `lib/screens`. Code you write in those trees must not match that regex.
- Italian calls a transaction *movimento* (masculine); adjectives agreeing with it are masculine.
- After any change touching a `@freezed` or `@riverpod` file, run `dart run build_runner build`. CI fails on stale generated output.
- Run with `export PATH="$HOME/flutter/bin:$PATH"`. Full gate: `flutter analyze`, `dart format --output=none --set-exit-if-changed lib test integration_test tool`, `flutter test`, `dart run tool/check_coverage.dart 80`.
- Baseline at the start of this plan: 1035 tests passing, coverage 87.9%.
- Run test commands in the FOREGROUND with a generous timeout. Do not background them.

---

### Task 1: `fromDio` keeps what the server said

**Files:**
- Modify: `lib/core/api/api_exception.dart:9-43` (the `fromDio` factory)
- Create: `test/core/api/api_exception_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `ApiException.serverMessage` is non-null whenever the response carried a usable body, and `ApiException.statusCode` is non-null for every `badResponse`. Task 2 reads both. Also produces the private constant `maxServerMessageLength = 200`.

- [ ] **Step 1: Write the failing test**

Create `test/core/api/api_exception_test.dart`:

```dart
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds the DioException shape `ApiException.fromDio` actually receives
/// for a response the server answered with.
DioException badResponse(int status, dynamic body) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.badResponse,
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: body,
  ),
);

void main() {
  group('fromDio keeps what the server said', () {
    test('a JSON error body becomes serverMessage, not just message', () {
      final e = ApiException.fromDio(
        badResponse(422, {'error': 'Amount must be positive'}),
      );

      expect(e, isA<ValidationException>());
      expect(e.serverMessage, 'Amount must be positive');
      expect(e.statusCode, 422);
    });

    test('a bare string body is taken as the explanation too', () {
      final e = ApiException.fromDio(badResponse(400, 'Missing account'));

      expect(e.serverMessage, 'Missing account');
      expect(e.statusCode, 400);
    });

    test('a body that explains nothing leaves serverMessage null', () {
      final e = ApiException.fromDio(badResponse(500, <String, dynamic>{}));

      expect(e, isA<ServerException>());
      expect(e.serverMessage, isNull);
      expect(e.statusCode, 500);
    });

    test('an empty string body is not an explanation', () {
      final e = ApiException.fromDio(badResponse(400, ''));

      expect(e.serverMessage, isNull);
    });

    // 403 carries the status so localizedMessage can tell "the API is
    // switched off" from "your session expired" -- two things that read
    // identically without it.
    test('403 carries its status', () {
      final e = ApiException.fromDio(badResponse(403, null));

      expect(e, isA<UnauthorizedException>());
      expect(e.statusCode, 403);
    });

    test('401 carries its status', () {
      final e = ApiException.fromDio(badResponse(401, null));

      expect(e, isA<UnauthorizedException>());
      expect(e.statusCode, 401);
    });

    // A misconfigured reverse proxy answers with a whole HTML page. That
    // string is about to be shown to a user inside a snackbar.
    test('an overlong body is truncated', () {
      final e = ApiException.fromDio(badResponse(400, 'x' * 5000));

      expect(e.serverMessage!.length, lessThanOrEqualTo(201));
      expect(e.serverMessage, endsWith('…'));
    });

    test('a body at the limit is not given an ellipsis', () {
      final e = ApiException.fromDio(badResponse(400, 'x' * 200));

      expect(e.serverMessage, 'x' * 200);
    });

    test('a connection failure has no server message or status', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(e, isA<NetworkException>());
      expect(e.serverMessage, isNull);
      expect(e.statusCode, isNull);
    });
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/core/api/api_exception_test.dart`

Expected: FAIL. `serverMessage` is null on every `badResponse` case and `statusCode` is null everywhere, because `fromDio` passes the derived string as the positional `message` and never uses the named parameters.

- [ ] **Step 3: Thread both fields through**

In `lib/core/api/api_exception.dart`, replace the `badResponse` case of `fromDio` (lines 17-36) with:

```dart
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        final body = e.response?.data;
        final raw = switch (body) {
          {'error': final String msg} when msg.isNotEmpty => msg,
          final String s when s.isNotEmpty => s,
          _ => null,
        };
        // This string is shown to a user now, and a misconfigured reverse
        // proxy answers with an entire HTML page. Cut it here, once, so
        // every consumer gets the same rule.
        final serverMessage = raw == null || raw.length <= maxServerMessageLength
            ? raw
            : '${raw.substring(0, maxServerMessageLength)}…';
        if (status == 401) {
          return UnauthorizedException(
            serverMessage ?? 'Not authenticated',
            serverMessage: serverMessage,
            statusCode: status,
          );
        }
        if (status == 403) {
          return UnauthorizedException(
            serverMessage ?? 'API access is not enabled',
            serverMessage: serverMessage,
            statusCode: status,
          );
        }
        if (status >= 400 && status < 500) {
          return ValidationException(
            serverMessage ?? 'Invalid request',
            serverMessage: serverMessage,
            statusCode: status,
          );
        }
        return ServerException(
          serverMessage ?? 'Server error ($status)',
          serverMessage: serverMessage,
          statusCode: status,
        );
```

Add the constant near `_certificateMessage` at the bottom of the file:

```dart
/// How much of the server's own explanation is worth putting in front of a
/// user. A body long enough to matter is an HTML error page, not a sentence.
const maxServerMessageLength = 200;
```

Note the added `when msg.isNotEmpty` guard on the JSON branch: an
`{'error': ''}` body is not an explanation, and without the guard it would
produce an empty `serverMessage` that reads as "the server explained itself".

- [ ] **Step 4: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/core/api/api_exception_test.dart`
Expected: PASS, 9/9.

- [ ] **Step 5: Run the suites that consume exceptions**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/core/ test/features/auth/ test/l10n/`
Expected: PASS. Nothing reads `serverMessage` yet, so this is a regression check only. If something fails, it is asserting on a generic fallback that a real `serverMessage` now displaces — report it rather than editing the assertion.

- [ ] **Step 6: Commit**

```bash
git add lib/core/api/api_exception.dart test/core/api/api_exception_test.dart
git commit -m "fix(api): keep the server's own explanation and its status"
```

---

### Task 2: the user sees the server's sentence, inside a translated frame

**Files:**
- Modify: `lib/core/api/api_exception.dart:59-78` (`localizedMessage`)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_it.arb`
- Test: `test/core/api/api_exception_test.dart`

**Interfaces:**
- Consumes: `serverMessage` and `statusCode` from Task 1.
- Produces: l10n keys `errorInvalidRequestDetail(detail)` and `errorServerDetail(status, detail)`. No later task depends on them.

- [ ] **Step 1: Add the strings**

In `lib/l10n/app_en.arb`, beside the other `error*` keys:

```json
  "errorInvalidRequestDetail": "Invalid request: {detail}",
  "@errorInvalidRequestDetail": {"placeholders": {"detail": {"type": "String"}}},
  "errorServerDetail": "Server error ({status}): {detail}",
  "@errorServerDetail": {"placeholders": {"status": {"type": "String"}, "detail": {"type": "String"}}},
```

In `lib/l10n/app_de.arb`:

```json
  "errorInvalidRequestDetail": "Ungültige Anfrage: {detail}",
  "errorServerDetail": "Serverfehler ({status}): {detail}",
```

In `lib/l10n/app_it.arb`:

```json
  "errorInvalidRequestDetail": "Richiesta non valida: {detail}",
  "errorServerDetail": "Errore del server ({status}): {detail}",
```

Then run: `export PATH="$HOME/flutter/bin:$PATH" && flutter gen-l10n`

- [ ] **Step 2: Write the failing test**

Append to `test/core/api/api_exception_test.dart`. Note the import and the German lookup — asserting only in English cannot tell a translated frame from a verbatim quote, which is the whole point of this task:

```dart
// add to the imports at the top of the file:
// import 'package:cuentimobile/l10n/app_localizations.dart';
// import 'package:cuentimobile/l10n/app_localizations_de.dart';
// import 'package:cuentimobile/l10n/app_localizations_en.dart';

  group('localizedMessage', () {
    final en = AppLocalizationsEn();
    final de = AppLocalizationsDe();

    test('a 4xx quotes the server inside a translated frame', () {
      final e = ApiException.fromDio(
        badResponse(422, {'error': 'Amount must be positive'}),
      );

      expect(e.localizedMessage(en), 'Invalid request: Amount must be positive');
      expect(
        e.localizedMessage(de),
        'Ungültige Anfrage: Amount must be positive',
      );
    });

    test('a 4xx with no explanation keeps the plain translated string', () {
      final e = ApiException.fromDio(badResponse(400, null));

      expect(e.localizedMessage(en), 'Invalid request');
      expect(e.localizedMessage(de), 'Ungültige Anfrage');
    });

    test('a 5xx names its status and quotes the server', () {
      final e = ApiException.fromDio(badResponse(503, 'Upstream down'));

      expect(e.localizedMessage(en), 'Server error (503): Upstream down');
    });

    // Dead before this change: statusCode was always null, so every 5xx
    // took the "unexpected response" branch instead.
    test('a 5xx with no explanation names its status', () {
      final e = ApiException.fromDio(badResponse(500, null));

      expect(e.localizedMessage(en), 'Server error (500)');
    });

    // Dead before this change: without statusCode, a switched-off API read
    // as an expired session and sent the user after a password problem.
    test('403 says the API is not enabled, not that you are signed out', () {
      final e = ApiException.fromDio(badResponse(403, null));

      expect(e.localizedMessage(en), 'API access is not enabled');
    });

    test('401 stays the translated string even when the server spoke', () {
      final e = ApiException.fromDio(badResponse(401, 'JWT expired'));

      expect(e.localizedMessage(en), 'Not authenticated');
      expect(e.localizedMessage(de), 'Nicht angemeldet');
    });

    test('a network failure is translated, never quoted', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(e.localizedMessage(de), 'Keine Verbindung zum Server');
    });

    test('the truncated body is what the user is shown', () {
      final e = ApiException.fromDio(badResponse(400, 'y' * 5000));

      expect(e.localizedMessage(en).length, lessThan(230));
      expect(e.localizedMessage(en), endsWith('…'));
    });
  });
```

If a German or Italian assertion above does not match the catalogue, use the
catalogue's actual value — do not edit the catalogue to match the test.

- [ ] **Step 3: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/core/api/api_exception_test.dart`

Expected: FAIL. Today `localizedMessage` returns `serverMessage` verbatim when it is set (line 61), so the framed cases come back as bare server text; the 403 and known-status 5xx cases return the wrong branch.

- [ ] **Step 4: Replace `localizedMessage`**

In `lib/core/api/api_exception.dart`, replace the method and its doc comment (lines 54-78) with:

```dart
  /// The message to put in front of the user.
  ///
  /// Where the server's own sentence tells the user something this client
  /// cannot -- which field it rejected, which upstream is down -- it is
  /// quoted inside a translated frame, so the words around it are in the
  /// user's language even when the server's are not. Everything else is
  /// translated outright: a 401's "Not authenticated" or a connection
  /// failure adds nothing over the string written here, and 403 has a
  /// specific one that is better than anything the server will say.
  String localizedMessage(L l) {
    final detail = serverMessage;
    final explained = detail != null && detail.isNotEmpty;
    return switch (this) {
      NetworkException() =>
        message == _certificateMessage ? l.errorCertificate : l.errorNetwork,
      UnauthorizedException() => switch (this) {
        _ when message == invalidCredentialsMessage =>
          l.errorInvalidCredentials,
        _ when statusCode == 403 => l.errorApiDisabled,
        _ => l.errorNotAuthenticated,
      },
      ValidationException() => explained
          ? l.errorInvalidRequestDetail(detail)
          : l.errorInvalidRequest,
      ServerException() => switch (statusCode) {
        null => l.errorUnexpectedResponse,
        final status when explained =>
          l.errorServerDetail('$status', detail),
        final status => l.errorServer('$status'),
      },
      UnknownApiException() => l.errorUnknown,
    };
  }
```

- [ ] **Step 5: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/core/api/api_exception_test.dart test/l10n/`
Expected: PASS.

- [ ] **Step 6: Run the full suite**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test`

Expected: PASS. This change alters what users see on every error path, so screens asserting on a generic string may now see a framed one. Any failure here is a real behaviour change to report, not a test to quietly update — say which test and what it now sees.

- [ ] **Step 7: Commit**

```bash
git add lib/core/api/api_exception.dart lib/l10n/ test/core/api/api_exception_test.dart
git commit -m "feat(api): show what the server said, inside a translated frame"
```

---

### Task 3: the sync stores the server's words, and comes off the allow-list

**Files:**
- Modify: `lib/features/transactions/data/transaction_sync.dart:53-59`
- Modify: `lib/features/transactions/ui/widgets/transaction_list_parts.dart:316-324`
- Modify: `lib/l10n/app_en.arb`, `app_de.arb`, `app_it.arb`
- Modify: `test/l10n/error_localization_test.dart:22-38` (remove the allow-list entry and its TODO)
- Test: `test/features/transactions/transaction_sync_test.dart`, `test/features/transactions/transactions_screen_test.dart`

**Interfaces:**
- Consumes: `ApiException.serverMessage` from Task 1.
- Produces: `PendingTransaction.rejection` may now be the empty string, meaning "refused, and the server gave no reason". `isRejected` must stay true for it.

- [ ] **Step 1: Check what `isRejected` does with an empty string**

Read `lib/features/transactions/domain/pending_transaction.dart` and find `isRejected`. If it is `rejection != null`, no change is needed. If it tests for non-emptiness, change it to `rejection != null` and note it in your report — an entry refused without explanation is still refused, and a row that loses its rejection mark would be silently retried by the next drain.

- [ ] **Step 2: Add the string**

`lib/l10n/app_en.arb`, beside `txPendingRejected`:

```json
  "txPendingRefused": "Refused",
  "@txPendingRefused": {},
```

`lib/l10n/app_de.arb`: `"txPendingRefused": "Abgelehnt",`

`lib/l10n/app_it.arb`: `"txPendingRefused": "Rifiutato",`

(Masculine, agreeing with *movimento*, like `txPendingRejected` beside it.)

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter gen-l10n`

- [ ] **Step 3: Write the failing tests**

In `test/features/transactions/transaction_sync_test.dart`, add to the group covering refusals:

```dart
    test('a refusal stores the server own words, not the English half', () async {
      await outbox.add(entry('local-1'));
      when(() => repository.save(any(), splitsTouched: any(named: 'splitsTouched')))
          .thenThrow(
            ValidationException(
              'Amount must be positive',
              serverMessage: 'Amount must be positive',
              statusCode: 422,
            ),
          );

      await sync.drain();

      final all = await outbox.all();
      expect(all.single.rejection, 'Amount must be positive');
    });

    test('a refusal with no server body stores an empty reason, and the '
        'entry is still refused', () async {
      await outbox.add(entry('local-1'));
      when(() => repository.save(any(), splitsTouched: any(named: 'splitsTouched')))
          .thenThrow(const ValidationException('Invalid request'));

      await sync.drain();

      final all = await outbox.all();
      expect(all.single.rejection, '');
      expect(all.single.isRejected, isTrue);
    });
```

Adapt `entry(...)`, `outbox`, `sync` and the `when(...)` stub to the names
already used in that file — read its existing refusal tests first and match
them rather than introducing new fixtures.

In `test/features/transactions/transactions_screen_test.dart`, beside the
existing test for a refused row:

```dart
    testWidgets('a refusal the server did not explain reads "Refused", not '
        '"Refused: "', (tester) async {
      // An empty reason is what the sync stores when the server refused
      // without saying why. Framing it with txPendingRejected would render
      // a dangling colon.
      await pumpWithPending(
        tester,
        [pendingEntry(rejection: '')],
      );
      await tester.pumpAndSettle();

      expect(find.text('Refused'), findsOneWidget);
      expect(find.textContaining('Refused: '), findsNothing);
    });
```

Adapt `pumpWithPending` / `pendingEntry` to that file's existing helpers.

- [ ] **Step 4: Run them and watch them fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transaction_sync_test.dart test/features/transactions/transactions_screen_test.dart`

Expected: FAIL — the sync stores `e.message` (which for a no-body refusal is the English fallback `'Invalid request'`, not `''`), and the row renders `txPendingRejected('')` as `"Refused: "`.

- [ ] **Step 5: Store the server's words**

In `lib/features/transactions/data/transaction_sync.dart`, change both `markRejected` calls (lines 55 and 58) from `e.message` to `e.serverMessage ?? ''`:

```dart
      } on ValidationException catch (e) {
        await _record(
          () => _outbox.markRejected(entry.localId, e.serverMessage ?? ''),
        );
        continue;
      } on ServerException catch (e) {
        await _record(
          () => _outbox.markRejected(entry.localId, e.serverMessage ?? ''),
        );
        continue;
```

Update the doc comment above `drain()` that explains the storing, so it
describes what the code now does: the server's own sentence is stored and
quoted beside the row; an empty reason means it refused without saying why.

- [ ] **Step 6: Render an unexplained refusal**

In `lib/features/transactions/ui/widgets/transaction_list_parts.dart`, replace the `Text` child at lines 317-324 with:

```dart
                            entry.isRejected
                                ? (entry.rejection!.isEmpty
                                      ? L.of(context).txPendingRefused
                                      : L
                                            .of(context)
                                            .txPendingRejected(
                                              entry.rejection!,
                                            ))
                                : L.of(context).txPendingNotSent,
```

- [ ] **Step 7: Take the sync off the allow-list**

In `test/l10n/error_localization_test.dart`, delete the whole
`'lib/features/transactions/data/transaction_sync.dart'` entry from the
`allowed` set — its comment block and the `TODO(cuenti)` inside it. The set
keeps only the `auth_controller.dart` entry.

- [ ] **Step 8: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/ test/l10n/`
Expected: PASS. The guard test now proves the sync no longer reads the English half.

- [ ] **Step 9: Commit**

```bash
git add lib/features/transactions/data/transaction_sync.dart \
        lib/features/transactions/ui/widgets/transaction_list_parts.dart \
        lib/l10n/ test/l10n/error_localization_test.dart \
        test/features/transactions/
git commit -m "fix(transactions): a refusal quotes the server, or says nothing"
```

---

### Task 4: a *Try again* that actually tries again

**Files:**
- Modify: `lib/features/transactions/data/transaction_sync.dart:45-46`
- Modify: `lib/features/transactions/ui/widgets/transaction_list_parts.dart:138-149` (`_retry`)
- Test: `test/features/transactions/transaction_sync_test.dart`

**Interfaces:**
- Consumes: the existing `drain()` single-flight.
- Produces: `Future<int> drainAgain()` on `TransactionSync`.

**Background:** `_drain()` snapshots the outbox with `_outbox.all()` at entry and skips entries carrying a rejection. `_retry` clears the rejection and calls `drain()`. When a drain is already in flight, `drain()` returns that run — whose snapshot still had the entry rejected — so nothing is sent. The row silently changes from "Refused: …" to "Not sent yet" with no request made.

- [ ] **Step 1: Write the failing test**

In `test/features/transactions/transaction_sync_test.dart`:

```dart
  group('drainAgain', () {
    test('a retry during an in-flight drain still sends the entry', () async {
      // The first drain is made slow so the retry lands inside it, which is
      // the case that fails: its snapshot was taken before the rejection
      // was cleared, so joining it sends nothing.
      final gate = Completer<void>();
      var saves = 0;
      when(() => repository.save(any(), splitsTouched: any(named: 'splitsTouched')))
          .thenAnswer((_) async {
            saves++;
            await gate.future;
            return tx(1);
          });

      await outbox.add(entry('slow-one'));
      final first = sync.drain();
      await Future<void>.delayed(Duration.zero);

      // Meanwhile the user clears a rejection and asks again.
      await outbox.add(entry('retried', rejection: null));
      final again = sync.drainAgain();

      gate.complete();
      await first;
      await again;

      expect(saves, 2, reason: 'the retried entry was sent, not skipped');
      expect(await outbox.all(), isEmpty);
    });

    test('a burst of retries queues one follow-up run, not one per tap', () async {
      final gate = Completer<void>();
      var runs = 0;
      when(() => repository.save(any(), splitsTouched: any(named: 'splitsTouched')))
          .thenAnswer((_) async {
            runs++;
            await gate.future;
            return tx(1);
          });

      await outbox.add(entry('one'));
      final first = sync.drain();
      await Future<void>.delayed(Duration.zero);

      final a = sync.drainAgain();
      final b = sync.drainAgain();
      final c = sync.drainAgain();
      expect(identical(a, b), isTrue, reason: 'one follow-up, shared');
      expect(identical(b, c), isTrue);

      gate.complete();
      await Future.wait([first, a, b, c]);

      expect(runs, 1, reason: 'nothing left to send on the follow-up run');
    });

    test('with nothing in flight it behaves exactly like drain', () async {
      await outbox.add(entry('one'));

      expect(await sync.drainAgain(), 1);
      expect(await outbox.all(), isEmpty);
    });
  });
```

Adapt `entry(...)`, `tx(...)`, `outbox`, `sync` and the stub to the file's existing fixtures. Add `import 'dart:async';` if it is not already there.

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transaction_sync_test.dart`
Expected: FAIL — `drainAgain` does not exist (compile error). That is the expected first failure; after Step 3 the first test must fail for the *behavioural* reason if you stub `drainAgain` as an alias for `drain`, which is worth confirming before writing the real one.

- [ ] **Step 3: Add `drainAgain`**

In `lib/features/transactions/data/transaction_sync.dart`, beside `drain()`:

```dart
  Future<int>? _inFlight;
  Future<int>? _queued;

  /// Sends what is queued, joining a run already under way.
  ///
  /// [drain] is what the app's own triggers want: app start, a reconnection
  /// and a manual refresh all mean "catch up", and three of them arriving
  /// together should cost one pass.
  Future<int> drain() =>
      _inFlight ??= _drain().whenComplete(() => _inFlight = null);

  /// Sends what is queued, starting a fresh pass if one is already running.
  ///
  /// A person tapping *Try again* has just changed the queue -- their
  /// entry's rejection was cleared a moment ago. [drain] would hand them
  /// the pass already in flight, and that pass read the outbox before the
  /// change, so it will skip the very entry they asked about: the row goes
  /// from "Refused" to "Not sent yet" with no request made. This waits for
  /// the current pass and then reads the outbox again.
  ///
  /// At most one follow-up is queued, so a burst of taps cannot fan out
  /// into a queue of passes -- they all share the one that will see all of
  /// their changes anyway.
  Future<int> drainAgain() {
    final running = _inFlight;
    if (running == null) return drain();
    return _queued ??= running
        .then((_) => drain())
        .whenComplete(() => _queued = null);
  }
```

Delete the old standalone `_inFlight` declaration if it sat elsewhere in the class, so there is exactly one.

- [ ] **Step 4: Point `_retry` at it**

In `lib/features/transactions/ui/widgets/transaction_list_parts.dart`, in `_retry`, change `drain()` to `drainAgain()`:

```dart
      await ref.read(transactionSyncProvider).drainAgain();
```

and extend the doc comment above `_retry` with the reason:

```dart
  /// Clears the rejection and asks the sync to try again. Uses
  /// `drainAgain` rather than `drain`: a pass already in flight read the
  /// outbox before the rejection was cleared and would skip this entry.
```

- [ ] **Step 5: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/transactions/data/transaction_sync.dart \
        lib/features/transactions/ui/widgets/transaction_list_parts.dart \
        test/features/transactions/transaction_sync_test.dart
git commit -m "fix(transactions): Try again starts a pass that can see it"
```

---

### Task 5: an unreadable queue must not sign out quietly

**Files:**
- Modify: `lib/features/transactions/data/transaction_outbox.dart:41-50` (`openOrFallback`) and the class's fields
- Modify: `lib/features/auth/ui/sign_out.dart:27-37` (`confirmSignOut`)
- Modify: `lib/l10n/app_en.arb`, `app_de.arb`, `app_it.arb`
- Test: `test/features/transactions/transaction_outbox_test.dart`, `test/features/user/settings_screen_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `TransactionOutbox.isFallback` (a `bool`, false by default, true only for the store `openOrFallback` builds after a failure).

**Background:** `openOrFallback` falls back to a temp directory with only a `debugPrint`. When app-support is transiently unavailable at launch, the app starts on an empty temp queue while the real store still holds entries — and sign-out then tells the user nothing is unsent. That is the exact lie the offline feature exists to prevent.

- [ ] **Step 1: Add the string**

`lib/l10n/app_en.arb`, beside `logoutPendingTitle`:

```json
  "logoutPendingUnknown": "Your unsent transactions could not be read. Signing out will discard anything still waiting.",
  "@logoutPendingUnknown": {},
```

`lib/l10n/app_de.arb`:

```json
  "logoutPendingUnknown": "Nicht gesendete Buchungen konnten nicht gelesen werden. Beim Abmelden geht alles noch Wartende verloren.",
```

`lib/l10n/app_it.arb`:

```json
  "logoutPendingUnknown": "Non è stato possibile leggere le operazioni non inviate. Uscendo andrà perso tutto ciò che è ancora in attesa.",
```

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter gen-l10n`

- [ ] **Step 2: Write the failing tests**

In `test/features/transactions/transaction_outbox_test.dart`:

```dart
  test('a store opened normally is not a fallback', () {
    expect(TransactionOutbox(dir).isFallback, isFalse);
  });
```

In `test/features/user/settings_screen_test.dart`, in the sign-out group:

```dart
    testWidgets('a queue that could not be read is still asked about, even '
        'though it looks empty', (tester) async {
      // The fallback store is empty because the real one could not be
      // opened -- not because there is nothing unsent. Signing out without
      // asking would discard whatever the real store holds.
      final auth = await pumpSettings(
        tester,
        outboxDir: outboxDir,
        outboxIsFallback: true,
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Logout'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('could not be read'),
        findsOneWidget,
      );
      expect(auth.logoutCalls, 0);
    });
```

`pumpSettings` gains an `outboxIsFallback` flag that overrides
`transactionOutboxProvider` with a store built as a fallback. Extend that
helper the way its `outboxDir` parameter is already threaded.

- [ ] **Step 3: Run them and watch them fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transaction_outbox_test.dart test/features/user/settings_screen_test.dart`
Expected: FAIL — `isFallback` does not exist, and an empty queue signs out without asking.

- [ ] **Step 4: Flag the fallback store**

In `lib/features/transactions/data/transaction_outbox.dart`, give the class the flag and thread it through the constructor:

```dart
  TransactionOutbox(this._directory, {this.isFallback = false});

  /// True when this store is the temp-directory fallback rather than the
  /// real one, which means an empty queue is "could not be read", not
  /// "nothing is waiting". The sign-out flow must not treat the two alike.
  final bool isFallback;
```

and in `openOrFallback`, build the fallback with it:

```dart
      return TransactionOutbox(dir, isFallback: true);
```

- [ ] **Step 5: Ask when the queue is unreadable**

In `lib/features/auth/ui/sign_out.dart`, replace the body of `confirmSignOut`:

```dart
Future<bool> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final outbox = ref.read(transactionOutboxProvider);
  final pending = await outbox.all();
  if (!context.mounted) return false;
  // An empty fallback store means the real one could not be opened, not
  // that nothing is waiting -- so it is exactly the case that must ask.
  if (pending.isEmpty && !outbox.isFallback) return true;
  return showConfirmSheet(
    context,
    title: L.of(context).logoutPendingTitle,
    message: outbox.isFallback
        ? L.of(context).logoutPendingUnknown
        : L.of(context).logoutPendingBody(pending.length),
    confirmLabel: L.of(context).actionLogout,
  );
}
```

- [ ] **Step 6: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/ test/features/user/ test/screens/ test/l10n/`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/transactions/data/transaction_outbox.dart \
        lib/features/auth/ui/sign_out.dart lib/l10n/ \
        test/features/transactions/transaction_outbox_test.dart \
        test/features/user/settings_screen_test.dart
git commit -m "fix(auth): a queue that cannot be read is not an empty queue"
```

---

### Task 6: three small corrections

**Files:**
- Modify: `lib/features/user/ui/settings_screen.dart:66-74`
- Modify: `lib/features/transactions/ui/transactions_controller.dart:304-320` (`delete`)
- Modify: `lib/features/auth/ui/auth_controller.dart:40` (the `build` microtask)
- Modify: `lib/core/api/api_client.dart:26` and `lib/main.dart:104-109` (comments only)
- Test: `test/features/user/settings_screen_test.dart`, `test/features/transactions/transactions_controller_test.dart`

**Interfaces:** none produced or consumed.

These are three independent corrections plus one comment pair. Each is small; they are one task because none carries its own review surface.

- [ ] **Step 1: Write the failing test for the delete rollback**

In `test/features/transactions/transactions_controller_test.dart`:

```dart
    test('an outbox failure after an accepted delete does not put the row '
        'back', () async {
      // The server has already accepted the delete. An outbox problem
      // while tidying up a stale queued edit must not be reported as a
      // failed delete, and must not restore a row that is gone.
      when(() => repository.delete(7)).thenAnswer((_) async {});
      when(outbox.all).thenThrow(const FileSystemException('gone'));

      final outcome = await controller.delete(7);

      expect(outcome, SaveOutcome.sent);
      expect(
        container.read(controllerProvider).value!.items.map((t) => t.id),
        isNot(contains(7)),
      );
    });
```

Adapt `controller`, `container`, `repository`, `outbox` and `controllerProvider` to the fixtures that file already uses. Import `dart:io` for `FileSystemException` if needed.

- [ ] **Step 2: Run it and watch it fail**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/transactions_controller_test.dart`
Expected: FAIL — the outbox read sits inside `delete()`'s `try`, whose `catch` restores the pre-delete state and rethrows, so the row comes back and the call throws.

- [ ] **Step 3: Move the outbox cleanup out of the rollback's reach**

In `lib/features/transactions/ui/transactions_controller.dart`, in `delete`, wrap only the cleanup:

```dart
      await ref.read(transactionsRepositoryProvider).delete(id);
      // An edit of this row may still be queued from an offline spell.
      // Left there, the next drain PUTs a transaction the server no longer
      // has, takes a 404 and marks the entry refused -- and mergePending
      // only overlays updates onto rows the server still returns, so that
      // entry could never be shown, retried or discarded again. Its one
      // remaining effect would be a phantom in the sign-out warning.
      //
      // Guarded on its own: the server has already accepted the delete, so
      // a storage problem here is not a failed delete and must not roll the
      // row back on screen.
      try {
        final queued = await _queuedIdFor(id);
        if (queued != null) {
          await ref.read(transactionOutboxProvider).remove(queued);
        }
      } on Exception catch (e) {
        debugPrint('TransactionsController: stale queued edit left behind: $e');
      }
```

Add `import 'package:flutter/foundation.dart';` if `debugPrint` is not already imported.

- [ ] **Step 4: Restore the mounted guard on the settings sign-out**

In `lib/features/user/ui/settings_screen.dart`, in the button's `onPressed`, add the guard the drawer path already has:

```dart
          final router = GoRouter.of(context);
          if (!await confirmSignOut(context, ref)) return;
          if (!context.mounted) return;
          await signOut(ref);
          router.go('/login');
```

- [ ] **Step 5: Stop swallowing a failed auth init**

In `lib/features/auth/ui/auth_controller.dart`, replace the bare microtask in `build` (line 40):

```dart
    // A throw here used to vanish into an unhandled async error. `init()`
    // sets `initialized`, which gates the app-start outbox drain, so a
    // silent failure here is a startup that quietly never syncs.
    unawaited(
      Future.microtask(init).catchError((Object e, StackTrace s) {
        debugPrint('AuthController: init failed: $e\n$s');
      }),
    );
```

Add `import 'package:flutter/foundation.dart';` if `debugPrint` is not already imported. Do NOT change the gate itself — it is correct, and loosening it reopens the startup race it was added to close.

- [ ] **Step 6: Record that the two halves of the startup fix hold each other up**

`lib/core/api/api_client.dart:26`, on the `BaseOptions` line:

```dart
      // A non-empty default so a request composed before init() cannot go
      // nowhere. Nothing composes one today -- main.dart gates the startup
      // drain on auth being initialised -- and if that gate is ever
      // loosened, this default is what such a request would reach.
```

`lib/main.dart`, on the gate:

```dart
    // Held until the client knows its server: a drain composed before
    // ApiClient.init() would go out against the default baseUrl in
    // api_client.dart and be refused, and a refused entry is never retried
    // automatically.
```

- [ ] **Step 7: Run and watch it pass**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/features/transactions/ test/features/user/ test/features/auth/ test/main_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/user/ui/settings_screen.dart \
        lib/features/transactions/ui/transactions_controller.dart \
        lib/features/auth/ui/auth_controller.dart \
        lib/core/api/api_client.dart lib/main.dart \
        test/features/transactions/transactions_controller_test.dart
git commit -m "fix: three corrections around sign-out, delete and startup"
```

---

### Task 7: the whole gate

**Files:** none — this task only runs and reports.

- [ ] **Step 1: Regenerate anything generated**

Run: `export PATH="$HOME/flutter/bin:$PATH" && dart run build_runner build && flutter gen-l10n`

Commit any generated churn on its own so it does not hide inside a behaviour change:

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

Expected: all four clean. Test count should exceed the 1035 baseline by the tests added here. Report the final number and the coverage figure.
