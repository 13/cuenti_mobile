# UI Overhaul — Phase 3 of Mobile Overhaul

**Date:** 2026-07-12
**Repo:** `~/repo/cuenti_mobile` (Flutter, post Phase-2 Riverpod architecture)
**Status:** Approved design.
**Roadmap:** `docs/superpowers/specs/2026-07-12-mobile-overhaul-roadmap-design.md`

## Goal

Give the app a designed, "modern finance" identity — fixed brand palette,
custom typography, a reusable component kit, restyled screens and charts,
and purposeful motion — without adding features (Phase 4) or changing
navigation structure. One functional upgrade rides along: the transactions
filter/search bar wires up the Phase 1 server-side filters, replacing the
loaded-pages-only client search.

## Decisions (user-approved)

- **Fixed brand palette** (emerald-teal identity). The user-selectable color
  seed is removed: settings loses the color picker; `setColorSchemeSeed` and
  its storage key are retired. Dark-mode toggle stays.
- **Custom bundled font:** Manrope (weights 400/500/600/700/800), with
  `FontFeature.tabularFigures()` on every monetary amount.

## 1. Design system foundation (`lib/core/theme/`)

- Hand-tuned `ColorScheme`s for light and dark (dark = desaturated variants,
  not inversion). Anchors: primary `#0E8A6B`; light background `#F7F9F8`,
  surfaces white, outline `#DCE5E1`, onSurface `#16211D`; dark background
  `#0E1513`, surface `#16201C`, surface-high `#1D2925`, onSurface `#E5EDE9`.
  All body-text pairs meet WCAG 4.5:1 in both modes (verify at
  implementation time; adjust tones, not roles).
- `ThemeExtension<CuentiColors>` carries semantic tokens the scheme lacks:
  `income` (green, light `#1E9E63` / dark `#5CC894`), `expense` (red, light
  `#D64545` / dark `#F07575`), `transfer` (blue-gray), `heroGradient`
  (teal → deep teal `LinearGradient`), and a 6-color accessible chart
  palette. Widgets never use raw hex — tokens only.
- Typography: Manrope TTFs bundled under `assets/fonts/`, declared in
  pubspec; Material text roles mapped to a consistent scale; amounts always
  render with tabular figures.
- Spacing on a 4/8 rhythm, radius tokens 12/16/20, one elevation scale.
  Component themes (Card, BottomSheet, InputDecoration, FAB, NavigationBar,
  SnackBar, Dialog, Chip) defined centrally in `AppTheme`.

## 2. Core component kit (`lib/core/widgets/`)

| Widget | Purpose |
|---|---|
| `AmountText` | Formats money with tabular figures; semantic color + sign by transaction type or explicit polarity |
| `HeroCard` | Gradient surface for headline numbers |
| `StatChip` | Small labeled stat (icon + label + value) |
| `SkeletonLoader` | Shimmer placeholder; list- and card-shaped variants |
| `EmptyState` | Icon + message + optional action button |
| `SectionHeader` | Consistent list-section titles |
| `ConfirmSheet` | Styled destructive-action confirmation bottom sheet |

- `AsyncValueWidget` upgraded: default loading becomes a skeleton (callers
  pass a shape hint or custom skeleton), error state gains a retry callback.
- Page transitions: fade-through `pageBuilder` on all go_router routes,
  200-250ms, disabled when `MediaQuery.disableAnimations` is true.

## 3. Dashboard

Hero net-worth card (gradient, large tabular amount, cash + portfolio
`StatChip`s), horizontal account-card carousel, asset performance list
restyled with gain/loss semantic coloring. Data unchanged
(`dashboardProvider`); no API changes.

## 4. Transactions

- Day-granularity sticky date headers ("Today", "Yesterday", else formatted
  date) replacing month grouping.
- Redesigned tile: leading category glyph (icon derived from category/type),
  payee + memo, trailing `AmountText`.
- Swipe actions with visible affordance: swipe-left reveals delete
  (confirmed via `ConfirmSheet`), swipe-right reveals edit.
- **Server-side filter bar:** debounced search plus filter chips (type,
  category, date range) driving the Phase 1 API filters.
  `TransactionsRepository.getPage` gains `type`, `categoryId`, `start`,
  `end`, `search` parameters; the controller family key grows to a filter
  object. Client-side search of loaded pages is removed (fixes the Phase 2
  SMOKE quirk).

## 5. Forms & dialogs

Bottom sheets restyled (drag handle, rounded top, consistent padding).
Transaction dialog: segmented EXPENSE / INCOME / TRANSFER selector,
prominent amount field. Fields, validation, and save payloads unchanged.

## 6. Screen sweep

Accounts, categories, payees, tags, currencies, assets, scheduled,
settings, auth screens restyled with the kit: cards, empty states,
skeleton loading, consistent list tiles. Statistics: fl_chart restyle —
smooth gradient line/area charts, rounded bars, tap tooltips, legend chips,
colors from the chart palette token. Settings loses the color-scheme
picker row.

## 7. Motion

Micro-interactions 150-300ms, ease-out enter / ease-in exit; subtle list
entrance stagger (30-50ms per item, first page only); press feedback
(scale 0.97 or ink) on tappable cards. All motion gated on
`MediaQuery.disableAnimations`.

## 8. Error/loading/empty conventions

Every list screen: skeleton while loading, `EmptyState` when empty,
`AsyncValueWidget` error with retry. Mutations keep call-site
`ApiException` snackbars.

## 9. Testing

- Widget tests for the kit: `AmountText` (color/sign/tabular), `EmptyState`
  action, `AsyncValueWidget` skeleton/error-retry swap.
- Existing suite (102 tests) updated where screens changed (login,
  transactions screen, transaction dialog widget tests) and kept green at
  every task boundary; `flutter analyze --no-fatal-infos` exit 0 throughout.
- No golden tests (no CI, device-dependent rendering).

## Non-goals

- New features or screens (budgets, forecasts, vehicles, splits editor,
  export/import, audit, saved views, admin actions) — Phase 4.
- Navigation structure changes (shell, routes, bottom-nav layout stay).
- Backend changes. The transactions filter params already exist (Phase 1).
