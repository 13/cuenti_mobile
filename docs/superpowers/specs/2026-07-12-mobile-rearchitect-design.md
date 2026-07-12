# Mobile Rearchitect — Phase 2 of Mobile Overhaul

**Date:** 2026-07-12
**Repo:** `~/repo/cuenti_mobile` (Flutter)
**Status:** Approved design.
**Roadmap:** `docs/superpowers/specs/2026-07-12-mobile-overhaul-roadmap-design.md`

## Goal

Replace the app's architecture (Provider + raw `Map<String, dynamic>` + one
507-line `DataProvider`) with Riverpod + freezed + feature-first structure,
without changing how the app looks or behaves. The UI redesign is Phase 3;
new feature screens are Phase 4. After every task in the implementation plan
the app compiles and the test suite is green (incremental coexist migration —
Provider and Riverpod run side by side until the final removal task).

One deliberate behavior change: the transactions list moves to server-side
pagination with infinite scroll, consuming the Phase 1 `page`/`size` envelope
— the current load-everything approach doesn't scale.

## Current state

25 Dart files. `ApiClient` (dio + secure storage + self-signed-cert bypass),
11 thin `*Api` classes passing raw maps, `DataProvider extends ChangeNotifier`
holding every domain list, `AuthProvider` for token/user/biometric flag,
go_router with string routes and an auth redirect, biometric app-lock logic
inline in `main.dart`. No tests. Models are hand-written `fromJson` classes
in one file.

## Target stack

| Concern | Choice |
|---|---|
| State | `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator` (codegen) |
| Models | `freezed` + `json_serializable` — immutable, typed |
| HTTP | dio (kept), incl. the self-signed-cert bypass and JWT interceptor |
| Routing | go_router (kept) → typed routes via `go_router_builder` |
| Storage | flutter_secure_storage (kept) |
| Tests | flutter_test + `mocktail` (dio mocked at repository tests) |
| Lints | `very_good_analysis`; `flutter analyze` must be clean (targeted ignores allowed only where a rule fights generated code) |

Models include the Phase 1 API additions now (e.g. `Transaction.splits`,
`UserProfile.defaultVehicleCategoryId`) so Phase 4 does not touch the model
layer again. No raw `Map<String, dynamic>` crosses the repository boundary.

## Layout

```
lib/
  core/
    api/       dio provider, ApiClient (token + server URL), ApiException
    storage/   secure storage wrapper
    router/    typed routes + auth redirect
    theme/     current _buildTheme moved verbatim (Phase 3 replaces contents)
    widgets/   shared widgets (AsyncValueWidget, confirm dialog helpers)
  features/<domain>/
    data/      <domain>_api.dart (dio calls) + <domain>_repository.dart (typed)
    domain/    freezed models
    ui/        screens + @riverpod controllers
```

Domains: auth, accounts, transactions, categories, payees, tags, currencies,
assets, scheduled, dashboard, statistics, user (profile/preferences/admin +
settings screen).

## Core pieces

- **ApiException** — one sealed/typed exception mapped from `DioException`:
  network/timeout, 401 (triggers logout), 400 with server `{"error": ...}`
  message surfaced verbatim, other HTTP, unknown. Repositories throw it;
  nothing above the repository sees `DioException`.
- **Repository per domain** — wraps the dio calls, parses into freezed
  models, exposes typed methods. The 11 existing `*Api` classes dissolve
  into these.
- **Controllers** — `@riverpod` async notifiers per domain: expose
  `AsyncValue<List<T>>` (or domain-specific state), mutation methods
  (save/delete) that call the repository and update state. The current
  optimistic-delete-with-revert pattern is preserved.
- **Transactions pagination** — `PagedTransactionsNotifier` holding items,
  page cursor, `hasMore`, active filters (accountId now; the Phase 1 filter
  params are plumbed through the repository signature for Phase 3/4 use).
  Infinite scroll via scroll-position trigger in the list screen.
- **Auth** — auth notifier owns token presence, current user profile,
  biometric preference; go_router redirect listens to it (same redirect
  rules as today). Biometric app-lock moves from `main.dart` into an
  `AppLockObserver` widget wrapping the router child.
- **Error surfacing** — `ref.listen` on controllers shows snackbars with
  `ApiException` messages, replacing `DataProvider.lastError` /
  `saving` flag (buttons disable on `AsyncLoading` instead).
- **AsyncValueWidget** — shared loading/error/data switcher so screens stop
  hand-rolling spinner/error states.

## Migration order (each step leaves the app green)

1. **Foundation:** dependencies, lints, `core/` (dio provider, ApiException,
   storage), all freezed models generated, build_runner wired. Old code
   untouched and still running the app.
2. **Auth + router + shell** on Riverpod; `MultiProvider` still wraps the
   tree for the not-yet-migrated screens.
3. **Domains feature-by-feature:** accounts → transactions (+ pagination) →
   categories/payees/tags/currencies/assets → scheduled → dashboard +
   statistics → user/settings (+ admin panel).
4. **Removal:** delete `lib/providers/data_provider.dart`,
   `lib/providers/auth_provider.dart`, `lib/api/api_services.dart`,
   `lib/models/models.dart`, and `lib/api/api_client.dart` (its replacement
   `lib/core/api/api_client.dart` is created in step 1 and both exist during
   the migration); drop `provider` from pubspec.
5. Tests land with each step, not at the end.

## Testing

- Repository tests per domain: mocked dio asserts request path/method/body
  and model parsing (incl. an `ApiException` mapping test).
- Controller tests per domain: ProviderContainer-based, repository mocked.
- Widget tests for three critical flows: login, transactions list
  (incl. pagination trigger), transaction create/edit dialog.
- `flutter analyze` clean and `flutter test` green at every task boundary.

## Non-goals

- Visual changes of any kind (Phase 3).
- Budgets/forecasts/vehicles/audit/saved-views/export-import screens
  (Phase 4) — but their API fields already exist in the models where they
  ride on existing endpoints (splits).
- Backend changes.
