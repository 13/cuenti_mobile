# Feature Screens — Phase 4 of Mobile Overhaul

**Date:** 2026-07-12
**Repo:** `~/repo/cuenti_mobile` (Flutter; post Phase-3 UI overhaul)
**Status:** Approved design.
**Roadmap:** `docs/superpowers/specs/2026-07-12-mobile-overhaul-roadmap-design.md`
**API contracts:** `~/repo/cuenti/docs/superpowers/specs/2026-07-12-rest-api-expansion-design.md` (Phase 1, deployed as backend v2.10.0)

## Goal

Ship the parity features the Phase 1 API enabled: budgets, forecasts,
vehicles, transaction splits, JSON export/import, audit log, saved views,
and the deferred admin user actions. Every screen uses the Phase 2
architecture (feature-first, Riverpod codegen, freezed) and the Phase 3
design system (kit widgets, tokens, chart styling).

## Navigation (user-approved)

- Bottom nav grows to 4: Dashboard, Transactions, **Budgets**, Statistics.
- Drawer gains: Forecasts, Vehicles, Audit Log (audit entry rendered only
  for admins — `authState.user.isAdmin`).
- Export/Import: two rows in Settings.
- Saved views: bookmark icon in the transactions filter bar.
- Split editor: section inside the transaction dialog.
- Admin user actions: popup menu in the existing settings admin panel.

## Features

### 1. Budgets (`lib/features/budgets/`)

- API: `GET/POST /api/budgets`, `PUT/DELETE /api/budgets/{id}`,
  `GET /api/budgets/progress` (budgetId, categoryId, categoryName,
  monthlyLimit, spent, remaining, active).
- Screen: card list from `/progress` — category name, linear progress bar
  (spent/limit; primary color under budget, expense token at/over),
  `AmountText` spent + limit, inactive budgets dimmed. FAB add + card
  tap-to-edit bottom sheet: category picker (EXPENSE categories not already
  budgeted, current one allowed when editing), monthly limit field, active
  switch. Delete via swipe or sheet button + `showConfirmSheet`. Duplicate
  category → backend 400 message surfaced via snackbar.
- Controller: list from `/progress`; mutations invalidate self.

### 2. Forecasts (`lib/features/forecasts/`)

- API: `GET /api/forecasts?year=YYYY` → `{year, months[{month, income,
  expense, net}], totalIncome, totalExpense, netForecast, currency}`.
- Screen: year `ChoiceChip` row (currentYear−1 … +2), three summary stat
  cards (income/expense/net with semantic colors), grouped monthly bar
  chart (income + expense bars per month, tokens, P3 chart styling:
  rounded rods, tooltips, outlineVariant grid), monthly breakdown list
  (month label + income/expense/net `AmountText`s).
- Provider: `@riverpod` family on `year` (read-only).

### 3. Vehicles (`lib/features/vehicles/`)

- API: `GET /api/vehicles/report?categoryId=&start=&end=` → entries
  (date, odometer, liters, amount, currency, station, memo, fullTank,
  distance, pricePerLiter, consumption) + totals (totalCost, totalLiters,
  totalDistance, avgConsumption, avgPricePerLiter, currency). Default
  category comes from the user profile's `defaultVehicleCategoryId`;
  "set as default" writes `PUT /api/user/preferences
  {defaultVehicleCategoryId}` then refreshes the profile.
- Screen: category `InputChip` (EXPENSE category sheet; star action = set
  default), date-range chips (this-year default, custom range picker),
  stat cards (total cost, liters, distance km, ⌀ l/100km, ⌀ price/l),
  consumption line chart over entries (P3 styling), fuel entry list
  (date, station, liters+odometer subtitle, `AmountText`, full-tank badge
  chip, consumption when measured).
- No category selected and no default → `EmptyState` prompting selection.
- Provider: family on `(categoryId, start, end)` (read-only).

### 4. Transaction split editor (in `transaction_dialog.dart`)

- Collapsible "Splits" section listing rows: category dropdown (typed to
  the transaction type, TRANSFER hides the section), amount field, memo
  field, remove button; "Add split" button.
- Live validation banner: sum of splits vs amount (backend rule mirrored);
  Save disabled while mismatched and splits non-empty.
- Payload semantics per Phase 1 contract: transaction never had splits and
  the section was untouched → `splits` key omitted; existing splits
  cleared by the user → `[]` sent (deliberate remove-all); otherwise the
  full replacement list. The Phase 2 repository's `if (t.splits.isEmpty)
  json.remove('splits')` guard is replaced by an explicit
  `bool splitsTouched` signal passed to `TransactionsRepository.save`.

### 5. JSON export/import (`lib/features/user/` + settings rows)

- Export: `GET /api/json-export-import/export` → write to temp file
  (`cuenti-export-YYYY-MM-DD.json`) → system share sheet (`share_plus`).
- Import: pick `.json` file (`file_selector`) → `showConfirmSheet`
  (destructive warning: replaces server data) → `POST
  /api/json-export-import/import` → success snackbar + invalidate all data
  providers (reuse the shell refresh-all set).
- **New dependencies: `share_plus`, `file_selector`.**

### 6. Audit log (`lib/features/audit/`)

- API: `GET /api/audit-log?page=&size=&filter=` → `{content[{id, userId,
  username, timestamp, entityType, entityId, action, details}], page,
  size, totalElements, totalPages}`.
- Screen (drawer, admin-only entry): debounced filter field, infinite
  scroll (transactions-pattern paged controller), tile: action icon
  (CREATE/UPDATE/DELETE glyphs), entityType + details, username + relative
  timestamp.

### 7. Saved views (`lib/features/saved_views/` + transactions bar)

- API: `GET/POST /api/saved-views`, `PUT/DELETE /api/saved-views/{id}`;
  `params` is an opaque string — mobile stores the JSON-encoded
  `TransactionFilter` (accountId/type/categoryId/start/end/search; dates
  ISO). Unknown/foreign params strings that fail to parse are shown
  disabled with a "web view" hint (web app may store its own format).
- UI: bookmark `IconButton` in the transactions filter bar opens a sheet:
  saved views list (tap → apply filter + close), trailing delete (confirm),
  "Save current view" (enabled when filter ≠ default; name prompt; POST
  upserts by name).

### 8. Admin user actions (settings admin panel)

- Restore the enable/disable/delete popup menu per user row (repository
  methods `setUserEnabled`/`deleteUser` + tests exist since Phase 2).
  Delete requires `showConfirmSheet`. List refreshes via
  `ref.invalidate(adminUsersProvider)`.

## Architecture

Each new domain follows the established shape: freezed models in
`domain/`, repository (+ `_guard`) in `data/`, `@riverpod`
controller/provider in `ui/`, screen using kit widgets. No raw hex; all
lists get skeleton/empty/retry states; deletes get confirm sheets; page
transitions come from the router automatically.

## Testing

- Repository tests per new domain (parse, payload capture, ApiException).
- Controller tests: budgets mutations, audit paging.
- Widget tests: budgets screen (progress render + add flow), split editor
  (sum validation + payload semantics incl. omitted-vs-empty), saved views
  sheet (apply + save current).
- Suite green + `flutter analyze --no-fatal-infos` exit 0 at every task
  boundary.

## Non-goals

- Backend changes (all endpoints shipped in v2.10.0).
- XHB / TradeRepublic import (web-only).
- Offline caching, widgets/home-screen, notifications.
