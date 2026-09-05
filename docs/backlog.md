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
