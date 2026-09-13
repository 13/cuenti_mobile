# Offline Mode — Safety & Security Audit Plan

**Goal:** Decide whether offline mode can be trusted with a finance app's two promises:
- **Security:** nobody but the account holder sees or changes the data.
- **Safety:** nothing the user enters is lost, duplicated or silently wrong.

**Output:** a ranked findings report, then fix tasks.

**Base:** `origin/main` at v2.9.2 plus branch `fix/offline-lock-versioned-apks`: `38e3b6e` (app lock on every restored session) and `d2806b8` (offline start needs the password without biometric unlock). Audit the branch, since it changes the offline entry path.

**Output file:** `docs/audit/2026-09-offline-mode-audit.md`. One row per finding: ID, severity, threat, `file:line`, evidence (a test or repro), impact, fix, effort.

## Scope

| Area | Code | Existing tests |
|------|------|----------------|
| Offline entry | `auth_controller.dart` (`_init`, `_signInOffline`, `_readSavedProfile`, `offlineProfileMaxAge`), `login_screen.dart`, `app_lock_observer.dart` | auth_controller (47), app_lock (10) |
| Response cache | `core/api/response_cache.dart`, `offline_cache_interceptor.dart`, `api_client.dart` (attach, `clearToken`, server move), `transactions_repository.dart` (filtered-from-cached) | response_cache (18), interceptor (13), api_client (5), repository (21) |
| Outbox | `transaction_outbox.dart`, `outbox_ownership.dart`, `outbox_claim_prompt.dart`, `domain/pending_transaction.dart` | outbox (31), ownership (37), claim prompt (24) |
| Sync | `transaction_sync.dart`, `ui/outbox_drain.dart`, drain triggers in `main.dart`, `shell_screen.dart`, `refresh_all.dart` | sync (29), drain (3), main (10) |
| Sign-out / expiry | `sign_out.dart`, `AuthController.logout` / `_handleSessionExpired`, `ApiClient.clearToken` | auth_controller, settings/shell screens |
| UI truthfulness | `offline_banner.dart`, stale markers, pending/rejected rows | offline_banner (7), transactions screen (25) |
| Platform | `AndroidManifest.xml`, `backup_rules.xml`, `data_extraction_rules.xml`, `network_security_config.xml` | — |

## Threat model

| # | Actor or event | What they have | What must hold |
|---|----------------|----------------|----------------|
| T1 | Someone holding an unlocked or found phone | Physical access, no password, no fingerprint | Can't enter offline, can't read cached figures, can't queue writes |
| T2 | The next person on a shared device | Their own account, same install | Never sees, sends or adopts the previous account's cache or queue |
| T3 | Rooted phone, forensic extraction, malware with file access | App-private files | Exposure limited to what's unavoidable, and documented |
| T4 | Network attacker (café Wi-Fi, MDM or user CA, cleartext LAN) | Traffic during drain and refresh | Can't read or alter queued writes, and can't feed a poisoned response into the cache |
| T5 | Stale or conflicting data | The same account edited elsewhere while this phone was offline | No silent lost update, no duplicate, no decision on figures that look live |
| T6 | Crash, kill, OS storage purge, clock change | Device lifecycle | No queued transaction lost or double-sent without the user being told |

## Already found while scoping

These are verified in code but not yet reproduced by a test; the audit confirms each with a test.

| ID | Sev | Threat | Finding | Evidence |
|----|-----|--------|---------|----------|
| O-1 | **High** | T1 | Offline password sign-in has **no attempt limit**. With the token present and a snapshot under 14 days, whoever holds the phone can guess passwords locally, as fast as they can type or script the UI. Online, the server can rate-limit; offline, nothing does. | `auth_controller.dart` `_signInOffline` (plain comparison against the saved password), no lockout in `features/auth` |
| O-2 | **High** | T3 | Response cache stores **plaintext JSON**: dashboard, transactions, balances, profile. Backups are refused (`allowBackup=false` plus both rule files), but on the device it's protected only by the app sandbox. | `response_cache.dart` `store` → `$support/response_cache/*.json`; comments in `backup_rules.xml` |
| O-3 | **High** | T6 | If app support can't be opened within 5 s, the outbox **falls back to `systemTemp`**, which the OS may purge between runs. Unsent transactions can vanish, and only the sign-out sheet ever says so. | `transaction_outbox.dart` `openOrFallback`; `sign_out.dart` `isFallback` |
| O-4 | **High** | T5/T6 | **No idempotency key.** A POST whose response is lost is sent again on the next drain, creating a duplicate server row. Acknowledged in code as needing a server change. | `transaction_sync.dart` (~L136 comment); backend `TransactionApiController` |
| O-5 | Medium | T5 | Queued **updates and deletes** replay last-write-wins. An edit made elsewhere while offline gets silently overwritten, and a queued delete can remove a row changed meanwhile. | `PendingOperation` in `pending_transaction.dart`; `_send` in `transaction_sync.dart` |
| O-6 | Medium | T3 | The outbox is plaintext JSON too, and **sidelined queues of other accounts stay on the device indefinitely** (kept deliberately for reclaim). A shared device keeps a previous user's unsent entries at rest. | `transaction_outbox.dart` `sideline`/`sidelinedQueues`; `outbox_ownership.dart` `_reclaim` |
| O-7 | Medium | T1/T6 | Freshness bounds trust the device clock: the cache uses file **mtime**, and the profile snapshot uses a stored `savedAt`. Setting the clock back extends a 14-day offline window indefinitely. | `response_cache.dart` `read` (`statSync().modified`), `_readSavedProfile` |
| O-8 | Medium | T4 | Drain and refresh run over the same client that allows cleartext and user-installed CAs (a documented, accepted trade-off). Offline replay then serves whatever that path last stored, so an interception during one refresh persists for up to 14 days. | `network_security_config.xml`, `AndroidManifest.xml`, interceptor `onResponse` |
| O-9 | Low | T2 | The cache key is method + path + query, with no server and no account. Isolation depends entirely on `clearToken`/server-move clearing firing on every exit path. | `response_cache.dart` `cacheKeyFor`, `api_client.dart:158,173` |
| O-10 | Low | T3 | `debugPrint` also prints in release builds. Check that no line logs transaction contents, account keys or server messages to logcat. | `transaction_outbox.dart`, `auth_controller.dart` |

## Audit workstreams

### A. Offline entry and session (T1, T2)
1. **State table:** walk every combination of {online, offline, certificate refused} × {token, no token} × {snapshot fresh, stale, missing, corrupt} × {biometric on, off} × {saved password yes, no}. For each: is anyone signed in, does the lock show, what does the login form offer. Turn the table into a parameterised `auth_controller` test.
2. **O-1:** add a test for repeated wrong offline passwords. Design a local attempt counter with backoff (persisted in secure storage, surviving restart) and a wipe or require-online after N failures. Decide the thresholds.
3. **Biometric enrolment change:** does local_auth invalidate on newly enrolled fingerprints? Can someone who adds their own fingerprint unlock? (Keystore `setInvalidatedByBiometricEnrollment`.) Device test.
4. **Lock timing:** the lock must be visible before any cached figure renders. Check the first frame after a restore, the resume path, and the recent-apps screenshot (`FLAG_SECURE`).
5. **Expiry mid-offline:** a token expiring server-side while offline; reconnect → 401 → `_handleSessionExpired`. Confirm the queue is kept for the same account and the cache cleared or kept as designed.
6. **Snapshot lifecycle:** written only from server-answered profiles; deleted by "Not you?" and sign-out; unreadable → treated as missing.

### B. Data at rest (T3)
1. **Inventory:** every file and key offline mode writes, with who can read it: secure storage, `response_cache/`, `transaction_outbox/`, `.sidelined-*`, `systemTemp/cuenti_outbox`, the update-download temp, export temp.
2. **O-2, O-6:**
   - **Measure:** entry sizes, and which endpoints are cached. Is any auth, token or export response cached? Check `/auth/*` and the export GET explicitly.
   - **Design:** encryption at rest (AES-GCM, key in Keystore via `flutter_secure_storage`) for the cache and outbox. Cost it against startup latency.
   - **Retention:** decide how long sidelined queues are kept.
3. **Wipe completeness:** after sign-out, session expiry, server change and "Not you?", list what's left on disk. Automate as a test that snapshots the directories.
4. **O-10:** review release logcat output.

### C. Outbox durability and integrity (T5, T6)
1. **O-3:** reproduce the fallback (open timeout). Decide the fix: retry opening support storage, block writes, or warn persistently while on the fallback, instead of only at sign-out.
2. **Atomicity:** temp-and-rename on `add`, `setOwner` and `sideline`. Fault-inject a kill between steps (test harness). Check no torn file reads as a different entry or owner.
3. **O-4:** confirm the duplicate with a lost-response test. Specify a client `Idempotency-Key` (the entry's `localId`) plus server support; until then, a same-day duplicate check before re-posting an entry that may have been delivered.
4. **O-5:** conflict cases, each as a sync test: update vs remote update, update vs remote delete, delete vs remote update, delete vs already deleted. Decide on optimistic concurrency (version or `updatedAt` precondition) and the UI for a conflict.
5. **Single-flight drain:** run all four triggers at once (startup, reconnect, refresh-all, per-row retry). Queue at most one extra pass, and never send an entry twice.
6. **Rejections:** a 4xx marks the entry rejected and stops retrying; a 5xx or network error leaves it queued. The user can edit or discard, and a discarded entry is never sent.
7. **Ownership:** claim, sideline and reclaim under concurrent sign-in and offline save; a foreign queue is never drained into the current account.

### D. Cache correctness (T4, T5)
1. **Replay rules:** only GET, only genuine connection failures, never a 5xx, 401 or refused certificate (`isOfflineFailure`). Confirm with tests for each `DioExceptionType`.
2. **Filtered-from-cached lists:** a filtered view built from a cached unfiltered list must never claim completeness. It must show the "may be missing" state.
3. **Staleness UI:** the banner is shown whenever any figure on screen is replayed, including for callers that use `markStale`; it's removed on the true→false edge; the time shown is the oldest entry. Stale balances must never look live.
4. **O-7:** clock-change tests; consider a monotonic or server-time anchor (store server `Date` with the entry).
5. **O-9:** assert the cache is empty after every account or server change path.
6. **Eviction:** 200 entries; search queries can't push out the dashboard or accounts. Check the eviction order.

### E. Network during reconnect (T4)
1. **O-8:** drain and refresh behaviour under mitmproxy with a user CA, and on cleartext `http://`. Record what an attacker can read or alter. Decide whether writes (drain) should require a pinned or system-trusted connection even when reads accept the documented trade-off.
2. **Certificate change while offline:** a refused certificate on reconnect must stop the drain and keep the queue. It must not count as offline (no replay), and must not be treated as a rejection.

### F. Device verification (needs a phone)
Run in airplane mode on a real device, fresh install and upgrade:
- **Entry and lock:** cold start with biometric on and off; resume; kill mid-drain.
- **Storage:** OS storage-pressure purge.
- **Accounts:** two-account switch on one device.
- **Integrity:** clock change; server edited from the web app while the phone was offline.

## Order and effort

| Step | Work | Output | Est. |
|------|------|--------|------|
| 1 | Inventory and state table (A1, B1), log review (B4) | tables in the report | 0.5 d |
| 2 | Repro tests for O-1, O-3, O-4, O-5, O-7, O-9 (failing tests on a scratch branch) | evidence per finding | 1 d |
| 3 | At-rest design: encryption, retention, wipe test (B2–B3) | design note plus cost | 0.5 d |
| 4 | Outbox durability and conflicts (C1–C7) | findings plus fault-injection tests | 1 d |
| 5 | Cache and network (D, E), with mitmproxy | findings | 0.5 d |
| 6 | Device run (F) | checklist results | 0.5 d |
| 7 | Report: rank by severity × effort into fix batches | `docs/audit/2026-09-offline-mode-audit.md` | 0.5 d |

**Rules:**
- No product code changes during the audit; repro tests live on a scratch branch.
- Every High finding gets a failing test before any fix.
- Backend dependencies (O-4 idempotency key, O-5 concurrency preconditions) are written up for `../cuenti`, not worked around silently.

## Decisions needed from you
1. **Offline attempt limit (O-1):** how many wrong passwords before backoff or requiring online? And should repeated failure wipe the offline data?
2. **Encryption at rest (O-2, O-6):** worth the startup cost for the cache and outbox?
3. **Backend changes (O-4, O-5):** can `../cuenti` take an idempotency key and optimistic-concurrency preconditions?
4. **Device run:** is a test phone available?
