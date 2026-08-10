# Structured Fuel Entry (Mobile) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Structured odometer/liters/full-tank fields in the Flutter transaction dialog, two-way-synced with the `d=… l=… full` memo format, with last-odometer hint and non-blocking plausibility warnings.

**Architecture:** Pure-Dart memo token util mirrors the server parser. A Riverpod `FutureProvider.family` derives fuel-category/last-odometer meta from the existing `GET /api/vehicles/report` endpoint. `TransactionDialog` gains a fuel section below the category dropdown. No server changes.

**Tech Stack:** Flutter/Dart (SDK ^3.11.0), Riverpod (manual providers in this feature), Dio, mocktail + flutter_test. Run commands from `/home/ben/repo/cuenti_mobile`.

**Spec:** `docs/superpowers/specs/2026-08-10-fuel-entry-mobile-design.md`

## Global Constraints

- Memo format `d=<km> l=<liters> [full] <free text>` is canonical output; parser also accepts legacy `v=`, `d:`, `l~`, `45210 km`, `40 l` variants and comma decimals (`41,3`).
- Warnings never block saving.
- Strings hardcoded English (no i18n infra in this app).
- Numbers in built memos have no trailing zeros: `45210` not `45210.0`, `41.3` stays `41.3`.
- Fuel section only for `_type == 'EXPENSE'` (transfers/income never appear in the vehicle report; server filters EXPENSE).
- Test conventions: mocktail mocks of repositories + `ProviderScope(overrides: […])`, see `test/features/transactions/transaction_dialog_test.dart`.
- Run tests: `flutter test <path>`; full suite `flutter test`.
- Commit messages end with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.

---

### Task 1: Fuel memo token util (`fuel_memo.dart`)

**Files:**
- Create: `lib/features/vehicles/domain/fuel_memo.dart`
- Test: `test/features/vehicles/fuel_memo_test.dart`

**Interfaces:**
- Consumes: nothing (pure Dart).
- Produces (used by Tasks 2–4):
  - `class FuelTokens { final double? odometer; final double? liters; final bool fullTank; final String remainderText; bool get hasFuelData; }`
  - `FuelTokens parseFuelTokens(String? memo)` — null-safe, never returns null.
  - `String buildFuelMemo(double? odometer, double? liters, bool fullTank, String remainderText)`

- [ ] **Step 1: Write the failing tests**

Create `test/features/vehicles/fuel_memo_test.dart`:

```dart
import 'package:cuentimobile/features/vehicles/domain/fuel_memo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseFuelTokens', () {
    test('parses tokens and preserves remainder text', () {
      final t = parseFuelTokens('d=45210 l=41.3 full Aral Autobahn');
      expect(t.odometer, 45210);
      expect(t.liters, 41.3);
      expect(t.fullTank, isTrue);
      expect(t.remainderText, 'Aral Autobahn');
      expect(t.hasFuelData, isTrue);
    });

    test('null and empty memo yield empty tokens', () {
      for (final memo in [null, '']) {
        final t = parseFuelTokens(memo);
        expect(t.odometer, isNull);
        expect(t.liters, isNull);
        expect(t.fullTank, isFalse);
        expect(t.remainderText, isEmpty);
        expect(t.hasFuelData, isFalse);
      }
    });

    test('parses legacy secondary notation', () {
      final t = parseFuelTokens('45210 km 40 l');
      expect(t.odometer, 45210);
      expect(t.liters, 40);
      expect(t.fullTank, isFalse);
    });

    test('parses v= liters and comma decimals', () {
      final t = parseFuelTokens('d=195885 v~13,51');
      expect(t.odometer, 195885);
      expect(t.liters, 13.51);
    });
  });

  group('buildFuelMemo', () {
    test('builds canonical memo', () {
      expect(buildFuelMemo(45210, 41.3, true, 'Aral'), 'd=45210 l=41.3 full Aral');
    });

    test('skips missing parts and trailing zeros', () {
      expect(buildFuelMemo(null, 40, false, ''), 'l=40');
      expect(buildFuelMemo(45210.0, null, false, ''), 'd=45210');
      expect(buildFuelMemo(null, null, false, 'just a note'), 'just a note');
      expect(buildFuelMemo(null, null, false, ''), isEmpty);
    });

    test('round-trip is stable', () {
      final built = buildFuelMemo(100500, 38.5, true, 'Shell');
      final t = parseFuelTokens(built);
      expect(t.odometer, 100500);
      expect(t.liters, 38.5);
      expect(t.fullTank, isTrue);
      expect(t.remainderText, 'Shell');
      expect(buildFuelMemo(t.odometer, t.liters, t.fullTank, t.remainderText), built);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/vehicles/fuel_memo_test.dart`
Expected: COMPILATION ERROR — `fuel_memo.dart` does not exist.

- [ ] **Step 3: Implement the util**

Create `lib/features/vehicles/domain/fuel_memo.dart`:

```dart
/// Fuel memo token parsing/building, mirroring the server's
/// VehicleReportService: "d=<km> l=<liters> [full] <free text>".
class FuelTokens {
  const FuelTokens({
    this.odometer,
    this.liters,
    this.fullTank = false,
    this.remainderText = '',
  });

  final double? odometer;
  final double? liters;
  final bool fullTank;
  final String remainderText;

  bool get hasFuelData => odometer != null || liters != null;
}

final _odometerPattern = RegExp(r'd[=:]\s*(\d+(?:[.,]\d+)?)');
final _litersPattern = RegExp(r'[vl][~=:]\s*(\d+(?:[.,]\d+)?)');
final _fullTankPattern = RegExp(r'\bfull\b', caseSensitive: false);
final _secondaryOdometerPattern = RegExp(r'(\d{4,})\s*km');
final _secondaryLitersPattern = RegExp(r'(\d+(?:[.,]\d+)?)\s*[lL](?:\s|$|\))');

double? _extract(String memo, RegExp primary, RegExp secondary) {
  final m = primary.firstMatch(memo) ?? secondary.firstMatch(memo);
  if (m == null) return null;
  return double.tryParse(m.group(1)!.replaceAll(',', '.'));
}

FuelTokens parseFuelTokens(String? memo) {
  final safe = memo ?? '';
  final odometer = _extract(safe, _odometerPattern, _secondaryOdometerPattern);
  final liters = _extract(safe, _litersPattern, _secondaryLitersPattern);
  final fullTank = _fullTankPattern.hasMatch(safe);
  var remainder = safe
      .replaceAll(_odometerPattern, '')
      .replaceAll(_litersPattern, '')
      .replaceAll(_secondaryOdometerPattern, '')
      .replaceAllMapped(_secondaryLitersPattern, (_) => ' ')
      .replaceAll(_fullTankPattern, '');
  remainder = remainder.replaceAll(RegExp(r'\s+'), ' ').trim();
  return FuelTokens(
    odometer: odometer,
    liters: liters,
    fullTank: fullTank,
    remainderText: remainder,
  );
}

String _formatFuelNumber(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Inverse of [parseFuelTokens]: canonical "d=… l=… full <text>".
String buildFuelMemo(
  double? odometer,
  double? liters,
  bool fullTank,
  String remainderText,
) {
  final parts = <String>[
    if (odometer != null) 'd=${_formatFuelNumber(odometer)}',
    if (liters != null) 'l=${_formatFuelNumber(liters)}',
    if (fullTank) 'full',
    if (remainderText.trim().isNotEmpty) remainderText.trim(),
  ];
  return parts.join(' ');
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/vehicles/fuel_memo_test.dart`
Expected: 7 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/vehicles/domain/fuel_memo.dart test/features/vehicles/fuel_memo_test.dart
git commit -m "feat(vehicles): fuel memo token parse/build util

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: Fuel meta provider

**Files:**
- Create: `lib/features/vehicles/ui/fuel_meta_provider.dart`
- Test: `test/features/vehicles/fuel_meta_provider_test.dart`

**Interfaces:**
- Consumes: `vehiclesRepositoryProvider` and `VehiclesRepository.getReport({required int categoryId, DateTime? start, DateTime? end})` (`lib/features/vehicles/data/vehicles_repository.dart:8,20`); `VehicleReport.entries` (`List<FuelEntry>`, date-descending from server) with `FuelEntry.odometer` (`double?`).
- Produces (used by Tasks 3–4):
  - `class FuelMeta { final bool isFuel; final double? lastOdometer; }`
  - `final fuelMetaProvider = FutureProvider.family<FuelMeta, int>(…)` keyed by categoryId.

- [ ] **Step 1: Write the failing tests**

Create `test/features/vehicles/fuel_meta_provider_test.dart`:

```dart
import 'package:cuentimobile/features/vehicles/data/vehicles_repository.dart';
import 'package:cuentimobile/features/vehicles/domain/vehicle_report.dart';
import 'package:cuentimobile/features/vehicles/ui/fuel_meta_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVehiclesRepository extends Mock implements VehiclesRepository {}

void main() {
  late MockVehiclesRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockVehiclesRepository();
    container = ProviderContainer(
      overrides: [vehiclesRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('entries present: isFuel with newest non-null odometer', () async {
    when(
      () => repo.getReport(
        categoryId: 5,
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer(
      (_) async => VehicleReport(
        entries: [
          // Server sends date-descending; newest first has no odometer,
          // the next one does — provider must take the first non-null.
          FuelEntry(date: DateTime(2026, 8, 1), liters: 40),
          FuelEntry(date: DateTime(2026, 7, 1), odometer: 44870, liters: 38),
          FuelEntry(date: DateTime(2026, 6, 1), odometer: 44000, liters: 41),
        ],
      ),
    );

    final meta = await container.read(fuelMetaProvider(5).future);
    expect(meta.isFuel, isTrue);
    expect(meta.lastOdometer, 44870);
  });

  test('no entries: not a fuel category', () async {
    when(
      () => repo.getReport(
        categoryId: 7,
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) async => const VehicleReport());

    final meta = await container.read(fuelMetaProvider(7).future);
    expect(meta.isFuel, isFalse);
    expect(meta.lastOdometer, isNull);
  });

  test('repository error resolves to not-fuel (offline-safe)', () async {
    when(
      () => repo.getReport(
        categoryId: 9,
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenThrow(Exception('offline'));

    final meta = await container.read(fuelMetaProvider(9).future);
    expect(meta.isFuel, isFalse);
    expect(meta.lastOdometer, isNull);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/vehicles/fuel_meta_provider_test.dart`
Expected: COMPILATION ERROR — `fuel_meta_provider.dart` does not exist.

- [ ] **Step 3: Implement the provider**

Create `lib/features/vehicles/ui/fuel_meta_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/vehicles_repository.dart';

/// Whether a category holds fuel entries, and the newest known odometer
/// reading — derived from the existing /vehicles/report endpoint so the
/// transaction dialog needs no new server API.
class FuelMeta {
  const FuelMeta({required this.isFuel, this.lastOdometer});

  final bool isFuel;
  final double? lastOdometer;
}

final fuelMetaProvider = FutureProvider.family<FuelMeta, int>((
  ref,
  categoryId,
) async {
  final repo = ref.watch(vehiclesRepositoryProvider);
  try {
    final report = await repo.getReport(
      categoryId: categoryId,
      start: DateTime(2000, 1, 1),
      end: DateTime.now(),
    );
    double? lastOdometer;
    for (final e in report.entries) {
      if (e.odometer != null) {
        lastOdometer = e.odometer;
        break;
      }
    }
    return FuelMeta(
      isFuel: report.entries.isNotEmpty,
      lastOdometer: lastOdometer,
    );
  } catch (_) {
    // Offline or server error: fall back to "not fuel" — the dialog still
    // shows the fuel section when the memo itself parses.
    return const FuelMeta(isFuel: false);
  }
});
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/vehicles/fuel_meta_provider_test.dart`
Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/vehicles/ui/fuel_meta_provider.dart test/features/vehicles/fuel_meta_provider_test.dart
git commit -m "feat(vehicles): fuel meta provider from report endpoint

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: Fuel section in TransactionDialog (fields, visibility, two-way memo sync)

**Files:**
- Modify: `lib/features/transactions/ui/transaction_dialog.dart` (state class `_TransactionDialogState`; category dropdown ends at line 308; memo field at lines 445-453)
- Test: `test/features/transactions/transaction_dialog_fuel_test.dart` (create)

**Interfaces:**
- Consumes: `parseFuelTokens`, `buildFuelMemo`, `FuelTokens` (Task 1, import `../../vehicles/domain/fuel_memo.dart`); `fuelMetaProvider`, `FuelMeta` (Task 2, import `../../vehicles/ui/fuel_meta_provider.dart`).
- Produces (used by Task 4):
  - State fields: `_fuelOdometer`, `_fuelLiters` (`TextEditingController`), `_fuelFullTank` (`bool`), `_fuelRemainder` (`String`), `_fuelSyncing` (`bool`), `_fuelVisible` (`bool`, set during build).
  - Methods: `double? _parseFuelNum(String text)`, `void _syncMemoFromFuelFields()`, `void _reparseFuelFromMemo(String memo)`.
  - Widget keys: `Key('fuel-odometer')`, `Key('fuel-liters')`, `Key('fuel-full')` on the three inputs.

- [ ] **Step 1: Write the failing tests**

Create `test/features/transactions/transaction_dialog_fuel_test.dart`:

```dart
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/ui/transaction_dialog.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:cuentimobile/features/vehicles/data/vehicles_repository.dart';
import 'package:cuentimobile/features/vehicles/domain/vehicle_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockAccountsRepository extends Mock implements AccountsRepository {}

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

class MockVehiclesRepository extends Mock implements VehiclesRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Transaction(amount: 0, transactionDate: DateTime(2026, 1, 1)),
    );
  });

  late MockTransactionsRepository txRepo;
  late MockAccountsRepository accountsRepo;
  late MockCategoriesRepository categoriesRepo;
  late MockVehiclesRepository vehiclesRepo;

  setUp(() {
    txRepo = MockTransactionsRepository();
    accountsRepo = MockAccountsRepository();
    categoriesRepo = MockCategoriesRepository();
    vehiclesRepo = MockVehiclesRepository();

    when(
      () => accountsRepo.getAll(),
    ).thenAnswer((_) async => [const Account(id: 1, accountName: 'Giro')]);
    when(() => categoriesRepo.getAll(type: any(named: 'type'))).thenAnswer(
      (_) async => const [
        Category(id: 9, name: 'Tanken', type: 'EXPENSE'),
        Category(id: 2, name: 'Food', type: 'EXPENSE'),
      ],
    );
    when(
      () =>
          txRepo.getPage(filter: const TransactionFilter(), page: 0, size: 50),
    ).thenAnswer(
      (_) async => const TransactionPage(
        content: [],
        page: 0,
        size: 50,
        totalElements: 0,
        totalPages: 0,
      ),
    );
    // Category 9 is a fuel category with a known last odometer.
    when(
      () => vehiclesRepo.getReport(
        categoryId: 9,
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer(
      (_) async => VehicleReport(
        entries: [
          FuelEntry(date: DateTime(2026, 7, 1), odometer: 100000, liters: 40),
        ],
      ),
    );
    // Category 2 has no fuel entries.
    when(
      () => vehiclesRepo.getReport(
        categoryId: 2,
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) async => const VehicleReport());
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    Transaction? transaction,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(txRepo),
          accountsRepositoryProvider.overrideWithValue(accountsRepo),
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
          vehiclesRepositoryProvider.overrideWithValue(vehiclesRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(
                  transactionsControllerProvider(
                    filter: const TransactionFilter(),
                  ),
                );
                return TransactionDialog(transaction: transaction);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectCategory(WidgetTester tester, String name) async {
    final dropdown = find.byType(DropdownButtonFormField<int?>).first;
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  testWidgets('fuel section hidden for non-fuel category', (tester) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Food');
    expect(find.byKey(const Key('fuel-odometer')), findsNothing);
  });

  testWidgets('fuel section appears for fuel category with last-odometer '
      'hint', (tester) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');
    expect(find.byKey(const Key('fuel-odometer')), findsOneWidget);
    expect(find.byKey(const Key('fuel-liters')), findsOneWidget);
    expect(find.byKey(const Key('fuel-full')), findsOneWidget);
    expect(find.textContaining('last: 100000'), findsOneWidget);
  });

  testWidgets('field edits write the canonical memo', (tester) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');

    await tester.enterText(
      find.byKey(const Key('fuel-odometer')),
      '100650',
    );
    await tester.enterText(find.byKey(const Key('fuel-liters')), '41,3');
    final fullSwitch = find.byKey(const Key('fuel-full'));
    await tester.ensureVisible(fullSwitch);
    await tester.pumpAndSettle();
    await tester.tap(fullSwitch);
    await tester.pumpAndSettle();

    final memoField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Memo').first,
    );
    expect(memoField.controller!.text, 'd=100650 l=41.3 full');
  });

  testWidgets('editing a fuel transaction populates the fields', (
    tester,
  ) async {
    final existing = Transaction(
      id: 5,
      type: 'EXPENSE',
      amount: 70,
      fromAccountId: 1,
      categoryId: 9,
      transactionDate: DateTime(2026, 8, 1),
      memo: 'd=100650 l=41.3 full Aral',
    );
    await pumpDialog(tester, transaction: existing);

    expect(find.byKey(const Key('fuel-odometer')), findsOneWidget);
    final odometer = tester.widget<TextFormField>(
      find.byKey(const Key('fuel-odometer')),
    );
    final liters = tester.widget<TextFormField>(
      find.byKey(const Key('fuel-liters')),
    );
    expect(odometer.controller!.text, '100650');
    expect(liters.controller!.text, '41.3');
    final fullSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('fuel-full')),
    );
    expect(fullSwitch.value, isTrue);
  });

  testWidgets('typing memo reparses into fields', (tester) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Memo').first,
      'd=100700 l=30',
    );
    await tester.pumpAndSettle();

    final odometer = tester.widget<TextFormField>(
      find.byKey(const Key('fuel-odometer')),
    );
    final liters = tester.widget<TextFormField>(
      find.byKey(const Key('fuel-liters')),
    );
    expect(odometer.controller!.text, '100700');
    expect(liters.controller!.text, '30');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/transactions/transaction_dialog_fuel_test.dart`
Expected: FAIL — `Key('fuel-odometer')` finds nothing (section does not exist).

- [ ] **Step 3: Implement the fuel section**

In `lib/features/transactions/ui/transaction_dialog.dart`:

3a. Add imports at the top (after existing feature imports):

```dart
import '../../vehicles/domain/fuel_memo.dart';
import '../../vehicles/ui/fuel_meta_provider.dart';
```

3b. Add state fields to `_TransactionDialogState` (after `_splitsTouched`, line 62):

```dart
  late TextEditingController _fuelOdometer;
  late TextEditingController _fuelLiters;
  bool _fuelFullTank = false;
  String _fuelRemainder = '';
  bool _fuelSyncing = false;
  bool _fuelVisible = false; // last built visibility, used by _save()
```

3c. In `initState()` (after the `_date = …` line), populate from the memo:

```dart
    final fuelTokens = parseFuelTokens(t?.memo);
    _fuelOdometer = TextEditingController(
      text: fuelTokens.odometer != null
          ? formatFuelNumber(fuelTokens.odometer!)
          : '',
    );
    _fuelLiters = TextEditingController(
      text: fuelTokens.liters != null
          ? formatFuelNumber(fuelTokens.liters!)
          : '',
    );
    _fuelFullTank = fuelTokens.fullTank;
    _fuelRemainder = fuelTokens.remainderText;
```

This needs the number formatter public. In `lib/features/vehicles/domain/fuel_memo.dart`, rename `_formatFuelNumber` to `formatFuelNumber` (public) and update its use in `buildFuelMemo`.

3d. Add sync helpers to `_TransactionDialogState` (below `_parseAmount`):

```dart
  /// Fuel numbers accept comma or dot decimals ("41,3" -> 41.3), unlike
  /// _parseAmount which also strips thousands separators.
  double? _parseFuelNum(String text) =>
      text.isEmpty ? null : double.tryParse(text.replaceAll(',', '.'));

  void _syncMemoFromFuelFields() {
    if (_fuelSyncing) return;
    _fuelSyncing = true;
    _memo.text = buildFuelMemo(
      _parseFuelNum(_fuelOdometer.text),
      _parseFuelNum(_fuelLiters.text),
      _fuelFullTank,
      _fuelRemainder,
    );
    _fuelSyncing = false;
  }

  void _reparseFuelFromMemo(String memo) {
    if (_fuelSyncing) return;
    final tokens = parseFuelTokens(memo);
    _fuelSyncing = true;
    setState(() {
      _fuelOdometer.text = tokens.odometer != null
          ? formatFuelNumber(tokens.odometer!)
          : '';
      _fuelLiters.text = tokens.liters != null
          ? formatFuelNumber(tokens.liters!)
          : '';
      _fuelFullTank = tokens.fullTank;
      _fuelRemainder = tokens.remainderText;
    });
    _fuelSyncing = false;
  }
```

3e. In `build()`, before the `return SafeArea(` line, compute visibility:

```dart
    final fuelMeta = _type == 'EXPENSE' && _categoryId != null
        ? ref.watch(fuelMetaProvider(_categoryId!)).value
        : null;
    _fuelVisible = _type == 'EXPENSE' &&
        ((fuelMeta?.isFuel ?? false) ||
            parseFuelTokens(_memo.text).hasFuelData);
```

3f. Insert the fuel section into the `Column` children directly after the category dropdown's trailing `const SizedBox(height: 12),` (line 309):

```dart
                // Fuel entry (structured tanking fields)
                if (_fuelVisible) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('fuel-odometer'),
                          controller: _fuelOdometer,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Odometer (km)',
                            border: const OutlineInputBorder(),
                            helperText: fuelMeta?.lastOdometer != null
                                ? 'last: ${formatFuelNumber(fuelMeta!.lastOdometer!)}'
                                : null,
                          ),
                          onChanged: (_) =>
                              setState(_syncMemoFromFuelFields),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          key: const Key('fuel-liters'),
                          controller: _fuelLiters,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Liters',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) =>
                              setState(_syncMemoFromFuelFields),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    key: const Key('fuel-full'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Full tank'),
                    value: _fuelFullTank,
                    onChanged: (v) => setState(() {
                      _fuelFullTank = v;
                      _syncMemoFromFuelFields();
                    }),
                  ),
                  const SizedBox(height: 12),
                ],
```

3g. Wire the memo field's reparse — change the existing memo `TextFormField` (lines 446-453) to:

```dart
                TextFormField(
                  controller: _memo,
                  decoration: const InputDecoration(
                    labelText: 'Memo',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: _reparseFuelFromMemo,
                ),
```

3h. Dispose the new controllers — in `dispose()` after `_tags.dispose();`:

```dart
    _fuelOdometer.dispose();
    _fuelLiters.dispose();
```

- [ ] **Step 4: Run the new tests**

Run: `flutter test test/features/transactions/transaction_dialog_fuel_test.dart`
Expected: 5 tests PASS.

- [ ] **Step 5: Run Task 1 tests (formatFuelNumber rename) and existing dialog tests**

Run: `flutter test test/features/vehicles/fuel_memo_test.dart test/features/transactions/transaction_dialog_test.dart`
Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/transactions/ui/transaction_dialog.dart lib/features/vehicles/domain/fuel_memo.dart test/features/transactions/transaction_dialog_fuel_test.dart
git commit -m "feat(transactions): structured fuel fields in transaction dialog

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: Info line, plausibility warnings, empty-save SnackBar

**Files:**
- Modify: `lib/features/transactions/ui/transaction_dialog.dart` (fuel section from Task 3; `_save()` method)
- Test: extend `test/features/transactions/transaction_dialog_fuel_test.dart`

**Interfaces:**
- Consumes: Task 3 state (`_fuelOdometer`, `_fuelLiters`, `_fuelFullTank`, `_fuelVisible`, `_parseFuelNum`) and `fuelMeta` from the build method; `formatFuelNumber` (Task 1/3).
- Produces: `(String, bool)? _fuelInfoLine(double? lastOdometer)` — message + isWarning flag; `String? _fuelLitersWarning` getter.

- [ ] **Step 1: Write the failing tests**

Append to `test/features/transactions/transaction_dialog_fuel_test.dart` (inside `main()`):

```dart
  testWidgets('non-increasing odometer shows warning', (tester) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');

    await tester.enterText(find.byKey(const Key('fuel-odometer')), '99000');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('not higher than the last reading'),
      findsOneWidget,
    );
  });

  testWidgets('plausible full-tank entry shows distance and consumption', (
    tester,
  ) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');

    await tester.enterText(find.byKey(const Key('fuel-odometer')), '100340');
    await tester.enterText(find.byKey(const Key('fuel-liters')), '41,3');
    final fullSwitch = find.byKey(const Key('fuel-full'));
    await tester.ensureVisible(fullSwitch);
    await tester.pumpAndSettle();
    await tester.tap(fullSwitch);
    await tester.pumpAndSettle();

    // 340 km since last, 41.3 / 340 * 100 = 12.1 L/100km
    expect(find.textContaining('340 km since last'), findsOneWidget);
    expect(find.textContaining('12.1'), findsOneWidget);
  });

  testWidgets('implausible liters shows field warning', (tester) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');

    await tester.enterText(find.byKey(const Key('fuel-liters')), '413');
    await tester.pumpAndSettle();

    expect(find.text('Implausible liters value'), findsOneWidget);
  });

  testWidgets('empty fuel fields on save show SnackBar, save proceeds', (
    tester,
  ) async {
    when(() => txRepo.save(any())).thenAnswer(
      (invocation) async =>
          invocation.positionalArguments.single as Transaction,
    );

    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '60',
    );
    // EXPENSE requires a From Account.
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giro').last);
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pump(); // SnackBar appears before the dialog pops

    expect(
      find.textContaining('will not appear in the vehicle report'),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    verify(() => txRepo.save(any())).called(1);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/transactions/transaction_dialog_fuel_test.dart`
Expected: the 4 new tests FAIL (no warning/info widgets, no SnackBar); the 5 Task 3 tests still PASS.

- [ ] **Step 3: Implement info line and warnings**

In `lib/features/transactions/ui/transaction_dialog.dart`:

3a. Add helpers to `_TransactionDialogState` (below `_reparseFuelFromMemo`):

```dart
  String? get _fuelLitersWarning {
    final liters = _parseFuelNum(_fuelLiters.text);
    if (liters == null) return null;
    return (liters <= 0 || liters > 200) ? 'Implausible liters value' : null;
  }

  /// Message + isWarning for the line under the fuel fields; null when
  /// nothing to show. First matching rule wins (mirrors the web app).
  (String, bool)? _fuelInfoLine(double? lastOdometer) {
    final odometer = _parseFuelNum(_fuelOdometer.text);
    if (odometer == null || lastOdometer == null) return null;
    final distance = odometer - lastOdometer;
    if (distance <= 0) {
      return (
        'Odometer is not higher than the last reading '
            '(${formatFuelNumber(lastOdometer)})',
        true,
      );
    }
    if (distance > 2000) {
      return (
        'Very large jump since the last reading '
            '(${formatFuelNumber(distance)} km) — typo?',
        true,
      );
    }
    final liters = _parseFuelNum(_fuelLiters.text);
    if (_fuelFullTank && liters != null && liters > 0) {
      final consumption = (liters / distance * 100).toStringAsFixed(1);
      return (
        '${formatFuelNumber(distance)} km since last, ~$consumption L/100km',
        false,
      );
    }
    return ('${formatFuelNumber(distance)} km since last fill-up', false);
  }
```

3b. In the fuel section (Task 3 block), add `helperText`-style warning to the liters field — change its `decoration` to:

```dart
                          decoration: InputDecoration(
                            labelText: 'Liters',
                            border: const OutlineInputBorder(),
                            helperText: _fuelLitersWarning,
                            helperStyle: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
```

3c. Add the info line between the `Row` and the `SwitchListTile` in the fuel section:

```dart
                  if (_fuelInfoLine(fuelMeta?.lastOdometer) case (
                    final message,
                    final isWarning,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        message,
                        key: const Key('fuel-info'),
                        style: TextStyle(
                          color: isWarning
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
```

3d. Empty-save SnackBar — in `_save()`, directly after the two guard `if`s at the top (line 488-489), add:

```dart
    if (_fuelVisible &&
        _parseFuelNum(_fuelOdometer.text) == null &&
        _parseFuelNum(_fuelLiters.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No km/liters entered — this entry will not appear in the '
            'vehicle report',
          ),
        ),
      );
    }
```

Save proceeds — informational only, no `return`.

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/transactions/transaction_dialog_fuel_test.dart`
Expected: all 9 tests PASS.

- [ ] **Step 5: Run full suite + analyzer**

Run: `flutter analyze && flutter test`
Expected: no analyzer errors; all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/transactions/ui/transaction_dialog.dart test/features/transactions/transaction_dialog_fuel_test.dart
git commit -m "feat(transactions): fuel plausibility warnings and consumption preview

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Notes for implementers

- Dart record patterns (`if (expr case (final a, final b))`) need Dart 3 — the project SDK is ^3.11.0, fine.
- `fuelMetaProvider` watch happens in `build()`; the first frame after selecting a fuel category resolves the future, so tests must `pumpAndSettle()` after category selection (the provided tests do).
- `formatFuelNumber` is public in `fuel_memo.dart` from Task 3 on (renamed from `_formatFuelNumber` in Task 1's code) — Task 3 performs the rename.
- The web app (cuenti repo) is the reference implementation: `VehicleReportService.parseFuelTokens/buildFuelMemo` and the fuel section in `TransactionHistoryView`. Behavior must match (same regexes, same warning thresholds 2000 km / 200 L).
- Server sends `entries` date-descending; `FuelMeta.lastOdometer` takes the first non-null odometer, matching "latest known reading".
- The `_fuelVisible` flag computed in `build()` is what `_save()` consults — it is always current because saving requires a build to have happened.
