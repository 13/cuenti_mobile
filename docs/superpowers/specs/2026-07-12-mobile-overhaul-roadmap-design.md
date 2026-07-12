# Cuenti Mobile Overhaul — Roadmap

**Date:** 2026-07-12
**Repos:** `~/repo/cuenti_mobile` (Flutter app), `~/repo/cuenti` (Spring Boot backend)
**Status:** Approved design; each phase gets its own spec + implementation plan.

## Goal

Bring the Flutter app to feature parity with the Vaadin web app, modernize its
architecture, and give it a polished "modern finance" look. Work is split into
four shippable phases; Phase 1 is backend-only, phases 2–4 build on each other
in the mobile repo.

## Current state (summary)

- Mobile: 25 Dart files, Provider + go_router + dio. Single 507-line
  `DataProvider`, `Map<String, dynamic>` passed to API layer, no tests, no
  pagination, minimal loading/error states.
- Mobile already covers the existing REST API: accounts, transactions,
  categories, payees, tags, assets, currencies, scheduled transactions,
  dashboard, statistics, user profile/preferences/admin.
- Backend features with **no REST API** (Vaadin views only): Budgets,
  Forecasts, Vehicles (fuel tracking), Audit Log, Saved Views, JSON
  export/import (API exists but unused by mobile), transaction splits
  (entity exists, not exposed in `TransactionDTO`).
- Forecast and vehicle computation logic currently lives inside Vaadin views
  (`ForecastsView`, `VehiclesView`) and must be extracted into services before
  it can back REST endpoints.

## Phase 1 — Backend REST expansion (`~/repo/cuenti`)

Detailed spec: `~/repo/cuenti/docs/superpowers/specs/2026-07-12-rest-api-expansion-design.md`

- Extract `ForecastService` and `VehicleReportService` from the Vaadin views;
  views are refactored to consume the services.
- New JWT-secured, user-scoped controllers:
  - `/api/budgets` CRUD + `/api/budgets/progress?month=YYYY-MM`
  - `/api/forecasts?year=YYYY` (monthly income/expense/net from scheduled transactions)
  - `/api/vehicles/report?categoryId=&start=&end=`
  - `/api/audit-log` (paged, admin-gated)
  - `/api/saved-views` CRUD
- `TransactionDTO` gains `splits`; create/update accept them.
- `/api/transactions` gains pagination + filters (date range, category, payee,
  tag, type, text search) + sort; parameterless call stays back-compatible.
- Controller tests for every new/changed endpoint.

## Phase 2 — Mobile rearchitect (foundation)

- Riverpod (`flutter_riverpod` + `riverpod_generator`) replaces Provider.
- `freezed` + `json_serializable` code-gen models for every DTO; no raw maps
  past the repository layer.
- Feature-first layout: `lib/features/<domain>/{data,domain,ui}`.
- One repository per domain wrapping dio; typed `ApiException` error mapping;
  `AsyncValue`-based state everywhere.
- Keep: dio, go_router (moving to typed routes), flutter_secure_storage,
  biometric lock, fl_chart.
- Pagination infrastructure for the transaction list (infinite scroll).
- Tests: repository unit tests (mocked dio), provider tests, widget tests for
  auth, transaction list, and transaction dialog. Stricter lints; `flutter
  analyze` clean.

## Phase 3 — UI overhaul (modern finance look)

- Design system: theme tokens (light/dark palettes, typography scale, spacing,
  radii) and reusable components — hero balance card with gradient, animated
  amounts, stat chips, transaction tile, empty states, skeleton loaders.
- Dashboard: net-worth hero with sparkline, account carousel, recent activity.
- Transactions: date-grouped sticky headers, swipe actions (edit/delete),
  search/filter bar backed by the new API filters, saved views.
- Charts restyled (smooth curves, tooltips); page transitions, hero
  animations, pull-to-refresh everywhere.

## Phase 4 — Feature screens (on the new foundation)

- Budgets: list with per-category progress bars, month picker, CRUD.
- Forecasts: projected balance chart + upcoming scheduled timeline.
- Vehicles: fuel/cost dashboard (consumption, cost/km) per the web view.
- Split editor inside the transaction dialog.
- JSON export (share/save file) and import (file picker).
- Audit log screen (admin only); saved views for transaction filters.

## Sequencing and constraints

- Phase 1 is independent and unblocks Phase 4; phases 2 → 3 → 4 are sequential
  in the mobile repo.
- Every phase leaves both apps releasable: backend stays backward-compatible
  with the currently shipped mobile app (v1.3.1) throughout Phase 1.
- Error handling and tests are in-scope inside each phase, not deferred.
