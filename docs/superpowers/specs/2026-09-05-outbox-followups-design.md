# Outbox follow-ups: reachable refusals, two-way sidelining, and four chores

## Why

The outbox-ownership branch shipped with six items deliberately carried past
its final review. Two are design work; four are chores. They are one spec
because they are one cleanup of the same subsystem, and because the two
design items are the branch's own promises not yet kept.

## Track 1: a refused entry is always reachable

### The defect

`TransactionsController.mergePending` (`transactions_controller.dart:63-86`)
builds the list from the server page, then overlays pending `update`s **only
onto rows the server still returns**, hides rows with a pending `delete`, and
appends pending `create`s. An `update` or `delete` whose server row is gone
is therefore invisible.

That is correct while the entry is in flight — the drain will send it, take a
404, and mark it refused. It is wrong afterwards: a **refused** entry for a
vanished row can never be shown, so it can never be retried or discarded. It
sits in the outbox forever, inflating the sign-out count with a phantom.

Two paths create one. An online delete of a row that has a queued edit on an
unclaimed queue leaves the edit behind, and a later adoption makes it live.
And the duplicate-create window parked on the first branch — a send that
succeeds but whose removal fails — can leave an entry the server has already
absorbed.

### The decision

**A refused pending entry whose server row is absent is surfaced as its own
row**, marked refused like any other, with the existing Retry and Discard.

Rejected: `amendableEntries`, a fourth sanctioned read meaning "ours, or
nobody's", used only by `delete`'s success branch to remove the stranded
edit at the moment the server confirms the row is gone. It fixes one of the
two paths, adds a read to a module whose discipline is that reads are few
and named, and leaves the general defect — an entry nothing can reach —
in place. Surfacing the entry fixes every path at once.

### Behaviour

In `mergePending`, after the existing overlay:

- A pending entry with `operation == update` or `delete`, whose
  `transaction.id` is **not** among the server rows, and which
  **`isRejected`**, is appended as a row using `e.transaction`, subject to
  `matchesFilter` the same way pending creates are.
- A **non-rejected** orphan is still hidden. It is in flight; hiding it is
  the current, correct behaviour.

`TransactionTile.pendingFor` already matches a row with an id to its entry by
id (`transaction_list_parts.dart:185-186`), so the surfaced row gets its
refused mark, reason, and both buttons with no tile change. Discard removes
it from the outbox as today. Retry re-sends, takes the 404 again, and the row
stays refused — honest, and the user can then discard it.

A surfaced `delete` orphan shows the transaction the user asked to delete,
marked refused. That reads oddly but is truthful: the server no longer has
it, the delete cannot succeed, and the only useful action is Discard.

### Testing

- A refused `update` whose row the server no longer returns appears in the
  list, marked refused, with its reason.
- Discarding it removes it from the outbox and the list.
- A non-rejected `update` for a missing row does **not** appear.
- A refused `delete` for a missing row appears and can be discarded.
- The surfaced row obeys the active filter.
- The sign-out count no longer includes an entry the user has discarded
  this way — i.e. the phantom is really gone.

## Track 2: sidelining is two-way

### The promise not yet kept

The foreign-queue sheet says, in three languages: *"Signing in as that
account, or correcting the server address, brings them back — but saving a
transaction here will set them aside first."* Nothing reads a sidelined
directory back. The clause after the dash is true; the clause before it is
true only until the first save, after which the entries are in
`.sidelined-…` for good.

`sideline()` moves the old `.owner.json` **into** the subdirectory
(`transaction_outbox.dart:238-252`), so every sidelined queue knows whose it
is. Recovery is a read of that file and a move back.

### The decision

**A sidelined queue whose recorded owner is the current account is restored
into the root, when the root is that account's to fill.**

"Is that account's to fill" is the whole rule, and it is deliberately narrow:
the root queue must be **ours**, or **empty and unowned**. Never merge into a
queue that belongs to someone else, and never merge into an unowned queue
that still holds entries — that is the upgrade case, which the sheet owns.

### Where it runs

Two call sites, one function, both already on the ownership chain:

1. **After a claim.** `_resolveOwnership` sidelines whatever was there and
   calls `setOwner`. At that moment the root is ours and empty. Reclaim runs
   next, so a user whose queue was set aside gets it back on their first
   write.
2. **At the sign-in check.** `promptForForeignOutbox` runs once per arrival
   at a signed-in state, and `/server-setup` is outside the shell route, so
   correcting a server address remounts it. Reclaim runs **before**
   `claimStateOf`: if the root is ours-or-empty and a sidelined queue is
   ours, it comes back and the sheet has nothing to ask. If anything was
   reclaimed, `drainOutbox(ref)` — the app-start drain has already run.

That second site is what makes "correcting the server address brings them
back" true without the user having to save something first.

### Mechanics

`TransactionOutbox` gains a small value type and two methods:

- `SidelinedQueue` — a `directory` and a nullable `owner` string. Nothing
  else; it is a handle, not a store.
- `Future<List<SidelinedQueue>> sidelinedQueues()` — each `.sidelined-*`
  subdirectory with its recorded owner, or `null` where the owner file is
  missing or unreadable. A subdirectory with no readable owner is never
  reclaimed by anyone.
- `Future<void> restore(SidelinedQueue queue)` — moves each entry file back
  to the root, deletes the subdirectory's owner file, and removes the
  subdirectory. **It overwrites nothing**: an entry whose filename already
  exists in the root is left where it is and the subdirectory is kept. Local
  ids are a timestamp plus a counter, so this cannot happen in practice; the
  rule exists so the impossible case is a no-op rather than a loss.

`outbox_ownership.dart` gains `Future<int> reclaimSidelined(outbox, accountKey)`,
returning how many queues came back. It chains on the same per-outbox
`Expando` as `claimForWriting`, because it moves files and must not
interleave with a sideline. With a null key it does nothing.

If the root is empty and unowned and a reclaim happens, `setOwner(accountKey)`
follows, so the restored queue is claimed. If the root is already ours,
nothing about the owner changes.

Multiple sidelined queues with the same owner are all restored. Order does
not matter; the drain sorts by `queuedAt`.

### Testing

- After a foreign write sidelines A's queue, A's next write brings it back
  and A sees the entries.
- Correcting a mistyped server URL and returning to the dashboard brings the
  queue back **without a save**, and something is drained.
- A sidelined queue owned by A is **not** restored while the root belongs to
  B.
- A sidelined queue owned by A is **not** restored into an unowned root that
  still holds entries.
- A sidelined subdirectory with no readable owner is never restored.
- Two sidelined queues owned by A both come back.
- A restore that would overwrite an existing root entry leaves both intact.
- The reclaim runs on the ownership chain: a reclaim racing a sideline does
  not throw and leaves a coherent queue.

## Track 3: four chores

1. **The latent flake in `transaction_dialog_test.dart:747-761`.** Same
   shape the last branch fixed in `transactions_screen_test.dart`: the wait
   leaves `runAsync` when the entry hits disk, while the save sheet's
   progress indicator is still on screen, and the following `pumpAndSettle`
   can never settle. A fixed 200 ms delay currently hides it. Replace with a
   wait for the sheet to close — no `CircularProgressIndicator` and no Save
   button — using the helper shape already in the screen test.
2. **The spec is out of date with its own implementation.**
   `docs/superpowers/specs/2026-09-04-outbox-ownership-design.md:96` still
   documents `claimIfUnowned`, deleted on that branch; its string table
   still prescribes the Italian *operazioni* that the same branch corrected
   to *movimenti*. Annotate both, in the style the error-display spec used
   for its own superseded strings.
3. **`logoutPendingBody` has no ICU plural** in any language, so one entry
   reads "1 transactions have not reached the server". Add the plural in all
   three catalogues, matching the two `outbox*Body` strings that already
   have one, and update the settings test that pins the old text.
4. **A comment that reasons from a falsified premise, and its dead call.**
   `transactions_controller.dart:352-358`, in `delete`'s offline branch,
   argues that claiming before `_queuedIdFor` lets the lookup see the queue.
   Since unowned and foreign queues are now sidelined rather than adopted, a
   claim can never un-seal anything; the lookup finds nothing either way,
   and `_enqueue` claims immediately after regardless. Remove the call and
   the comment. Also `outbox_claim_prompt.dart:52`, which says adopting is
   "`setOwner` or nothing at all" — it is now `setOwner` and a drain.

## Out of scope

- Pruning old sidelined subdirectories.
- Any change to what sign-out's recursive `clear()` removes.
- A typed sum for `owner()`'s unattributable sentinel (still a follow-up).
- The remaining l10n minors: German *jenem*, Italian mood consistency.

## Constraints

- Every new or changed user-facing string in `app_en.arb`, `app_de.arb` and
  `app_it.arb`, then `flutter gen-l10n`; `translations_test.dart` enforces
  parity including ICU placeholder sets.
- Italian calls a transaction *movimento* (masculine). The catalogue uses it
  fifteen times; nothing new may say *operazione*.
- `outbox_ownership.dart` stays free of Riverpod; the structural guard
  `outbox_reads_test.dart` still bans bare `.all()` outside its two
  allow-listed files. `sidelinedQueues()` and `restore()` live in the store
  and are not reads of the queue, so they need no allow-list entry —
  `reclaimSidelined` is the sanctioned caller.
- Full gate: `flutter analyze`, `dart format --output=none
  --set-exit-if-changed lib test integration_test tool`, `flutter test
  --coverage`, `dart run tool/check_coverage.dart 80`. Baseline 1151 tests.
