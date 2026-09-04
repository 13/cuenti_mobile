# Error display, and the offline-transactions follow-ups

## Why

`ApiException.fromDio` computes the server's own explanation and then throws
it away. At `api_exception.dart:20-24` it derives `serverMessage` from the
response body, and at lines 26, 30, 34 and 36 it passes that string as the
**positional `message`** argument — never as `serverMessage:`, and never with
`statusCode:`. Both named fields are therefore null on every exception the
app has ever raised from a Dio failure.

Three consequences, all live in production today:

1. `localizedMessage`'s documented promise — *"A server that explained itself
   is quoted verbatim"* (`api_exception.dart:56-58`) — never happens. Every
   server explanation is replaced by a generic translated string on every
   error path in the app.
2. `statusCode == 403 → l.errorApiDisabled` (`:68`) is unreachable. A
   self-hoster who has not enabled the API sees "Not authenticated" and is
   sent looking for a password problem they do not have.
3. `ServerException`'s `statusCode == null` branch (`:73-75`) always wins, so
   every 5xx reports "Unexpected response from server" and `errorServer(status)`
   — a string that exists in all three catalogues — is never shown.

This was found while building offline-safe transactions, judged out of scope
there, and left with a TODO at `test/l10n/error_localization_test.dart:33-37`.
This spec closes it, and clears the two follow-up items that branch parked.

## Scope

Three independent tracks. They share no code and can be built and reviewed
separately; they are one spec because they are one cleanup.

- **Track 1** — `fromDio` and the display policy. App-wide.
- **Track 2** — a per-row *Try again* that can silently do nothing.
- **Track 3** — five small parked rough edges.

## Track 1: what the user sees when a request fails

### The decision

Threading the two fields through `fromDio` is four lines. The question that
matters is what `localizedMessage` should then return, because the moment
`serverMessage` is populated, line 61 returns it verbatim for every error
carrying a body — and a German or Italian user starts seeing raw server text
where they get a clean translation today. Fixing the plumbing without
deciding the policy trades a silent bug for a visible regression.

**Decision: a translated frame around the server's own sentence**, and only
where that sentence is actionable.

This is not a new pattern. The offline-transactions branch already ships it:
`txPendingRejected` is `"Refused: {reason}"` in English, `"Abgelehnt:
{reason}"` in German — a translated frame quoting the server verbatim inside
it. Track 1 extends that same shape to the error path.

Applied to `ValidationException` and `ServerException` only. A 401's "Not
authenticated" or a connection failure's message from the server adds nothing
over the translated string, and 403 has a specific translated string that is
better than anything the server will say.

### Behaviour

| Exception | Server sent a body | Server sent nothing |
|---|---|---|
| `NetworkException` (certificate) | `errorCertificate` | `errorCertificate` |
| `NetworkException` (other) | `errorNetwork` | `errorNetwork` |
| `UnauthorizedException`, 401, login endpoint | `errorInvalidCredentials` | `errorInvalidCredentials` |
| `UnauthorizedException`, 403 | `errorApiDisabled` | `errorApiDisabled` |
| `UnauthorizedException`, other 401 | `errorNotAuthenticated` | `errorNotAuthenticated` |
| `ValidationException` | `errorInvalidRequestDetail(detail)` | `errorInvalidRequest` |
| `ServerException`, status known | `errorServerDetail(status, detail)` | `errorServer(status)` |
| `ServerException`, status unknown | `errorUnexpectedResponse` | `errorUnexpectedResponse` |
| `UnknownApiException` | `errorUnknown` | `errorUnknown` |

The 403 and known-status rows are the two that are unreachable today.

### Changes

**`fromDio`** passes `serverMessage:` and `statusCode:` alongside the
positional `message` on all four `badResponse` returns. `message` keeps its
current value — it is "English, for logs and tests" and nothing about its
role changes.

**Truncation.** `serverMessage` is now shown to users, and the body it comes
from is not always a sentence: a misconfigured reverse proxy returns an HTML
error page, which `api_exception.dart:22` accepts whole. Truncate to 200
characters with an ellipsis at the point of construction in `fromDio`, so
every consumer — the UI and the outbox's stored rejection reason — benefits
from one rule. This also closes a minor parked during the offline branch
(an unbounded refusal reason rendered inside a row).

> **Amended by the final review: truncation was the wrong answer for the
> case that motivated it.** Cutting an HTML error page to 200 characters
> bounds its length but not its content — the user still gets raw markup and
> literal newlines wrapped over six lines of a four-second snackbar, which is
> worse than the plain `Server error (502)` it displaces. A string body that
> opens with `<` is a page, not a sentence, and is dropped outright
> (`serverMessage == null`); the body is trimmed first, so an all-whitespace
> one is dropped too. The 200-character cap stays, now justified by what it
> actually bounds: a long plain-text body such as a stack trace.

**New l10n keys**, in `app_en.arb`, `app_de.arb` and `app_it.arb`:

| Key | en | de | it |
|---|---|---|---|
| `errorInvalidRequestDetail` | `Invalid request: {detail}` | `Ungültige Anfrage: {detail}` | `Richiesta non valida: {detail}` |
| `errorServerDetail` | `Server error ({status}): {detail}` | `Serverfehler ({status}): {detail}` | `Errore del server ({status}): {detail}` |
| `txPendingRefused` | `Refused` | `Abgelehnt` | `Rifiutato` |

`errorInvalidRequestDetail` needs `"placeholders": {"detail": {"type": "String"}}`;
`errorServerDetail` needs both `status` and `detail` as `String`.
`txPendingRefused` takes no placeholder. Italian `Rifiutato` is masculine, to
agree with *movimento*, matching the correction already made to
`txPendingRejected`.

Track 3 adds one more, for the unreadable-queue case described there:

| Key | en | de | it |
|---|---|---|---|
| `logoutPendingUnknown` | `Your unsent transactions could not be read. Signing out will discard anything still waiting.` | `Nicht gesendete Buchungen konnten nicht gelesen werden. Beim Abmelden geht alles noch Wartende verloren.` | `Non è stato possibile leggere le operazioni non inviate. Uscendo andrà perso tutto ciò che è ancora in attesa.` |

> **Superseded twice — the shipped wording is not the one above.** Ruling R7
> found the original text false: sign-out clears the store it was *given*,
> and the store it is given when the real one cannot be opened is the empty
> fallback, so nothing "still waiting" is discarded at all. The text became
> `Your unsent transactions could not be read. They will stay on this device
> rather than being discarded, and may be sent later.` (de: `… Sie bleiben
> auf diesem Gerät, statt verworfen zu werden, und werden möglicherweise
> später gesendet.`; it: `… Rimarranno su questo dispositivo invece di essere
> scartate e potrebbero essere inviate più tardi.` — *scartate*, not
> *eliminate*, to agree with the *Scarta* button the user is looking at).
>
> The final review then found that R7 had only considered an *empty*
> fallback store. The fallback directory is a stable path, so a session that
> starts in fallback queues into it and signs out with entries that really
> are discarded. `confirmSignOut` therefore chooses on both facts, not on
> `isFallback` alone: `logoutPendingUnknown` only when the store is a
> fallback **and** empty, `logoutPendingBody(count)` otherwise. No new
> string; the honest count came back for the case that has one.

**Retiring the allow-list entry.** `transaction_sync.dart` sits on the l10n
guard's allow-list only because this bug forced it to store `e.message`. With
`serverMessage` real, it stores `e.serverMessage ?? ''` instead and comes off
the list genuinely — the guard bans `.message` in UI layers and the sync will
no longer contain it. An empty stored reason means "the server refused but
said nothing", and the row renders `txPendingRefused` rather than
`txPendingRejected('')`, which today would read `"Refused: "`. Delete the
TODO at `error_localization_test.dart:33-37` and the allow-list entry with it.

### Testing

The current suite never asserts what a user in a non-English locale actually
sees for a failed request with a body — which is why this survived. Required:

- `fromDio` populates `serverMessage` and `statusCode` for each of 401, 403,
  a 4xx and a 5xx, from both body shapes (`{'error': ...}` and a bare string).
- `localizedMessage` returns each row of the behaviour table above, asserted
  against German or Italian, not only English — an assertion that passes in
  English alone cannot tell a translated frame from a verbatim quote.
- A 403 yields `errorApiDisabled`, and a 500 yields `errorServer('500')`.
  Both fail before the fix; they are the two dead branches.
- An over-long body is truncated, and the truncation is visible in what the
  user is shown.
- A refused queued transaction with no server body renders `txPendingRefused`,
  not `Refused: `.
- The existing l10n guard test still passes with the allow-list entry removed.

## Track 2: a *Try again* that silently does nothing

`TransactionSync.drain()` is single-flight: `_inFlight ??= _drain().whenComplete(...)`
(`transaction_sync.dart:45-46`). `_drain()` snapshots the outbox with
`_outbox.all()` at entry and skips entries carrying a rejection.

`TransactionTile._retry` (`transaction_list_parts.dart:138-149`) clears the
rejection and then calls `drain()`. If a drain is already in flight, the
retry joins that run — whose snapshot still had this entry marked rejected —
so nothing is sent. The row changes from "Refused: …" to "Not sent yet" and
no request is made. It self-heals at the next drain trigger, and nothing is
lost, but the button appears to work and does not.

**Fix:** a `drainAgain()` that starts a fresh run after the in-flight one
rather than joining it — when `_inFlight != null`, chain a follow-up run onto
it and return that; otherwise behave exactly as `drain()`. At most one
follow-up is queued, so a burst of retries cannot fan out into a queue of
runs. `_retry` calls `drainAgain()`; the other three trigger sites keep
`drain()`, since coalescing is exactly what they want.

**Testing:** a retry issued while a drain is in flight sends the entry —
failing before the fix. And a burst of retries during one in-flight drain
produces one follow-up run, not one per tap.

## Track 3: the five parked rough edges

Each is small, independent, and currently harmless-but-wrong.

1. **The missing `context.mounted` guard.** `settings_screen.dart:71-72`
   calls `confirmSignOut(context, ref)` and then `signOut(ref)` with no
   mounted check between, so `signOut` can `ref.read` on a disposed
   `ConsumerWidget` ref. The drawer path guards this (`shell_screen.dart:227`);
   the settings path lost the guard in the refactor that shared the flow.
   Add it back.

2. **An outbox failure rolling back an accepted delete.**
   `transactions_controller.dart:312-315` reads and removes the queued entry
   *inside* `delete()`'s `try`, whose `catch` restores the pre-delete state
   and rethrows. An outbox I/O failure therefore puts the row back on screen
   and reports an error after the server has already accepted the delete.
   Move the outbox cleanup out of the guarded block, or guard it separately —
   the server write has already succeeded and must not be reported as failed.

3. **A startup drain that never fires.** The app-start drain is gated on
   `AuthState.initialized` (`main.dart:104-109`), which `auth_controller.dart:82`
   sets only at the end of `_init()`. Any throw inside `_init()` leaves it
   false permanently, and `_initFuture` memoises the failed run so it never
   retries. Reconnect and manual refresh still drain, so nothing is lost.

   The gate stays as it is — it is correct, and loosening it reopens the
   startup race it was added to close. What changes is that the failure stops
   being invisible: `AuthController.build`'s `unawaited(Future.microtask(init))`
   currently drops a thrown `_init()` into an unhandled async error with no
   log of its own. Attach a handler that logs the failure with its exception.
   Diagnosability is the whole change; no behaviour moves.

4. **The silent temp fallback.** `TransactionOutbox.openOrFallback()`
   (`transaction_outbox.dart:41-50`) falls back to a temp directory with only
   a `debugPrint`. If app-support is transiently unavailable at launch, the
   app starts with an apparently empty queue while the real store still holds
   entries — and the sign-out warning then says nothing is unsent, which is
   the one lie this whole feature exists to prevent.

   The fallback itself stays: it exists so the app starts at all, and that
   trade is right. What must not stand is the empty queue being presented as
   the truth. `TransactionOutbox` gains an `isFallback` flag, set by
   `openOrFallback` when it takes the temp path, and `confirmSignOut`
   (`sign_out.dart:27-37`) asks for confirmation whenever it is set — even
   with an empty queue — using a message that says the unsent transactions
   could not be read rather than naming a count. An unreadable queue is
   exactly the case where signing out must not proceed unasked.

5. **The load-bearing default `baseUrl`.** `api_client.dart:26` now sets a
   non-empty default so a pre-init request cannot go nowhere. Combined with
   the startup gate, a request composed before `init()` would reach the
   default host with a bearer token attached. No such caller exists today —
   the gate removed the only one — but the two halves are now load-bearing on
   each other with nothing recording that. A comment on each naming the other
   is enough; this is documentation, not a code change.

## Out of scope

- Any change to `message`'s role. It stays the English half for logs and tests.
- Retrying rejected outbox entries automatically. A refusal still waits for a
  person, as the offline spec decided.
- The server-side idempotency key that would close the parked duplicate-create
  window (R7). Still a backend change.
- The remaining deferred minors from the offline branch not listed in Track 3
  (duplicate list keys on pending creates, the logout TOCTOU, `mergePending`'s
  force-unwrap, `_queuedIdFor`'s double read, test-fake duplication).

## Constraints

- Every new user-facing string goes in all three of `app_en.arb`, `app_de.arb`,
  `app_it.arb`, then `flutter gen-l10n`. `test/l10n/translations_test.dart`
  enforces parity.
- After touching a `@freezed` or `@riverpod` file, run
  `dart run build_runner build --delete-conflicting-outputs`.
- Full gate: `flutter analyze`, `dart format --output=none
  --set-exit-if-changed lib test integration_test tool`, `flutter test`,
  `dart run tool/check_coverage.dart 80`. Baseline is 1035 tests passing.
- Never re-inspect `DioExceptionType` outside `api_exception.dart`.
