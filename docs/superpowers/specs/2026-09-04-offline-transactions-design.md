# Offline-safe transactions (local queue + sync)

**Date:** 2026-09-04
**Status:** Approved

## Goal

A transaction entered without a connection is kept and sent later, instead of
failing at the Save button. The person entering it can see that it has not
been sent yet, and is told if the server later refuses it.

Today the app survives being offline only for *reading*:
`OfflineCacheInterceptor` replays the last successful GET per endpoint. Every
write goes straight to the server and fails outright when it cannot be
reached. This adds the write half, for transactions.

## Decisions

| Question | Decision |
|---|---|
| What can be queued? | Transaction create, update and delete. Nothing else. |
| Creating a category or payee offline? | No. Their create rows are hidden while offline, so a queued transaction can only ever reference ids the server already has. |
| Do queued transactions show in the list? | Yes, in date order, marked as not yet sent. |
| Server refuses a queued write at sync? | The entry stays, marked with the server's reason, offering Edit and Discard. |
| Account balances while something is pending? | Left as the server reports them. Not adjusted locally. |
| Two devices editing the same transaction? | Last write wins, exactly as today. No merge. |
| Where does the queue live? | An explicit outbox the controller consults — not inside the repository, not a Dio interceptor. |

## Why an explicit outbox

Three places the queue could live:

**Inside `TransactionsRepository`.** `save()` would enqueue when the network
fails, leaving call sites untouched. Rejected: a caller that gets a
`Transaction` back could no longer tell whether it reached the server, and
saying exactly that is the whole feature.

**As a Dio interceptor** replaying failed write requests. Rejected: it queues
bytes, not transactions. It could not render a pending row, could not explain
a rejection in domain terms, and would replay a body that may have gone stale.
Its generality buys nothing once the scope is transactions only.

**An explicit outbox (chosen).** The controller knows whether a save was sent
or queued and can say so; the list can merge pending entries because they are
real `Transaction`s; a rejection carries the server's own message.

## Model

```dart
enum PendingOperation { create, update, delete }

class PendingTransaction {
  final String localId;        // stable key before a server id exists
  final PendingOperation operation;
  final Transaction transaction;
  final DateTime queuedAt;
  final String? rejection;     // the server's reason, once refused
}
```

`localId` is not decoration. `TransactionsController` dedupes on `id` and keys
rows by it, and its own comment notes that *duplicate nulls collide on
`ValueKey` just the same*. A pending create has no server id, so it needs a key
of its own or the list will collide the moment there are two of them.

## Components

**`TransactionOutbox`** — durable storage, one JSON file per entry in the
app-support directory. This is the pattern `ResponseCache` already uses
(`getApplicationSupportDirectory`, JSON per key, not purged behind the app's
back); no new storage story is introduced. Operations: `add`, `all`, `remove`,
`replace`, `markRejected`, `clear`.

The queue belongs to an account, so it is cleared where the response cache
already is — `ApiClient.clearToken()`. But unlike a cache, the queue holds
work the user did and the server has never seen. **Signing out with a
non-empty queue must ask first**, naming how many entries would be lost.
Clearing it silently would be the one thing this feature exists to prevent.

**`TransactionSync`** — drains the outbox oldest first:

- success → remove the entry
- **connection** failure → stop the run; still offline, try again later
- **server rejection** → `markRejected` with the message, continue to the next

The connection/rejection distinction is `e is NetworkException`. Repositories
already run every call through `guardApi`, which maps the connection and
timeout `DioExceptionType`s to `NetworkException` and every answered request
to `ValidationException` / `UnauthorizedException` / `ServerException`. Testing
the domain exception rather than re-inspecting Dio keeps the rule in one place
and out of the sync's business.

It is the crux of the design: a 500 or a 400 means the server answered, and
treating that as "still offline" would retry a permanent refusal for ever.

A bad TLS certificate also maps to `NetworkException`, so it queues. That is
the right side to err on -- the entry is kept and stays visible rather than
being discarded over a server the app could not verify.

**`TransactionsController`** — decides, on save, whether the write went to the
server or the queue, and merges the queue into the list.

## Data flow

**Saving.** Try the server. A connection failure enqueues and reports "saved on
this device, will send when there is a connection". A server rejection fails as
it does today — the server answered, and queueing a refusal only defers the bad
news to a moment when the user has forgotten the entry.

**Editing something still queued.** Rewrites that queued entry rather than
queueing an update against a transaction the server has never seen. Editing it
again rewrites it again — there is never more than one queued entry per
transaction. Deleting a queued *create* removes it from the queue outright,
with no request ever made.

**Deleting a transaction the server does have, while an edit of it is
queued.** The delete supersedes: the queued update is replaced by a queued
delete, since sending an update and then a delete would be two requests to
reach the same end.

**The list.** Server page, then: pending creates merged in by date, pending
updates overlaid on their server row, pending deletes hidden. Every pending row
carries a mark.

**Sync triggers.** App start; the connection returning (the offline banner
already tracks this); after a manual refresh; and from the pending row itself.

## Balances are deliberately not adjusted

Account balances are computed server-side and will not include anything
pending. The alternative is reimplementing the backend's arithmetic in the
client — including how it treats transfers, splits and excluded accounts — and
getting a subtly different answer. In an app about money, a balance that is
confidently wrong is worse than one that is visibly behind. The pending mark on
the row is what explains the gap.

## Error handling

| Situation | Behaviour |
|---|---|
| Offline at save | Queued; user told it is saved locally |
| Server rejects at save (online) | Fails now, as today; nothing queued |
| Server rejects at sync | Entry marked with the reason; Edit and Discard offered |
| Connection drops mid-drain | Run stops; remaining entries stay queued in order |
| Outbox file unreadable | That entry is skipped and logged, not thrown; one bad file must not block the queue |
| Logout with a non-empty queue | Blocked behind a confirmation naming how many entries would be lost; only then cleared |
| Logout with an empty queue | Cleared with the rest of the account's local data |

## Testing

Unit:
- outbox round-trips an entry, survives reopening, and removes cleanly
- an unreadable file does not stop `all()` returning the rest
- sync removes on success, stops on connection failure, marks on rejection
- edit-then-sync sends one create, not a create and an update
- delete of a queued create makes no request at all

Widget:
- saving offline shows the "saved on this device" message rather than an error
- a pending transaction appears in the list, in date order, with its mark
- a pending delete hides its row
- a rejected entry shows the server's reason with Edit and Discard
- the category and payee create rows are absent while offline
- signing out with a non-empty queue asks before discarding, and cancelling
  leaves the queue intact

## Out of scope

- Creating categories or payees offline
- Queueing writes from any other screen (accounts, budgets, scheduled)
- Local balance arithmetic
- Merging concurrent edits from another device

## Follow-up this enables

If queueing other writes is ever wanted, the outbox is the seam: it stores an
operation and a payload, and only the "which repository call does this map to"
step is transaction-specific. That generalisation is a separate project and
should not be anticipated in this one.
