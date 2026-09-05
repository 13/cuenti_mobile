# The outbox knows whose it is

## Why

The transaction outbox holds writes the server has never seen. Sign-out
clears it, and that clearing is the only thing standing between one
account's unsent transactions and another account's books. It is not
enough, because it assumes sign-out is the only way the app changes hands.
Two paths reach a new account with a stale queue still on disk.

**Door 1 — the fallback store.** When `getApplicationSupportDirectory()`
fails or hangs, `TransactionOutbox.openOrFallback()` returns a temp-directory
store so the app can start (`transaction_outbox.dart:45-55`). Sign-out then
clears *that* store; the real app-support store is never opened, so its
entries survive untouched. A later successful open finds them and drains
them into whoever is signed in then.

**Door 2 — session expiry.** `AuthController._handleSessionExpired`
deliberately keeps the outbox: the session expired, the user did not ask to
be forgotten, and their unsent work should still be there when they sign
back in. That reasoning is right. But it drops the user at the login screen,
and nothing enforces that the next person to sign in is the same user. Token
expiry is routine, so this door is the more likely of the two — it needs no
failure at all.

An app kill between queueing and sign-out reaches the same place by a third
route.

The common cause is that a queue on disk has no idea who it belongs to. Both
doors close, and the third route with them, if it does.

## Decision

**The outbox records its owner, and refuses to be read by anyone else.**

Clearing at sign-out stays as it is — it is the ordinary, correct path. What
changes is that correctness no longer depends on the clearing having
happened. This turns `_handleSessionExpired`'s "keep the outbox" from right
by assumption into right by enforcement, which is the argument for doing it
this way rather than patching sign-out alone.

Rejected: patching sign-out to best-effort open the real store and clear it.
Five lines, closes door 1, leaves door 2 — the likelier one — wide open.

Rejected: stamping every `PendingTransaction` with its owner. More precise —
it could send A's entries when A returns while B's flow normally — but it
needs a freezed field, a JSON migration for existing entries, and per-entry
UI. One owner per queue is the real case; the queue is short-lived by design.

## The account key

```
<server base URL>#<identity>
```

`identity` is `UserProfile.id` as a string when it is non-null, else
`UserProfile.username` when non-empty. The server URL comes from
`ApiClient.baseUrl` (`api_client.dart:137`), and it belongs in the key
because this app is self-hosted: the same user id on two different servers is
two different accounts.

When no user is signed in, or when a profile has neither an id nor a
username, there is **no** current account key. That is a distinct state from
"a key that does not match", and it seals the queue the same way — see below.

## Where the owner lives

`owner.json` beside the entries, holding `{"account": "<key>"}`. One file, no
model change, no `build_runner` run.

Absent `owner.json` means "unowned": either a fresh queue or one written by a
version before this change.

## When it is written

When the queue goes from empty to non-empty. A queue with nothing in it has
no owner and needs none. `TransactionsController._enqueue`
(`transactions_controller.dart:255`) is the single place entries are added,
so it claims ownership there.

## Reading: one door in, and a guard that keeps it that way

Three places read the outbox today — `TransactionSync.drain()`,
`TransactionsController.mergePending`, and `confirmSignOut` — and a fourth
would be easy to add without noticing the rule.

Rather than repeat the check three times, all reads go through one helper
file, `lib/features/transactions/data/outbox_ownership.dart`:

- `Future<List<PendingTransaction>> ownedEntries(Ref ref)` — the entries, or
  an empty list when the queue's owner is not the current account key
  (including when there is no current key).
- `Future<List<PendingTransaction>> entriesIgnoringOwner(Ref ref)` — every
  entry regardless of owner. Exactly one caller: the dialog that asks the
  user what to do about a queue that is not theirs.
- `Future<void> claimIfUnowned(Ref ref)` — writes the current key when the
  queue has no owner.

> **Superseded during execution, and removed.** `claimIfUnowned` only ever
> claimed an *unowned* queue; it had nothing to say about a queue owned by
> someone else, because at the time one was never written by a second
> account in the first place. `claimForWriting` replaced it once sidelining
> was added: on a write, a foreign or unreadable owner is set aside
> (`TransactionOutbox.sideline`) before the current account claims the now
> empty root, and any queue that account had set aside earlier is reclaimed
> onto it in the same step. `claimIfUnowned` had no caller left once
> `claimForWriting` covered its case, and was deleted.

`TransactionOutbox` itself stays a dumb store: it gains `owner` and
`setOwner` and its `all()` keeps returning everything. A store whose `all()`
silently omits rows is a store that lies; the filtering belongs above it,
named.

### Sign-out must warn about exactly what it deletes

`confirmSignOut` counts `ownedEntries`, and `signOut` therefore must not call
`clear()`, which deletes the directory wholesale including a foreign queue
the user was never told about. That would recreate the defect this project
just fixed on the previous branch — a message describing one thing while the
code does another.

So sign-out **clears only an owned queue**: if `ownedEntries` is non-empty it
clears, and if the queue is foreign it is left alone, still sealed and still
harmless. Leaving it is safe precisely because ownership is enforced on the
read path; deleting another account's data is not sign-out's business.

**A structural guard test** — `test/features/transactions/outbox_reads_test.dart`
— bans `\.all\(\)` on an outbox outside `outbox_ownership.dart`, in the same
blunt style as `test/l10n/error_localization_test.dart`, with the same kind of
documented allow-list. That test is what keeps the fourth reader honest.

## What the user sees

Foreign entries are never sent and never rendered. The second half matters as
much as the first: entries carry amounts and payees, so displaying another
account's queue is its own small privacy failure, distinct from sending it.

The check runs once per arrival at a signed-in state: after
`_persistSuccessfulLogin` on a fresh sign-in, and after `AuthController._init`
restores a saved session. Both funnel into one call so there is a single
place to read. It runs after the account key is knowable and before the
app-start drain, which is already gated on `initialized`.

When it finds a queue that is not the new account's, the user is asked once.
Two cases, two messages, one sheet:

| Case | Message | Buttons |
|---|---|---|
| Owner recorded, different account | `{count} unsent transactions belong to a different account. They will not be sent.` | Discard / Keep |
| No owner recorded, queue non-empty (upgrade) | `{count} unsent transactions were saved before this version. Send them as {account}, or discard them?` | Send as this account / Discard |

Declining either leaves the queue sealed rather than sent. **The answer is
never load-bearing for correctness** — `ownedEntries` is. The dialog exists so
the user knows, not so the code is safe.

New strings in all three catalogues:

| Key | en | de | it |
|---|---|---|---|
| `outboxForeignTitle` | `Unsent transactions from another account` | `Nicht gesendete Buchungen eines anderen Kontos` | `Operazioni non inviate di un altro account` |
| `outboxForeignBody` | `{count} unsent transactions belong to a different account. They will not be sent.` | `{count} nicht gesendete Buchungen gehören zu einem anderen Konto. Sie werden nicht gesendet.` | `{count} operazioni non inviate appartengono a un altro account. Non verranno inviate.` |
| `outboxUnknownTitle` | `Unsent transactions from an earlier version` | `Nicht gesendete Buchungen aus einer früheren Version` | `Operazioni non inviate di una versione precedente` |
| `outboxUnknownBody` | `{count} unsent transactions were saved before this version. Send them as {account}, or discard them?` | `{count} nicht gesendete Buchungen wurden vor dieser Version gespeichert. Als {account} senden oder verwerfen?` | `{count} operazioni non inviate sono state salvate prima di questa versione. Inviarle come {account} o scartarle?` |
| `outboxKeep` | `Keep` | `Behalten` | `Mantieni` |
| `outboxSendAsThisAccount` | `Send as this account` | `Als dieses Konto senden` | `Invia come questo account` |

> **Corrected by the final review: the Italian above is not what shipped.**
> *Operazione* is generic banking language; this app calls a transaction
> *movimento* everywhere else in the Italian catalogue, and a transaction
> is masculine (*movimento*, not *operazione*). The final review changed
> the four Italian strings above that said *operazione*/*operazioni*
> (`outboxForeignTitle`, `outboxForeignBody`, `outboxUnknownTitle`,
> `outboxUnknownBody`) to *movimento*/*movimenti*, and went further on the
> two body strings: each grew an ICU plural (`=1{…} other{…}`) and more
> detail than the table shows. `lib/l10n/app_it.arb` is the authority for
> the wording that actually ships.

`outboxForeignBody` needs `count` as `int`; `outboxUnknownBody` needs `count`
as `int` and `account` as `String`. Discard reuses the existing
`txDiscardPending` (*Scarta* in Italian, matching the row button).

## Existing installs

An absent owner with a non-empty queue is the upgrade case, and the honest
answer is that the app does not know whose it is — so it asks, offering to
adopt or discard. An absent owner with an empty queue is claimed silently on
the next enqueue. No migration step runs at startup; the question is asked
when it becomes relevant, at sign-in.

## Testing

Both doors get a named test, because both are the point:

- **Door 1.** A real store holding entries owned by account A survives a
  fallback sign-out; account B signs in; `ownedEntries` is empty, `drain()`
  sends nothing, and the list shows nothing.
- **Door 2.** `_handleSessionExpired` keeps the queue; a *different* account
  signs in; same three assertions.
- The same account signing back in after expiry still sees and sends its
  queue — this is what proves the guard reads the key rather than sealing
  everything.
- A server change alone (same user id, different base URL) counts as a
  different account.
- Upgrade: no `owner.json` and a non-empty queue asks; adopting makes the
  entries sendable; discarding empties the store.
- `drain()` refuses a foreign queue even when called directly, with no dialog
  involved.
- The structural guard test fails when a `.all()` call is added outside
  `outbox_ownership.dart`.

## Also in this change

Two chores, unrelated to ownership but open on the same ledger:

1. **Drop `--delete-conflicting-outputs`.** `build_runner` now prints
   `W These options have been removed and were ignored` on every codegen run.
   Remove the flag from `CLAUDE.md`, both plans under
   `docs/superpowers/plans/`, and any other documented command.
2. **The l10n guard does not scan `lib/core`.** `test/l10n/error_localization_test.dart`
   checks `lib/features` and `lib/screens`, but the shared error-display
   widgets now live in `lib/core/widgets` (`feedback_snack.dart:82`,
   `entity_edit_sheet.dart:90`). Add `lib/core` to the scanned list; it needs
   one allow-list entry for `lib/core/api/api_exception.dart`, which reads
   `e.message` off a `DioException` legitimately.

## Out of scope

- Per-entry ownership.
- Merging a fallback store's entries into the real store when it becomes
  available. Related, and worth its own decision later.
- Any change to what sign-out clears, or to `_handleSessionExpired`'s
  decision to keep the queue. This change makes that decision safe; it does
  not revisit it.

## Constraints

- Every new string in `app_en.arb`, `app_de.arb` and `app_it.arb`, then
  `flutter gen-l10n`; `test/l10n/translations_test.dart` enforces parity.
- Italian calls a transaction *movimento* (masculine); *Scarta* is discard,
  *Elimina* is delete.
- Never re-inspect `DioExceptionType` outside `api_exception.dart`.
- Full gate: `flutter analyze`, `dart format --output=none
  --set-exit-if-changed lib test integration_test tool`, `flutter test`,
  `dart run tool/check_coverage.dart 80`. Baseline 1067 tests passing.
