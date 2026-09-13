# Offline Mode — Safety & Security Audit (2026-09-13)

**Plan:** `docs/superpowers/plans/2026-09-13-offline-mode-audit.md`

**Scope:**
- **Mobile:** offline entry and app lock, response cache, outbox and sync, sign-out, platform config.
- **Backend (`../cuenti`):** what offline writes depend on.

**Branches (not merged, not released):**
- Mobile: `fix/offline-lock-versioned-apks`, on top of v2.9.2.
- Backend: `feat/api-idempotency-concurrency`, on top of `origin/main`.

**Deploy order:**
- The backend can go out first or later. Both new headers are optional on both sides: an old server ignores them, and an old app doesn't send them.
- Duplicate protection (O-4) and conflict refusal (O-5) only take effect once both sides run the new code.

## Findings and status

| ID | Sev | Threat | Finding | Status | Commit |
|----|-----|--------|---------|--------|--------|
| — | High | Phone in hand | A failed first restore used up the biometric lock decision; the retried restore opened the app with no fingerprint and no password. | ✅ Fixed. The lock now applies on every transition into a restored session (`AuthState.restoredSession`). | `38e3b6e` |
| — | High | Phone in hand | Offline start without biometric unlock resumed the session unchecked. | ✅ Fixed. Offline, the saved session is restored only with biometric unlock; otherwise the login form asks for the password, which is checked offline. | `d2806b8` |
| O-1 | High | Phone in hand | No limit on offline password guesses. | ✅ Fixed. 5 free attempts, then a 30 s wait doubling each time; after 10, offline sign-in is refused until the server confirms a sign-in. The count is persisted and resets on success. The biometric replay isn't throttled, since the OS already rate-limits it. | `8e35d6d` |
| O-2 | High | Rooted phone / forensics | The response cache was plaintext JSON. | ✅ Fixed. AES-256-GCM with the key in Keystore-backed secure storage. Legacy plaintext entries and entries that can't be decrypted are deleted (the cache can be refetched). | `5b61b1a` |
| O-3 | High | Crash / storage purge | Outbox fell back to purgeable temp storage. | ✅ Fixed. On Android the durable directory is derived without a platform channel. Queues stranded in temp are rescued as sidelined queues, which only their owner can reclaim. | `70df0fb` |
| O-4 | High | Stale data / crash | A resent create duplicated the transaction. | ✅ Fixed on both sides. The client sends `Idempotency-Key` = the entry's local id. The server writes the key and the transaction in one database transaction, unique per user and key, and a repeat returns the original. | `70df0fb`, backend `c9878c8` |
| O-5 | Medium | Stale data | Queued edits and deletes overwrote changes made elsewhere. | ✅ Fixed on both sides. Transactions carry a `version`, sent as `If-Match`. A stale write gets 409 before any balance changes, and the entry is marked refused with the reason. A delete answered 404 counts as delivered. | `70df0fb`, backend `c9878c8` |
| O-6 | Medium | Rooted phone / shared device | The outbox, including other accounts' sidelined queues, was plaintext. | ✅ Fixed. Entries and owner files are encrypted. Legacy plaintext entries are re-encrypted in place. A queue that can't be decrypted is kept but never adopted. | `5b61b1a` |
| O-7 | Medium | Phone in hand | The cache's and profile snapshot's 14-day limits trusted the clock. | ✅ Mitigated. A timestamp more than 5 min in the future counts as expired. Moving the clock back by less than the remaining window still extends it by that amount. | `8e35d6d` |
| O-8 | Medium | Network | Sync and refresh run over a client that accepts cleartext and user-installed CAs. | ⬜ Accepted risk, a documented upstream trade-off for self-hosters. | — |
| O-9 | Low | Shared device | The cache key didn't include the server. | ✅ Fixed. Server + path + query. | `8e35d6d` |
| O-10 | Low | Rooted phone | `debugPrint` diagnostics reached logcat in release builds. | ✅ Fixed. `kDebugMode` only. | `8e35d6d` |
| B-1 | Medium | CI | The backend's PostgreSQL tests were **silently skipped**: Docker 29 rejects Testcontainers' API 1.32. | ✅ Fixed. Pinned `api.version=1.44`. | backend `92a5a67` |
| B-2 | Medium | Deploy | Flyway migrations weren't exercised by any test; production runs `ddl-auto=validate`. | ✅ Fixed. `FlywaySchemaPostgresTest` migrates a real PostgreSQL and validates the schema against the entities (covers V5, V6). | backend `92a5a67` |
| B-3 | Medium | CI | Once the PostgreSQL tests ran, their Spring context in the same JVM broke `@WithMockUser` for 12 later H2 tests. | ✅ Fixed. PostgreSQL tests run in their own surefire execution (a separate JVM). `./mvnw test` still runs both. | backend `30e1db1` |

## What was already sound (verified, unchanged)
- **Certificates:** replay only on real connection failures, never on a 5xx, a 401 or a refused certificate.
- **Wipes:** the cache is wiped on sign-out and server change. The outbox is cleared only by the sign-out flow, which asks first.
- **Outbox ownership:** a foreign queue is never drained into the current account; writes are claimed before they happen; sidelining is interrupt-safe.
- **Sync:** one run at a time, and a retry queues one more run.
- **Backup:** `allowBackup=false` plus both backup rule files.
- **Recent-apps preview:** hidden (`MainActivity`).

## Verification

| | Result |
|---|---|
| Mobile `flutter analyze` (infos fatal, as in CI) | no issues |
| Mobile full `flutter test` (Flutter 3.47.2, as in CI) | 1299 passed, 0 failed (at `5205cfa`) |
| Mobile generated code (`gen-l10n`, `build_runner`) | current |
| Backend `TransactionConcurrencyApiTest` | 10/10 |
| Backend PostgreSQL: `FlywaySchemaPostgresTest`, `TransactionSearchPostgresTest` | pass, actually executed |
| Backend full `./mvnw test`, PostgreSQL tests isolated | 118 + 3 passed, BUILD SUCCESS (at `30e1db1`) |

**Not done (needs a device or an environment I don't have):**
- Airplane-mode runs on a phone: cold start with and without biometric unlock, the lockout counter, a storage purge.
- Two accounts on one device.
- A real Keystore reset (key loss). This is covered by tests with a separate key.
- mitmproxy during sync (O-8).

## Residual risks
- **Key loss:** if Android wipes secure storage (for example after the lock screen is reset), encrypted queued transactions become unreadable. They're kept on disk and never adopted by another account, but they can't be sent. Before encryption they would have been readable.
- **Legacy plaintext:** a plaintext outbox file is still accepted as legacy and re-encrypted, so an attacker with app-private write access could inject an entry. That attacker already had that access before this change.
- **Offline attempt limit:** it counts typed passwords, not devices. Clearing app data resets it, but that also deletes the token, so offline sign-in stops working.
- **`updated_at` stamp:** set by `TransactionService`. Bulk JPQL updates that bypass it don't move the version, so a conflict with such an update isn't detected.
