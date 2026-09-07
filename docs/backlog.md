# Backlog

Work that was deliberately left undone, with the reason. Each entry says
what is missing, what it costs to leave it, and what closing it would take —
so a future decision can be made on the same terms the deferral was.

Nothing here is a known defect. Defects get fixed or reported, not filed.

---

## Prune sidelined outbox queues

**What.** When an account writes into a transaction outbox it does not own,
the existing queue is moved into a `.sidelined-<timestamp>-<n>/`
subdirectory rather than deleted, so the account that owns it can get it
back. Nothing ever removes those directories. Each takeover leaves one
behind, and only a reclaim by their owner or a sign-out clears any of them.

**Cost of leaving it.** A few small JSON files per takeover, in app-support
storage. On a single-account device it never happens at all; on a shared one
it is bounded by how often the device changes hands. Not a leak that grows
on its own.

**What closing it takes.** A decision about *when* pruning is safe, which is
the actual work — the entries are the only copy of somebody's unsent
transactions, so age alone is a poor signal. Options worth weighing: prune
on successful reclaim of a *different* queue by the same owner; prune at
sign-out for queues owned by the account signing out; or surface them and
let a person decide (see below). The mechanics once decided are a directory
delete.

---

## Let a person recover a sidelined queue

**What.** Recovery is automatic and silent: a queue comes back when its
owner signs in, or corrects a mistyped server address, or writes while the
root is theirs to fill. A queue whose owner file is missing or unreadable
can never be reclaimed by anyone, because nothing can attribute it — and
nothing tells the user it exists.

**Cost of leaving it.** Rare, and it fails safe: the entries stay on disk
rather than being sent to the wrong account. But a user in that state has
unsent work they cannot see, cannot send, and cannot discard.

**What closing it takes.** A screen listing sidelined queues with their
recorded owner and entry count, offering *adopt* or *discard* — the same two
answers the sign-in sheet already offers for a foreign root, over the same
`sidelinedQueues()` / `restore()` primitives that already exist. The design
question is where it lives: a settings entry nobody finds, or something that
surfaces itself when there is anything to show. It would also give the
pruning item above its honest answer, since a person deciding beats a rule.

---

## An idempotency key the server honours

**What.** `TransactionSync.drain()` sends a queued write, then removes the
entry. If the process is killed between the server accepting the write and
the outbox recording that, the entry survives and the next drain sends it
again — a duplicate transaction. `_record` already swallows I/O failures on
that bookkeeping so one entry's storage problem cannot stop the queue, which
narrows the window to a kill, but it cannot close it.

**Cost of leaving it.** After an ill-timed crash, one duplicated
transaction: visible in the list and deletable. That is the opposite failure
from silent loss, and the less damaging one — which is why it was accepted
rather than fixed.

**What closing it takes.** A backend change. The client sends a key with each
queued write (`localId` already is one — unique, stable across replays), and
the server treats a repeat of a key it has already accepted as a no-op
returning the original result. No client-side workaround is honest; every
one of them is this same race moved somewhere else.

---

## Offline transfers show only what was cached

**What.** With no connection, a filtered transaction list — the Transfers
screen, or any type/search filter — is cut locally out of the unfiltered
pages already in the response cache, because a filtered query is a different
cache key and usually has no entry of its own. The corpus walked is whatever
pages of the unfiltered list this device happens to hold, from page 0 until
the first gap. That is the head of a date-descending list, so what is missing
is the oldest rows. A device that has never opened the transactions list
while online has nothing to cut from and still fails.

There is an asymmetry in what it will say. Where the cached pages are the
complete list, an empty result is reported as an empty list. Where they are
only a prefix, an empty result is reported as an error instead — a prefix
cannot support a claim of absence, and "you have no transfers" is a worse
answer than "could not load" when the honest one is "we do not know".

**Cost of leaving it.** An incomplete list under a banner saying when the
figures were fetched, never a wrong figure: every row shown is a row the
server handed this client verbatim, and totals describe what the device
holds rather than what exists. The visible cost is an offline transfers list
that stops earlier than the online one, and an error where an empty list
would have read better.

**What closing it takes.** Either a local store of transactions rather than a
cache of paged HTTP responses — which is the real answer, and a much larger
change than this one — or warming the cache while online by fetching the
filters the app knows it will want. The second is cheap and dishonest in a
small way: it spends the user's bandwidth on a question they have not asked,
and it only helps the filters someone thought to pre-fetch.

---

## A session expiry still clears the whole offline cache

**What.** `_handleSessionExpired` calls `logout()`, which calls
`ApiClient.clearToken()`, which clears the response cache. The cache is
cleared on sign-out so the next account cannot be shown the last one's
figures — but a session expiry is the *same* account, which is exactly why
that path already keeps the saved credentials and the outbox. One 401 on
reconnection therefore throws away every figure the offline mode depends on,
for a reason that does not apply.

**Cost of leaving it.** A session that expires while the user is away leaves
them with an empty cache the next time they open the app without a network —
the situation the cache exists for. They can still sign in offline against
their saved credentials, but there is nothing left to show them.

**What closing it takes.** Splitting `clearToken()` into "the token is dead"
and "this device is changing hands": the first keeps the cache, the second
clears it, and only `logout` and a server change call the second. Small, but
it needs care that no other caller of `clearToken` is relying on the sweep.
