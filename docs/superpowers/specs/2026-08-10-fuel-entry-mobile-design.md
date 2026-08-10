# Structured Fuel Entry (Mobile) — Design

**Date:** 2026-08-10
**Status:** Approved

## Problem

Tanking entries on mobile are typed by hand into the transaction memo field as
free text (`d=45210 l=41.3 full`). Typos silently drop the entry from the
vehicle report. Mobile is the primary entry point (at the gas station), so
guided entry and instant feedback matter most here. The web app (cuenti server)
already ships this feature; this design ports it to the Flutter app.

## Goal

Structured odometer/liters/full-tank fields in `TransactionDialog` with
two-way memo sync, last-odometer hint, distance/consumption preview, and
non-blocking plausibility warnings. The memo string `d=… l=… full` remains the
wire and storage format. No server changes.

## Non-Goals

- No new server endpoints (reuse `GET /api/vehicles/report`).
- No i18n infrastructure (app has none; strings stay hardcoded English).
- No offline caching of fuel meta beyond Riverpod's in-memory provider cache.
- No changes to the vehicles report screen.

## Design

### 1. Memo token util — `lib/features/vehicles/domain/fuel_memo.dart`

Pure Dart, mirrors the server logic (`VehicleReportService` in cuenti):

- `class FuelTokens { final double? odometer; final double? liters; final bool fullTank; final String remainderText; bool get hasFuelData; }`
- `FuelTokens parseFuelTokens(String? memo)` — null-safe, never returns null.
  Primary regexes identical to server: odometer `d[=:]\s*(\d+(?:[.,]\d+)?)`,
  liters `[vl][~=:]\s*(\d+(?:[.,]\d+)?)`, full tank `\bfull\b` (case-insensitive).
  Legacy fallbacks: `(\d{4,})\s*km` and `(\d+(?:[.,]\d+)?)\s*[Ll](?:\s|$|\))`.
  Comma decimal separators accepted (`41,3` → 41.3).
  `remainderText` = memo with all fuel tokens stripped, whitespace collapsed.
- `String buildFuelMemo(double? odometer, double? liters, bool fullTank, String remainderText)`
  — canonical `d=<km> l=<liters> [full] <remainder>`; numbers formatted without
  trailing zeros (45210 not 45210.0, 41.3 stays 41.3).

Round-trip invariant: `parseFuelTokens(buildFuelMemo(o, l, f, r))` returns the
same values.

### 2. Fuel meta provider — `lib/features/vehicles/ui/fuel_meta_provider.dart`

Riverpod `FutureProvider.family<FuelMeta, int>`:

- `class FuelMeta { final bool isFuel; final double? lastOdometer; }`
- Implementation: `vehiclesRepository.getReport(categoryId, start: 2000-01-01, end: today)`.
  `isFuel = entries.isNotEmpty`; `lastOdometer` = first entry (entries arrive
  date-descending from the server) with a non-null odometer.
- Any fetch error (offline, 401, 500) resolves to `FuelMeta(isFuel: false, lastOdometer: null)`
  — the fuel section then appears only when the memo already parses, so the
  dialog stays usable offline.
- Provider cache is Riverpod-default (in-memory, per family arg); no manual
  invalidation needed — a fresh dialog session may show a slightly stale
  last-odometer hint after a same-session save, which is acceptable (hint is
  advisory).

### 3. UI — fuel section in `TransactionDialog`

Rendered below the category dropdown, visible when `fuelMeta(categoryId).isFuel`
is true OR the current memo parses (`hasFuelData`):

- Odometer `TextFormField` — `keyboardType: number`, hint/helper shows
  `last: 44870` when `lastOdometer` known.
- Liters `TextFormField` — `keyboardType: numberWithOptions(decimal: true)`,
  accepts comma or dot decimals.
- Full tank `SwitchListTile` (or `CheckboxListTile`, whichever matches the
  dialog's existing style — splits section uses checkboxes).
- Info/warning line (single `Text` widget under the fields), first match wins:
  1. odometer ≤ lastOdometer → "Odometer is not higher than the last reading (44870)" (warning color)
  2. jump > 2000 km → "Very large jump since the last reading (X km) — typo?" (warning color)
  3. full tank + liters > 0 → "340 km since last, ~12.1 L/100km" (consumption = liters/distance×100, 1 decimal)
  4. otherwise, when distance computable → "340 km since last fill-up"
- Liters plausibility (≤ 0 or > 200) → field-level `errorText`-style helper on
  the liters field ("Implausible liters value"), non-blocking.
- Two-way sync:
  - Field/switch change → rebuild memo via `buildFuelMemo`, preserving
    `remainderText` captured from the last parse; guard flag prevents loops.
  - Memo `TextField` change (user-typed) → reparse into fields; same guard.
- On save with fuel section visible and both odometer and liters empty →
  `SnackBar` "No km/liters entered — this entry will not appear in the vehicle
  report"; save proceeds.
- Edit mode: when the transaction's memo parses, populate fields and show the
  section regardless of fuel-meta state.

### 4. Testing

- Unit (`test/features/vehicles/fuel_memo_test.dart`): parse canonical + legacy
  notations, null/empty, remainder preservation, build with missing parts,
  round-trip — mirroring the server's `FuelMemoTokensTest` cases.
- Provider (`test/features/vehicles/fuel_meta_provider_test.dart`): mocktail-
  mocked repository — entries present → isFuel + newest odometer; empty →
  not fuel; repository throws → `FuelMeta(false, null)`.
- Widget (`test/features/transactions/transaction_dialog_fuel_test.dart`):
  section hidden for non-fuel category, shown for fuel category; field edits
  regenerate memo text; typing memo reparses fields; warning line for
  non-increasing odometer; SnackBar on empty-fields save.
