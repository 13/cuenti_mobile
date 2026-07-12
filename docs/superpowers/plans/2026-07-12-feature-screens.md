# Feature Screens Implementation Plan (Phase 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship budgets, forecasts, vehicles, transaction splits, JSON export/import, audit log, saved views, and admin user actions on the Phase 1 API.

**Architecture:** Each new domain repeats the established feature shape — freezed models (`domain/`), repository with `_guard` (`data/`), `@riverpod` controller/provider (`ui/`), screen built from the Phase 3 kit. Navigation: Budgets joins the bottom nav (4 items); Forecasts/Vehicles/Audit go in the drawer (Audit admin-only); export/import are settings rows; saved views live in the transactions filter bar; splits live in the transaction dialog.

**Tech Stack:** Flutter 3.44 (fvm path per env-notes), Riverpod codegen, freezed, fl_chart (P3 styling), dio. New deps: `share_plus`, `file_selector`.

**Spec:** `docs/superpowers/specs/2026-07-12-feature-screens-design.md`
**API reference:** `~/repo/cuenti/docs/superpowers/specs/2026-07-12-rest-api-expansion-design.md` + controllers in `~/repo/cuenti/src/main/java/com/cuenti/app/api/` (source of truth for field names).

## Global Constraints

- Kit + tokens everywhere: no raw hex outside `lib/core/theme/`; money via `AmountText`; lists get skeleton (`AsyncValueWidget(skeleton:)`) + `EmptyState` + `onRetry`; destructive actions via `showConfirmSheet`; charts follow the P3 statistics styling (rounded rods radius 6 width 14, tooltips on `surfaceContainerHighest`, grid `outlineVariant` 50% no vertical, palette/income/expense tokens).
- New repositories copy the 3-line `_guard` helper per file (see `lib/features/accounts/data/accounts_repository.dart`).
- riverpod codegen quirk: default values for `build(...)` params must be `static const` on the class, not inline `const X()` (see `TransactionsController.defaultFilter`). `.value` not `.valueOrNull`.
- Gates at every task end: `flutter test --file-reporter json:/tmp/t.json` all green (baseline 125), `flutter analyze --no-fatal-infos` exit 0 no new warnings, `flutter build apk --debug`.
- Functional parity discipline: when touching existing files (dialog, shell, settings, transactions bar), inventory interactive elements before/after; no dropped handlers.
- Commits end with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`; clean tree at task end.
- Commands: flutter at `/home/ben/fvm/versions/stable/bin/flutter`, wrap in `bash -c`; codegen `dart run build_runner build --delete-conflicting-outputs`.

## File Structure (new)

```
lib/features/budgets/{domain/{budget.dart,budget_progress.dart}, data/budgets_repository.dart, ui/{budgets_controller.dart,budgets_screen.dart}}
lib/features/forecasts/{domain/forecast_data.dart, data/forecasts_repository.dart, ui/{forecasts_controller.dart,forecasts_screen.dart}}
lib/features/vehicles/{domain/vehicle_report.dart, data/vehicles_repository.dart, ui/{vehicles_controller.dart,vehicles_screen.dart}}
lib/features/audit/{domain/audit_entry.dart, data/audit_repository.dart, ui/{audit_controller.dart,audit_screen.dart}}
lib/features/saved_views/{domain/saved_view.dart, data/saved_views_repository.dart, ui/{saved_views_controller.dart,saved_views_sheet.dart}}
lib/features/transactions/domain/transaction_filter_codec.dart
lib/features/user/data/export_import_repository.dart
+ edits: router.dart, shell_screen.dart, transaction_dialog.dart, transactions_{repository,controller,screen}.dart, settings_screen.dart, pubspec.yaml
test/features/{budgets,forecasts,vehicles,audit,saved_views}/..., test/features/transactions/transaction_splits_payload_test.dart
```

---

### Task 1: Budgets feature (models, repo, controller, screen, bottom nav)

**Files:**
- Create: `lib/features/budgets/domain/budget.dart`, `domain/budget_progress.dart`, `data/budgets_repository.dart`, `ui/budgets_controller.dart`, `ui/budgets_screen.dart`
- Modify: `lib/router.dart` (route `/budgets`), `lib/screens/shell_screen.dart` (`_navItems` gains `(icon: Icons.pie_chart, label: 'Budgets', path: '/budgets')` between Transactions and Statistics; drawer 'General' section gains the same entry after Transactions)
- Test: `test/features/budgets/budgets_repository_test.dart`, `budgets_controller_test.dart`, `budgets_screen_test.dart`

**Interfaces:**

Models (freezed; `jsonToDouble` from `lib/features/json_converters.dart` on money fields):

```dart
// budget.dart
@freezed
abstract class Budget with _$Budget {
  const factory Budget({
    int? id,
    required int categoryId,
    String? categoryName,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double monthlyLimit,
    @Default(true) bool active,
  }) = _Budget;
  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);
}

// budget_progress.dart
@freezed
abstract class BudgetProgress with _$BudgetProgress {
  const factory BudgetProgress({
    required int budgetId,
    required int categoryId,
    String? categoryName,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double monthlyLimit,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double spent,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double remaining,
    @Default(true) bool active,
  }) = _BudgetProgress;
  factory BudgetProgress.fromJson(Map<String, dynamic> json) =>
      _$BudgetProgressFromJson(json);
}
```

Repository (explicit write payloads — NEVER `toJson()..remove`):

```dart
final budgetsRepositoryProvider = Provider<BudgetsRepository>(
    (ref) => BudgetsRepository(ref.watch(dioProvider)));

class BudgetsRepository {
  BudgetsRepository(this._dio);
  final Dio _dio;

  Future<List<BudgetProgress>> getProgress() => _guard(() async {
        final res = await _dio.get<List<dynamic>>('/budgets/progress');
        return (res.data ?? [])
            .map((e) => BudgetProgress.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Budget> save(Budget b) => _guard(() async {
        final json = {
          'categoryId': b.categoryId,
          'monthlyLimit': b.monthlyLimit,
          'active': b.active,
        };
        final res = b.id != null
            ? await _dio.put<Map<String, dynamic>>('/budgets/${b.id}',
                data: json)
            : await _dio.post<Map<String, dynamic>>('/budgets', data: json);
        return Budget.fromJson(res.data!);
      });

  Future<void> delete(int id) => _guard(() => _dio.delete<void>('/budgets/$id'));
}
```

Controller: `@riverpod class BudgetsController` — `build()` → `getProgress()`; `save(Budget)` + `delete(int)` invalidate self (delete NOT optimistic — progress list is derived, simple invalidate is fine; document that deviation from the CRUD pattern in a comment).

Screen behavior:
- `AsyncValueWidget(skeleton: SkeletonLoader.tiles(items: 4, height: 96), onRetry: invalidate)`.
- Card per `BudgetProgress` (active first, inactive dimmed `Opacity(0.5)`): categoryName title, `LinearProgressIndicator(value: (spent/monthlyLimit).clamp(0,1))` colored `cuentiColors.expense` when `spent >= monthlyLimit` else `colorScheme.primary`; row of `AmountText(spent, type: 'EXPENSE')` and `AmountText(monthlyLimit)`; remaining line.
- InkWell tap → edit sheet; FAB add. Sheet: category dropdown (from `categoriesControllerProvider`, `type == 'EXPENSE'`, excluding categoryIds already in the progress list except the one being edited), limit `TextFormField` (same numeric parsing as transaction dialog), active `SwitchListTile`, full-width save with `_submitting`. Delete button in edit sheet + swipe-to-delete, both via `showConfirmSheet`.
- Empty: `EmptyState(icon: Icons.pie_chart, message: 'No budgets yet', actionLabel: 'Add budget', onAction: openAddSheet)`.
- 400 from duplicate category → `on ApiException` snackbar (message comes from backend).

Tests:
- Repo: progress parse (2 items, doubles from ints), save POST payload capture (`{'categoryId':2,'monthlyLimit':300.0,'active':true}`, no extra keys, no id), PUT path with id, delete path, one ApiException mapping. Follow `test/features/categories/categories_repository_test.dart` conventions (MockDio + Interceptors stub from `test/helpers/fake_dio.dart`).
- Controller: build loads; save invalidates (repo.getProgress called twice) — ProviderContainer + mocktail per `test/features/accounts/accounts_controller_test.dart`.
- Widget: pump `/budgets` screen with repo override (one over-budget, one under-budget, one inactive) — expect two progress bars + dimmed card; tap FAB → sheet appears with category dropdown; host = `ProviderScope` + `MaterialApp(theme: AppTheme.light(), home: Scaffold(body: BudgetsScreen()))` (Scaffold wrap required — see dashboard test).

Steps: models+codegen → repo test RED → repo GREEN → controller (+test) → screen + nav wiring → widget test → full gates → commit `feat(budgets): budgets screen with progress bars and bottom-nav entry`.

---

### Task 2: Forecasts feature

**Files:**
- Create: `lib/features/forecasts/domain/forecast_data.dart`, `data/forecasts_repository.dart`, `ui/forecasts_controller.dart`, `ui/forecasts_screen.dart`
- Modify: `lib/router.dart` (`/forecasts`), `lib/screens/shell_screen.dart` (drawer 'General' section: `Icons.query_stats, 'Forecasts', '/forecasts'` after Statistics)
- Test: `test/features/forecasts/forecasts_repository_test.dart`

**Interfaces:**

```dart
// forecast_data.dart
@freezed
abstract class MonthForecast with _$MonthForecast {
  const factory MonthForecast({
    required String month, // "YYYY-MM"
    @JsonKey(fromJson: jsonToDouble) @Default(0) double income,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double expense,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double net,
  }) = _MonthForecast;
  factory MonthForecast.fromJson(Map<String, dynamic> json) =>
      _$MonthForecastFromJson(json);
}

@freezed
abstract class ForecastData with _$ForecastData {
  const factory ForecastData({
    required int year,
    @Default([]) List<MonthForecast> months,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double totalIncome,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double totalExpense,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double netForecast,
    @Default('EUR') String currency,
  }) = _ForecastData;
  factory ForecastData.fromJson(Map<String, dynamic> json) =>
      _$ForecastDataFromJson(json);
}
```

Repository: `Future<ForecastData> getForecast(int year)` → GET `/forecasts` `queryParameters: {'year': year}`.
Provider: `@riverpod Future<ForecastData> forecast(Ref ref, {required int year})` (read-only family).

Screen: year `ChoiceChip` row (`DateTime.now().year - 1` … `+2`, default current) in local state; three stat cards (Income/Expense/Net — `AmountText` with income/expense tokens, net colored by sign); grouped `BarChart` — per month two rods (income token, expense token), month initial labels on x-axis, P3 bar styling + tooltips; breakdown list (skip all-zero months): month label (`MMM yyyy` from `DateFormat`), income/expense/net `AmountText` row. Skeleton `SkeletonLoader.card(height: 220)` + tiles; retry invalidates the family instance for the selected year.

Repo test: parse full envelope (12 months, int → double), year param capture, ApiException mapping.

Steps: models → repo test RED → repo → provider → screen + nav → gates → commit `feat(forecasts): yearly forecast screen with monthly chart`.

---

### Task 3: Vehicles feature

**Files:**
- Create: `lib/features/vehicles/domain/vehicle_report.dart`, `data/vehicles_repository.dart`, `ui/vehicles_controller.dart`, `ui/vehicles_screen.dart`
- Modify: `lib/router.dart` (`/vehicles`), `lib/screens/shell_screen.dart` (drawer 'Management' section: `Icons.directions_car, 'Vehicles', '/vehicles'` after Assets)
- Test: `test/features/vehicles/vehicles_repository_test.dart`

**Interfaces:**

```dart
// vehicle_report.dart
@freezed
abstract class FuelEntry with _$FuelEntry {
  const factory FuelEntry({
    required DateTime date, // backend sends yyyy-MM-dd (LocalDate)
    @JsonKey(fromJson: jsonToDoubleN) double? odometer,
    @JsonKey(fromJson: jsonToDoubleN) double? liters,
    @JsonKey(fromJson: jsonToDoubleN) double? amount,
    String? currency,
    String? station,
    String? memo,
    @Default(false) bool fullTank,
    @JsonKey(fromJson: jsonToDoubleN) double? distance,
    @JsonKey(fromJson: jsonToDoubleN) double? pricePerLiter,
    @JsonKey(fromJson: jsonToDoubleN) double? consumption,
  }) = _FuelEntry;
  factory FuelEntry.fromJson(Map<String, dynamic> json) =>
      _$FuelEntryFromJson(json);
}

@freezed
abstract class VehicleReport with _$VehicleReport {
  const factory VehicleReport({
    @Default([]) List<FuelEntry> entries,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double totalCost,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double totalLiters,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double totalDistance,
    @JsonKey(fromJson: jsonToDoubleN) double? avgConsumption,
    @JsonKey(fromJson: jsonToDoubleN) double? avgPricePerLiter,
    @Default('EUR') String currency,
  }) = _VehicleReport;
  factory VehicleReport.fromJson(Map<String, dynamic> json) =>
      _$VehicleReportFromJson(json);
}
```

Repository: `Future<VehicleReport> getReport({required int categoryId, DateTime? start, DateTime? end})` → GET `/vehicles/report` with `categoryId` + optional `start`/`end` as `yyyy-MM-dd` (`DateFormat`).
Provider: `@riverpod Future<VehicleReport> vehicleReport(Ref ref, {required int categoryId, DateTime? start, DateTime? end})`.

Screen behavior:
- Local state: `int? _categoryId` initialized from `ref.read(authControllerProvider).user?.defaultVehicleCategoryId`; `_start/_end` default Jan 1 / Dec 31 current year.
- No category (null and no default): `EmptyState(icon: Icons.directions_car, message: 'Pick a fuel category to see your vehicle report', actionLabel: 'Choose category', onAction: openCategorySheet)`.
- Chips row: category `InputChip` (sheet of EXPENSE categories from `categoriesControllerProvider`; sheet rows have a star `IconButton` → `ref.read(userRepositoryProvider).updatePreferences({'defaultVehicleCategoryId': id})` then `authController.refreshProfile()`, snackbar 'Default saved'); date-range chips (`This year` / custom via `showDateRangePicker`).
- Stat cards: total cost (`AmountText(totalCost, currency: report.currency)`), liters, distance km, ⌀ `avgConsumption` l/100km (— when null), ⌀ `avgPricePerLiter` (tabular text, 3 decimals).
- Consumption `LineChart` over entries with non-null `consumption` (P3 curved+gradient styling, palette[0]); hidden when <2 points.
- Entries list (already date-descending from API): date + station title, `odometer km · liters L` subtitle, trailing `AmountText(amount)`, `fullTank` → small 'Full' `Chip`, consumption value line when present.

Repo test: report parse (entries + totals, nullable fields), param capture (categoryId + yyyy-MM-dd dates, omitted when null), ApiException.

Steps as Task 2. Commit `feat(vehicles): fuel report screen with consumption chart and default-category preference`.

---

### Task 4: Transaction split editor

**Files:**
- Modify: `lib/features/transactions/data/transactions_repository.dart` (save signature), `lib/features/transactions/ui/transactions_controller.dart` (pass-through), `lib/features/transactions/ui/transaction_dialog.dart` (splits section)
- Test: `test/features/transactions/transaction_splits_payload_test.dart` (new), updates to `transactions_repository_test.dart` + `transaction_dialog_test.dart`

**Interfaces:**

Repository change — `save` gains a named flag (default preserves every existing caller/test):

```dart
/// [splitsTouched]: the caller explicitly manages splits. When false
/// (default) the splits key is stripped for backend back-compat (omitted =
/// unchanged server-side). When true, t.splits is sent verbatim — an empty
/// list means deliberate remove-all.
Future<Transaction> save(Transaction t, {bool splitsTouched = false}) =>
    _guard(() async {
      final json = t.toJson()
        ..remove('id')
        ..remove('fromAccountName')
        ..remove('toAccountName')
        ..remove('categoryName')
        ..remove('assetName')
        ..remove('status');
      json['paymentMethod'] = t.paymentMethod ?? 'NONE';
      if (!splitsTouched) {
        json.remove('splits');
      } else {
        json['splits'] = t.splits
            .map((s) => {
                  'categoryId': s.categoryId,
                  'amount': s.amount,
                  if (s.memo != null) 'memo': s.memo,
                })
            .toList();
      }
      // ... unchanged PUT/POST + parse
    });
```

Controller: `Future<void> save(Transaction t, {bool splitsTouched = false})` passes through (invalidation unchanged).

Dialog behavior:
- New collapsible section after the category field, hidden when `_type == 'TRANSFER'`: header row 'Splits' + add `IconButton`. Each split row: category `DropdownButtonFormField` (categories of `_type`), amount field (same parsing as main amount), memo field, remove `IconButton`. Backed by a local `List<_SplitDraft>` (`{int? categoryId, TextEditingController amount, TextEditingController memo}`) initialized from `widget.existing?.splits`.
- `bool _splitsTouched` starts false; ANY add/remove/edit of a split row sets it true. (Editing a transaction that has splits but never touching the section keeps it false → key omitted → server keeps them.)
- Validation banner between section and save button when `_splitsTouched && rows.isNotEmpty`: sum of split amounts vs main amount; mismatch shows `Text` in `colorScheme.error` ('Splits must sum to the amount: X of Y') and disables Save. Every row must have a category (else same banner text 'Each split needs a category').
- `_save()` builds `splits: [...]` on the Transaction (`TransactionSplit(categoryId:, amount:, memo:)`) and calls `.save(transaction, splitsTouched: _splitsTouched)`.
- Backend rejects mismatches anyway (400) — client banner mirrors it; keep the ApiException snackbar as backstop.

Tests:
- `transaction_splits_payload_test.dart` (repository level, MockDio capture):
  1. `splitsTouched: false` (default) → payload has NO `splits` key even when `t.splits` non-empty.
  2. `splitsTouched: true` with 2 splits → payload `splits` = exact list of `{categoryId, amount, memo?}` maps.
  3. `splitsTouched: true` with empty list → payload `splits: []` present.
- Dialog widget test additions: open dialog for a transaction WITH 2 splits, don't touch section, save → captured payload has no splits key; add a split, mismatched sum → Save disabled + banner text found; fix sum → save → payload splits length 3.

Steps: payload tests RED → repo+controller change → GREEN → dialog UI → widget tests → full gates (existing dialog/screen tests must stay green) → commit `feat(transactions): split editor with omitted-vs-empty payload semantics`.

---

### Task 5: JSON export/import

**Files:**
- Modify: `pubspec.yaml` (add deps), `lib/features/user/ui/settings_screen.dart` (two rows in a new 'Data' section between 'Server' and 'Administration')
- Create: `lib/features/user/data/export_import_repository.dart`
- Test: `test/features/user/export_import_repository_test.dart`

**Interfaces:**

```bash
flutter pub add share_plus file_selector
```

```dart
final exportImportRepositoryProvider = Provider<ExportImportRepository>(
    (ref) => ExportImportRepository(ref.watch(dioProvider)));

class ExportImportRepository {
  ExportImportRepository(this._dio);
  final Dio _dio;

  /// Raw JSON export string from the backend.
  Future<String> exportJson() => _guard(() async {
        final res = await _dio.get<String>('/json-export-import/export',
            options: Options(responseType: ResponseType.plain));
        return res.data ?? '';
      });

  Future<void> importJson(String json) =>
      _guard(() => _dio.post<void>('/json-export-import/import',
          data: json,
          options: Options(contentType: 'application/json')));
}
```

Settings rows (new `SectionHeader('Data')`):
- 'Export data' (`Icons.upload_file`): calls `exportJson()`, writes to `${Directory.systemTemp.path}/cuenti-export-<yyyy-MM-dd>.json`, then `SharePlus.instance.share(ShareParams(files: [XFile(path)]))` (check installed share_plus major version for exact API — `Share.shareXFiles([XFile(path)])` on v10-era; use whichever the resolved version exposes and note it in the report). `_submitting` row spinner while running; ApiException snackbar on failure.
- 'Import data' (`Icons.download`): `openFile(acceptedTypeGroups: [XTypeGroup(label: 'JSON', extensions: ['json'])])` (file_selector); null → no-op; then `showConfirmSheet(title: 'Import data?', message: 'This replaces data on the server with the file contents.', confirmLabel: 'Import')`; on confirm read the file string, `importJson(...)`, success snackbar 'Import complete', then invalidate the full provider set (same 10-provider list as the shell refresh button — extract that list into a shared helper `void invalidateAllData(WidgetRef ref)` in `lib/core/router/…` no — put it in `lib/core/widgets/refresh_all.dart` and have BOTH shell_screen and the import row call it; update shell_screen accordingly).

Repo test: export GET plain-text parse; import POST body capture (raw string passed through, content-type json); ApiException mapping.

Steps: deps → repo test RED → repo → GREEN → refresh_all extraction + settings rows → gates (settings has no widget tests; suite must stay green) → commit `feat(data): JSON export via share sheet and import with confirm`.

---

### Task 6: Audit log (admin)

**Files:**
- Create: `lib/features/audit/domain/audit_entry.dart`, `data/audit_repository.dart`, `ui/audit_controller.dart`, `ui/audit_screen.dart`
- Modify: `lib/router.dart` (`/audit`), `lib/screens/shell_screen.dart` (drawer 'Settings' section, BEFORE Settings row, rendered only when `auth.user?.isAdmin == true`: `Icons.history, 'Audit Log', '/audit'`)
- Test: `test/features/audit/audit_repository_test.dart`, `audit_controller_test.dart`

**Interfaces:**

```dart
@freezed
abstract class AuditEntry with _$AuditEntry {
  const factory AuditEntry({
    required int id,
    int? userId,
    String? username,
    required DateTime timestamp,
    String? entityType,
    int? entityId,
    String? action, // CREATE | UPDATE | DELETE
    String? details,
  }) = _AuditEntry;
  factory AuditEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditEntryFromJson(json);
}

@freezed
abstract class AuditPage with _$AuditPage {
  const factory AuditPage({
    @Default([]) List<AuditEntry> content,
    @Default(0) int page,
    @Default(50) int size,
    @Default(0) int totalElements,
    @Default(0) int totalPages,
  }) = _AuditPage;
  factory AuditPage.fromJson(Map<String, dynamic> json) =>
      _$AuditPageFromJson(json);
}
```

Repository: `Future<AuditPage> getPage({int page = 0, int size = 50, String? filter})` → GET `/audit-log` (filter omitted when null/empty).

Controller — paged family on `filter`, mirroring `TransactionsController` exactly (state: items/nextPage/hasMore/loadingMore; `loadMore()` guard + append; no mutations):

```dart
@freezed
abstract class AuditState with _$AuditState {
  const factory AuditState({
    @Default([]) List<AuditEntry> items,
    @Default(0) int nextPage,
    @Default(true) bool hasMore,
    @Default(false) bool loadingMore,
    String? filter,
  }) = _AuditState;
}

@riverpod
class AuditController extends _$AuditController {
  static const pageSize = 50;
  @override
  Future<AuditState> build({String? filter}) async { /* page 0 fetch, same shape as TransactionsController.build */ }
  Future<void> loadMore() async { /* same guard/append shape */ }
}
```

Screen: debounced (350ms) filter `TextField`; `CustomScrollView`-less simple `ListView` (no day grouping) with scroll-trigger loadMore + bottom `loadingMore` row + `on ApiException` snackbar (copy `_loadMore` shape from transactions_screen); tile: leading glyph circle (`Icons.add_circle_outline`/`edit`/`delete` for CREATE/UPDATE/DELETE, tinted `income`/`transfer`/`expense` at 12%), title `entityType · details` (ellipsized), subtitle `username · dd.MM.yyyy HH:mm`; empty `EmptyState(icon: Icons.history, message: 'No audit entries')`.

Tests: repo (envelope parse, filter/page param capture + omission, ApiException); controller (build page 0, loadMore appends + hasMore flip, no-op when exhausted — mirror `transactions_controller_test.dart`).

Steps: models → repo test RED → repo → controller test RED → controller → screen + gated drawer entry + route → gates → commit `feat(audit): admin audit log with paging and filter`.

---

### Task 7: Saved views

**Files:**
- Create: `lib/features/saved_views/domain/saved_view.dart`, `data/saved_views_repository.dart`, `ui/saved_views_controller.dart`, `ui/saved_views_sheet.dart`, `lib/features/transactions/domain/transaction_filter_codec.dart`
- Modify: `lib/features/transactions/ui/transactions_screen.dart` (bookmark IconButton in the filter bar row)
- Test: `test/features/saved_views/transaction_filter_codec_test.dart`, `saved_views_repository_test.dart`, `saved_views_sheet_test.dart`

**Interfaces:**

```dart
// saved_view.dart
@freezed
abstract class SavedView with _$SavedView {
  const factory SavedView({
    int? id,
    required String name,
    String? params,
    DateTime? createdAt,
  }) = _SavedView;
  factory SavedView.fromJson(Map<String, dynamic> json) =>
      _$SavedViewFromJson(json);
}
```

Codec (`transaction_filter_codec.dart`) — versioned JSON so the web app's own params format fails cleanly:

```dart
/// Serializes TransactionFilter into the opaque `params` string stored by
/// the saved-views API. Versioned envelope: {"v":1,"accountId":…,…}.
/// Returns null from [decode] for anything it doesn't understand (e.g.
/// params written by the web app).
abstract final class TransactionFilterCodec {
  static String encode(TransactionFilter f) => jsonEncode({
        'v': 1,
        if (f.accountId != null) 'accountId': f.accountId,
        if (f.type != null) 'type': f.type,
        if (f.categoryId != null) 'categoryId': f.categoryId,
        if (f.start != null) 'start': DateFormat('yyyy-MM-dd').format(f.start!),
        if (f.end != null) 'end': DateFormat('yyyy-MM-dd').format(f.end!),
        if (f.search != null && f.search!.isNotEmpty) 'search': f.search,
      });

  static TransactionFilter? decode(String? params) {
    if (params == null || params.isEmpty) return null;
    try {
      final map = jsonDecode(params);
      if (map is! Map<String, dynamic> || map['v'] != 1) return null;
      return TransactionFilter(
        accountId: map['accountId'] as int?,
        type: map['type'] as String?,
        categoryId: map['categoryId'] as int?,
        start: map['start'] != null ? DateTime.parse(map['start'] as String) : null,
        end: map['end'] != null ? DateTime.parse(map['end'] as String) : null,
        search: map['search'] as String?,
      );
    } on FormatException {
      return null;
    }
  }
}
```

Repository: `getAll()` GET `/saved-views` → `List<SavedView>`; `save(String name, String params)` POST `/saved-views` body `{'name': name, 'params': params}` (upserts by name server-side); `delete(int id)` DELETE.

Controller: standard list controller (build → getAll; saveCurrent(name, filter) → repo.save(name, TransactionFilterCodec.encode(filter)) + invalidateSelf; delete optimistic-revert like accounts).

Sheet (`saved_views_sheet.dart`): `showSavedViewsSheet(BuildContext, WidgetRef, {required TransactionFilter current, required ValueChanged<TransactionFilter> onApply})` — bottom sheet: list of views (decodable → enabled ListTile, tap `onApply(decoded)` + pop; undecodable → disabled tile with 'Saved by web app' subtitle), trailing delete IconButton (`showConfirmSheet`), bottom `FilledButton` 'Save current view' enabled when `current != TransactionsController.defaultFilter` → name prompt dialog (TextField + save) → `saveCurrent`.

Transactions screen: bookmark `IconButton(icon: Icons.bookmark_outline)` at the end of the filter-chips row → `showSavedViewsSheet(..., current: _filter, onApply: (f) => setState(() => _filter = f))`.

Tests:
- Codec: round-trip full filter; decode returns null for `'{"someWebFormat":true}'`, `'not json'`, `''`, version-2 envelope.
- Repo: parse list, POST body capture, delete, ApiException.
- Sheet widget test: pump with repo override (one mobile-encoded view, one web-format view) → one enabled + one disabled tile; tap enabled → onApply called with decoded filter; 'Save current view' disabled with default filter, enabled with a search filter.

Steps: codec test RED → codec → repo test RED → repo → controller → sheet + screen button → widget test → gates → commit `feat(saved-views): save and apply transaction filters`.

---

### Task 8: Admin user actions (restore)

**Files:**
- Modify: `lib/features/user/ui/settings_screen.dart` (admin panel user rows)
- Test: none new (repository methods `setUserEnabled`/`deleteUser` already tested since Phase 2)

Behavior: each user `ListTile` in `_AdminPanel` gains a trailing `PopupMenuButton<String>` (keep the 'API ✓' text — put both in a `Row(mainAxisSize: MainAxisSize.min)`): items 'Enable', 'Disable', 'Delete'. Enable/Disable → `ref.read(userRepositoryProvider).setUserEnabled(u.id!, true/false)` then `ref.invalidate(adminUsersProvider)`. Delete → `showConfirmSheet(title: 'Delete ${u.username}?', message: 'This permanently removes the user and their data.')` then `deleteUser(u.id!)` + invalidate. Guard: hide the menu on the CURRENT user's own row (`u.username == authState.user?.username`) — self-delete via mobile is a footgun. `on ApiException` snackbar wrapping.

This was reverted in Phase 2 as out-of-scope; it is now the spec-mandated deliverable (spec §8).

Steps: implement → gates → commit `feat(admin): user enable/disable/delete actions in admin panel`.

---

### Task 9: Final gate + smoke + docs

- [ ] Full gates: analyze exit 0, suite green (json-verified), debug APK.
- [ ] Greps: `grep -rn "Color(0x" lib/features lib/screens --include="*.dart"` → zero; `grep -rn "toJson()..remove" lib/features/*/data/*.dart` → only the transactions repository (documented exception).
- [ ] Append to `docs/superpowers/plans/2026-07-12-mobile-rearchitect-SMOKE.md` a Phase 4 checklist: budgets CRUD + over-budget bar color; forecasts year switch + chart tooltips; vehicles category default star + report numbers vs web; split create/edit/omit/clear against a web-created split transaction; export share sheet opens with valid JSON; import round-trip restores data; audit log paging + filter (admin); saved view save/apply/delete + web-created view shows disabled; admin enable/disable/delete (not on self). Remove the Phase-2 quirk line about split edits being rejected (split editor now exists — editing amounts adjusts splits in the dialog).
- [ ] Commit `docs: phase 4 smoke checklist`.
- [ ] Whole-branch review dispatch (controller does this).
