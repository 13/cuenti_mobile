# UI Overhaul Implementation Plan (Phase 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fixed brand identity (emerald-teal palette + Manrope), a reusable component kit (amounts, hero cards, skeletons, empty states), restyled screens and charts, purposeful motion — plus server-side transaction filters/search.

**Architecture:** All visual decisions live in `lib/core/theme/` (ColorSchemes + `ThemeExtension<CuentiColors>` + component themes) and `lib/core/widgets/` (kit). Screens consume tokens and kit widgets only — no raw hex, no ad-hoc text styles for amounts. The only data-layer change is `TransactionsRepository.getPage` gaining filter params and the controller family key becoming a filter object.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod codegen, freezed, fl_chart, go_router. Flutter binary: `/home/ben/fvm/versions/stable/bin/flutter` (wrap commands in `bash -c`).

**Spec:** `docs/superpowers/specs/2026-07-12-ui-overhaul-design.md`

## Global Constraints

- No new features/screens; no navigation-structure changes; no backend changes. Functional changes allowed: server-side transaction filters/search (spec §4) and removal of the color-seed picker (spec Decisions).
- No raw hex in widgets — colors come from `Theme.of(context).colorScheme` or `context.cuentiColors` (the `CuentiColors` extension). Amounts always render via `AmountText` (tabular figures).
- Palette anchors (verbatim from spec): primary `#0E8A6B`; light: background `#F7F9F8`, surface white, outline `#DCE5E1`, onSurface `#16211D`; dark: background `#0E1513`, surface `#16201C`, surfaceContainerHigh `#1D2925`, onSurface `#E5EDE9`. Income light `#1E9E63` / dark `#5CC894`; expense light `#D64545` / dark `#F07575`.
- Motion: 150-300ms, ease-out enter / ease-in exit; ALL motion gated on `MediaQuery.disableAnimations` (wrap check in the kit, not per screen).
- Gates at every task end: `flutter test --file-reporter json:/tmp/t.json` all green (102 baseline, count grows), `flutter analyze --no-fatal-infos` exit 0 with no new warnings/errors, `flutter build apk --debug` succeeds.
- Commits end with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- Working tree clean at every task end; screens are EDITED in place (no moves this phase).

## File Structure (new/heavily-modified)

```
assets/fonts/Manrope-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf   (new)
lib/core/theme/app_theme.dart          (rewritten: schemes, textTheme, component themes)
lib/core/theme/cuenti_colors.dart      (new: ThemeExtension + context accessor)
lib/core/widgets/amount_text.dart      (new)
lib/core/widgets/hero_card.dart        (new)
lib/core/widgets/stat_chip.dart        (new)
lib/core/widgets/skeleton_loader.dart  (new)
lib/core/widgets/empty_state.dart      (new)
lib/core/widgets/section_header.dart   (new)
lib/core/widgets/confirm_sheet.dart    (new)
lib/core/widgets/async_value_widget.dart (upgraded)
lib/core/router/transitions.dart       (new: fade-through page builder)
lib/features/transactions/domain/transaction_filter.dart (new, freezed)
+ edits: router.dart, main.dart, auth_controller.dart, every screen file,
  transactions repository/controller, settings (picker removal)
test/core/{app_theme_test,amount_text_test,widgets_test}.dart (new)
test/features/transactions/* (updated for filter)
```

---

### Task 1: Brand theme foundation (palette, fonts, tokens, seed retirement)

**Files:**
- Create: `lib/core/theme/cuenti_colors.dart`, `assets/fonts/` (5 Manrope TTFs)
- Rewrite: `lib/core/theme/app_theme.dart`
- Modify: `pubspec.yaml` (fonts + assets), `lib/main.dart` (theme wiring), `lib/features/auth/ui/auth_controller.dart` (retire colorSchemeSeed), `lib/features/user/ui/settings_screen.dart` (remove picker rows + `_colorOptions` + color sheet)
- Test: `test/core/app_theme_test.dart`

**Interfaces (later tasks rely on):**
- `AppTheme.light()` / `AppTheme.dark()` → `ThemeData` (no args; old `build(seed, brightness)` deleted).
- `CuentiColors` ThemeExtension: fields `Color income, Color expense, Color transfer, Gradient heroGradient, List<Color> chartPalette` (6 entries); static `light`/`dark` instances; accessor `extension CuentiColorsX on BuildContext { CuentiColors get cuentiColors; }` (reads `Theme.of(this).extension<CuentiColors>()!`).
- Semantic color helper for transaction types: `Color amountColorFor(BuildContext, String type)` — EXPENSE → expense, INCOME → income, else transfer. Lives in `cuenti_colors.dart`.

- [ ] **Step 1: Fetch and bundle Manrope**

```bash
mkdir -p /home/ben/repo/cuenti_mobile/assets/fonts && cd /tmp && \
curl -fL -o manrope.zip "https://gwfh.mranftl.com/api/fonts/manrope?download=zip&subsets=latin&variants=regular,500,600,700,800&formats=ttf" && \
unzip -o manrope.zip -d manrope-ttf && ls manrope-ttf
```

Rename/copy into the repo as `Manrope-Regular.ttf` (400), `Manrope-Medium.ttf` (500), `Manrope-SemiBold.ttf` (600), `Manrope-Bold.ttf` (700), `Manrope-ExtraBold.ttf` (800) under `assets/fonts/`.
FALLBACK if the endpoint is down: download the variable font `https://github.com/google/fonts/raw/main/ofl/manrope/Manrope%5Bwght%5D.ttf`, then instance static weights with fontTools if available (`pip install fonttools; fonttools varLib.instancer Manrope[wght].ttf wght=400 -o Manrope-Regular.ttf` etc.); if neither path works, report BLOCKED.

pubspec.yaml additions (under `flutter:`):

```yaml
  fonts:
    - family: Manrope
      fonts:
        - asset: assets/fonts/Manrope-Regular.ttf
          weight: 400
        - asset: assets/fonts/Manrope-Medium.ttf
          weight: 500
        - asset: assets/fonts/Manrope-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Manrope-Bold.ttf
          weight: 700
        - asset: assets/fonts/Manrope-ExtraBold.ttf
          weight: 800
```

- [ ] **Step 2: Write the failing theme test**

`test/core/app_theme_test.dart`:

```dart
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG relative-luminance contrast ratio.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final light = AppTheme.light();
  final dark = AppTheme.dark();

  test('body text meets WCAG 4.5:1 in both modes', () {
    for (final t in [light, dark]) {
      final cs = t.colorScheme;
      expect(contrast(cs.onSurface, cs.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(cs.onPrimary, cs.primary), greaterThanOrEqualTo(4.5));
      expect(
          contrast(cs.onSurfaceVariant, cs.surface), greaterThanOrEqualTo(4.5));
    }
  });

  test('semantic tokens present with 3:1 contrast vs surface', () {
    for (final t in [light, dark]) {
      final c = t.extension<CuentiColors>()!;
      final surface = t.colorScheme.surface;
      expect(contrast(c.income, surface), greaterThanOrEqualTo(3.0));
      expect(contrast(c.expense, surface), greaterThanOrEqualTo(3.0));
      expect(c.chartPalette.length, 6);
    }
  });

  test('Manrope is the theme font', () {
    expect(light.textTheme.bodyMedium!.fontFamily, 'Manrope');
    expect(dark.textTheme.titleLarge!.fontFamily, 'Manrope');
  });

  test('brand anchors', () {
    expect(light.colorScheme.primary, const Color(0xFF0E8A6B));
    expect(light.scaffoldBackgroundColor, const Color(0xFFF7F9F8));
    expect(dark.scaffoldBackgroundColor, const Color(0xFF0E1513));
  });
}
```

- [ ] **Step 3: Run to verify RED** (`AppTheme.light` undefined). `bash -c '/home/ben/fvm/versions/stable/bin/flutter test test/core/app_theme_test.dart'`

- [ ] **Step 4: Implement**

`lib/core/theme/cuenti_colors.dart`:

```dart
import 'package:flutter/material.dart';

/// Brand-semantic colors the Material ColorScheme has no roles for.
/// Widgets access these via `context.cuentiColors` — never raw hex.
class CuentiColors extends ThemeExtension<CuentiColors> {
  const CuentiColors({
    required this.income,
    required this.expense,
    required this.transfer,
    required this.heroGradient,
    required this.chartPalette,
  });

  final Color income;
  final Color expense;
  final Color transfer;
  final Gradient heroGradient;
  final List<Color> chartPalette;

  static const light = CuentiColors(
    income: Color(0xFF1E9E63),
    expense: Color(0xFFD64545),
    transfer: Color(0xFF5B7286),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF12A57F), Color(0xFF0A5C4A)],
    ),
    chartPalette: [
      Color(0xFF0E8A6B), // teal (brand)
      Color(0xFFB9821D), // amber
      Color(0xFF4F63C2), // indigo
      Color(0xFFC25B4F), // coral
      Color(0xFF2793A8), // cyan
      Color(0xFF8A5BA6), // purple
    ],
  );

  static const dark = CuentiColors(
    income: Color(0xFF5CC894),
    expense: Color(0xFFF07575),
    transfer: Color(0xFF8FA6BA),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F8065), Color(0xFF07443A)],
    ),
    chartPalette: [
      Color(0xFF3FB392), // teal
      Color(0xFFD9A94A), // amber
      Color(0xFF8B9BE0), // indigo
      Color(0xFFE08A80), // coral
      Color(0xFF5BB8CC), // cyan
      Color(0xFFB78CD1), // purple
    ],
  );

  @override
  CuentiColors copyWith({
    Color? income,
    Color? expense,
    Color? transfer,
    Gradient? heroGradient,
    List<Color>? chartPalette,
  }) {
    return CuentiColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      transfer: transfer ?? this.transfer,
      heroGradient: heroGradient ?? this.heroGradient,
      chartPalette: chartPalette ?? this.chartPalette,
    );
  }

  @override
  CuentiColors lerp(CuentiColors? other, double t) {
    if (other == null) return this;
    return CuentiColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      heroGradient: Gradient.lerp(heroGradient, other.heroGradient, t)!,
      chartPalette: [
        for (var i = 0; i < chartPalette.length; i++)
          Color.lerp(chartPalette[i], other.chartPalette[i], t)!,
      ],
    );
  }
}

extension CuentiColorsX on BuildContext {
  CuentiColors get cuentiColors => Theme.of(this).extension<CuentiColors>()!;
}

/// Semantic amount color for a transaction type string.
Color amountColorFor(BuildContext context, String type) {
  final c = context.cuentiColors;
  return switch (type) {
    'EXPENSE' => c.expense,
    'INCOME' => c.income,
    _ => c.transfer,
  };
}
```

`lib/core/theme/app_theme.dart` — rewrite. Build both schemes with `ColorScheme.fromSeed(seedColor: Color(0xFF0E8A6B), brightness: ...)` then `.copyWith` the anchor overrides so Material tonal roles stay coherent:

```dart
import 'package:flutter/material.dart';
import 'cuenti_colors.dart';

class AppTheme {
  static const _seed = Color(0xFF0E8A6B);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed).copyWith(
      primary: _seed,
      surface: Colors.white,
      onSurface: const Color(0xFF16211D),
      onSurfaceVariant: const Color(0xFF44534D),
      outlineVariant: const Color(0xFFDCE5E1),
      surfaceContainerHighest: const Color(0xFFEEF3F1),
    );
    return _base(scheme, CuentiColors.light)
        .copyWith(scaffoldBackgroundColor: const Color(0xFFF7F9F8));
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark)
            .copyWith(
      primary: const Color(0xFF3FB392),
      onPrimary: const Color(0xFF072A21),
      surface: const Color(0xFF16201C),
      onSurface: const Color(0xFFE5EDE9),
      onSurfaceVariant: const Color(0xFFA9BBB3),
      outlineVariant: const Color(0xFF2C3A34),
      surfaceContainerHighest: const Color(0xFF1D2925),
    );
    return _base(scheme, CuentiColors.dark)
        .copyWith(scaffoldBackgroundColor: const Color(0xFF0E1513));
  }

  static ThemeData _base(ColorScheme scheme, CuentiColors cuenti) {
    final textTheme = Typography.material2021(colorScheme: scheme)
        .englishLike
        .apply(
          fontFamily: 'Manrope',
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      extensions: [cuenti],
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
```

(If a contrast assertion fails, adjust the failing TONE minimally — keep the role structure. Document any adjusted hex in the report.)

`lib/main.dart`: `theme: AppTheme.light(), darkTheme: AppTheme.dark(),` (auth watch stays only for `themeMode`).

Seed retirement:
- `auth_controller.dart`: delete `colorSchemeSeed` field from `AuthState`, the storage read in `_init`, `setColorSchemeSeed`, and the `_colorKey` const. Codegen re-run.
- `settings_screen.dart`: delete the Color Scheme `ListTile`, `_colorOptions`, and the color-picker sheet method.

- [ ] **Step 5: Codegen + gates**

`dart run build_runner build --delete-conflicting-outputs`; run theme test → PASS; full `flutter test` (some auth-controller tests may reference colorSchemeSeed — update them); analyze; debug build.

- [ ] **Step 6: Commit** `feat(theme): fixed brand palette, Manrope, CuentiColors tokens; retire color-seed picker`

---

### Task 2: Component kit + page transitions

**Files:**
- Create: `lib/core/widgets/amount_text.dart`, `hero_card.dart`, `stat_chip.dart`, `skeleton_loader.dart`, `empty_state.dart`, `section_header.dart`, `confirm_sheet.dart`, `lib/core/router/transitions.dart`
- Modify: `lib/core/widgets/async_value_widget.dart`, `lib/router.dart`
- Test: `test/core/amount_text_test.dart`, `test/core/widgets_test.dart`

**Interfaces (later tasks rely on — exact):**
- `AmountText(amount, {String? type, bool signed = false, String? currency, TextStyle? style})` — formats via the existing `utils/number_format.dart` helper + currency suffix when given; applies `FontFeature.tabularFigures()`; when `type != null` colors via `amountColorFor` and, when `signed`, prefixes `−`/`+` for EXPENSE/INCOME.
- `HeroCard({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(20)})` — gradient `context.cuentiColors.heroGradient`, radius 20, white-ish foreground (`DefaultTextStyle`/`IconTheme` set to `Colors.white`).
- `StatChip({required IconData icon, required String label, required String value})`.
- `SkeletonLoader.list({int items = 6})`, `SkeletonLoader.card({double height = 160})`, `SkeletonLoader.tiles({int items = 3, double height = 72})` — shimmer via an `AnimatedBuilder` opacity pulse (no external package); pulse disabled when `MediaQuery.disableAnimationsOf(context)`.
- `EmptyState({required IconData icon, required String message, String? actionLabel, VoidCallback? onAction})`.
- `SectionHeader(String title, {Widget? trailing})`.
- `Future<bool> showConfirmSheet(BuildContext context, {required String title, String? message, String confirmLabel = 'Delete'})` — returns true on confirm; destructive button uses `colorScheme.error`.
- `AsyncValueWidget<T>` gains `skeleton` (Widget?) and `onRetry` (VoidCallback?): loading = `skeleton ?? loading ?? SkeletonLoader.list()`; error = card with message + Retry `FilledButton` when `onRetry != null`.
- `fadeThroughPage({required Widget child, required GoRouterState state})` in `transitions.dart` → `CustomTransitionPage` (fade + slight scale 0.98→1.0, 220ms, ease-out in / ease-in out; returns `NoTransitionPage`-equivalent when `MediaQuery.disableAnimations`). Router: every `GoRoute.builder` becomes `pageBuilder: (c, s) => fadeThroughPage(child: <Screen>(), state: s)` — shell route child routes included.

Test code (write first, RED, then implement):

```dart
// test/core/amount_text_test.dart
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/amount_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) =>
    MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child));

void main() {
  testWidgets('expense is colored and signed', (tester) async {
    await tester.pumpWidget(
        host(const AmountText(12.5, type: 'EXPENSE', signed: true)));
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, startsWith('−'));
    expect(text.style!.color, CuentiColors.light.expense);
    expect(text.style!.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  testWidgets('income signed plus, transfer neutral', (tester) async {
    await tester.pumpWidget(
        host(const AmountText(3, type: 'INCOME', signed: true)));
    expect(tester.widget<Text>(find.byType(Text)).data, startsWith('+'));
    await tester.pumpWidget(
        host(const AmountText(3, type: 'TRANSFER', signed: true)));
    expect(tester.widget<Text>(find.byType(Text)).style!.color,
        CuentiColors.light.transfer);
  });

  testWidgets('untyped amount uses ambient style color', (tester) async {
    await tester.pumpWidget(host(const AmountText(99)));
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, isNot(startsWith('−')));
  });
}
```

```dart
// test/core/widgets_test.dart (kit behaviors)
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) =>
    MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child));

void main() {
  testWidgets('EmptyState action fires', (tester) async {
    var tapped = false;
    await tester.pumpWidget(host(EmptyState(
      icon: Icons.inbox,
      message: 'Nothing here',
      actionLabel: 'Add',
      onAction: () => tapped = true,
    )));
    await tester.tap(find.text('Add'));
    expect(tapped, isTrue);
  });

  testWidgets('AsyncValueWidget loading shows skeleton', (tester) async {
    await tester.pumpWidget(host(const AsyncValueWidget<int>(
      value: AsyncLoading(),
      data: _dataText,
    )));
    expect(find.byType(SkeletonLoader), findsOneWidget);
    await tester.pumpWidget(host(Container())); // dispose pulse timer
  });

  testWidgets('AsyncValueWidget error shows retry and fires callback',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(host(AsyncValueWidget<int>(
      value: AsyncError(Exception('boom'), StackTrace.empty),
      data: _dataText,
      onRetry: () => retried = true,
    )));
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });
}

Widget _dataText(int v) => Text('$v');
```

Steps: write both test files → RED → implement all kit widgets + AsyncValueWidget upgrade + transitions.dart + router pageBuilder conversion → GREEN → full gates → commit `feat(ui-kit): amount text, hero card, skeletons, empty states, confirm sheet, page transitions`.

---

### Task 3: Server-side transaction filters (data layer)

**Files:**
- Create: `lib/features/transactions/domain/transaction_filter.dart`
- Modify: `lib/features/transactions/data/transactions_repository.dart`, `lib/features/transactions/ui/transactions_controller.dart` (family key change + all `transactionsControllerProvider(...)` call sites: transactions screen, transaction dialog, shell refresh, scheduled controller invalidation — the family-target invalidations need no change)
- Test: update `test/features/transactions/transactions_repository_test.dart`, `transactions_controller_test.dart`, `scheduled_controller_test.dart` (call-site signature)

**Interfaces:**

```dart
// transaction_filter.dart  (freezed; equality is what keys the provider family)
@freezed
abstract class TransactionFilter with _$TransactionFilter {
  const factory TransactionFilter({
    int? accountId,
    String? type,       // EXPENSE | INCOME | TRANSFER
    int? categoryId,
    DateTime? start,    // date-only; sent as yyyy-MM-dd
    DateTime? end,
    String? search,
  }) = _TransactionFilter;
}
```

Repository:

```dart
Future<TransactionPage> getPage({
  TransactionFilter filter = const TransactionFilter(),
  int page = 0,
  int size = 50,
}) => _guard(() async {
      final df = DateFormat('yyyy-MM-dd');
      final res = await _dio.get<Map<String, dynamic>>('/transactions',
          queryParameters: {
            if (filter.accountId != null) 'accountId': filter.accountId,
            if (filter.type != null) 'type': filter.type,
            if (filter.categoryId != null) 'categoryId': filter.categoryId,
            if (filter.start != null) 'start': df.format(filter.start!),
            if (filter.end != null) 'end': df.format(filter.end!),
            if (filter.search != null && filter.search!.isNotEmpty)
              'search': filter.search,
            'page': page,
            'size': size,
          });
      return TransactionPage.fromJson(res.data!);
    });
```

Controller: `build({TransactionFilter filter = const TransactionFilter()})`; `TransactionsState.accountId` field replaced by `TransactionFilter filter`; `loadMore`/`save`/`delete` unchanged in logic (pass `filter:` through). Call sites: screen passes its filter object; dialog + others that used `transactionsControllerProvider(accountId: X)` become `transactionsControllerProvider(filter: TransactionFilter(accountId: X))`.

Tests: repository capture asserts each param serialized (`start: '2026-02-01'` etc.) and omitted when null; controller tests updated to the new family signature; add one test `filter change creates distinct family instance` (read two providers with different filters → repo getPage called with each filter).

Steps: RED (update repo test with new expectations) → implement → GREEN → all call sites compile → full gates → commit `feat(transactions): server-side filter object drives paged queries`.

---

### Task 4: Transactions screen — sticky day groups, swipe actions, filter bar, tile redesign

**Files:**
- Modify: `lib/features/transactions/ui/transactions_screen.dart` (substantial rewrite of list area; state fields for filter)
- Test: update `test/features/transactions/transactions_screen_test.dart` (+ new cases)

**Behavior spec:**
- Local state: `TransactionFilter _filter` (starts empty). Debounced search `TextField` (350ms `Timer`, cancel-on-change) updates `_filter.copyWith(search: ...)`. Filter chips row (horizontal scroll): type chip (choice sheet EXPENSE/INCOME/TRANSFER/All), category chip (list sheet from `categoriesControllerProvider`), date-range chip (`showDateRangePicker`), account chip (existing dropdown becomes a chip). Active chips show the selection + clear (×). All old client-side search filtering DELETED.
- Watch `ref.watch(transactionsControllerProvider(filter: _filter))`.
- Grouping: replace month `_ListItem` flattening with day groups rendered in a `CustomScrollView`: for each day (descending) a `SliverMainAxisGroup` with a pinned `SliverPersistentHeader` (day label: `Today` / `Yesterday` / `EEE, d MMM yyyy`) + `SliverList` of tiles. Load-more sentinel + `loadingMore` progress row stay (as trailing sliver). Keep existing ScrollController trigger.
- Tile: leading `CircleAvatar`-style category glyph (`Icons.category`-family mapping: pick icon by type — `arrow_upward`/`arrow_downward`/`swap_horiz` — inside a tinted circle using `amountColorFor` at 12% alpha), title payee (fallback category/memo), subtitle memo·account, trailing `AmountText(t.amount, type: t.type, signed: true)`.
- Swipe: keep `Dismissible`; `direction: DismissDirection.horizontal`; background (startToEnd) = edit affordance (blue-gray container, edit icon+label), secondaryBackground (endToStart) = delete (error color container, delete icon+label). `confirmDismiss`: endToStart → `showConfirmSheet(...)`, on confirm call delete (existing logic) and return true; startToEnd → open the edit sheet and return false (row stays).
- Empty filter result → `EmptyState(icon: Icons.receipt_long, message: 'No transactions match', actionLabel: 'Clear filters', onAction: reset)`; loading → `SkeletonLoader.list()` via AsyncValueWidget.
- Entrance stagger: first build only, wrap tiles in a small `_Staggered` helper (opacity+slide 250ms, 35ms/index, index capped at 12) — skipped entirely when `MediaQuery.disableAnimationsOf(context)`.

Tests to update/add (keep existing pagination test working with new tree): pumping with repo override returning 2 tx on different days → expect two day headers; search field debounce → verify repo called with `search` param after `tester.pump(Duration(milliseconds: 400))`; swipe endToStart on a tile → confirm sheet appears; empty result shows EmptyState.

Steps: update tests RED → rewrite screen → GREEN → gates → commit `feat(transactions-ui): sticky day groups, swipe actions, server filter bar, redesigned tiles`.

---

### Task 5: Dashboard restyle

**Files:**
- Modify: `lib/features/dashboard/ui/dashboard_screen.dart`
- Test: `test/features/dashboard/dashboard_screen_test.dart` (new, light)

**Behavior spec:** `ListView` becomes: (1) `HeroCard` — "Net worth" label, `AmountText(netWorth, style: displaySmall w800)` (white, tabular), row of two `StatChip`s (wallet icon + 'Cash' + formatted availableCash; trending icon + 'Portfolio' + portfolioValue) — chips rendered white-on-translucent inside the hero; (2) `SectionHeader('Accounts')` + horizontal `SizedBox(height:120)` `ListView` of account cards (Card, account name, type label small, `AmountText(balance)`; width 160); (3) `SectionHeader('Assets')` + existing asset tiles restyled: trailing `AmountText(currentValue)` + gain/loss line in `income`/`expense` color with ▲/▼ prefix (percent, tabular). Loading = `SkeletonLoader.card()` + `SkeletonLoader.tiles()`; error retry via AsyncValueWidget `onRetry: () => ref.invalidate(dashboardProvider)`. Old `_MetricCard` deleted.

Test: pump with `dashboardRepositoryProvider` override (one account, one assetPerformance, netWorth 1500) → finds 'Net worth', formatted amount text, account name, EmptyState absent; loading state shows SkeletonLoader.

Steps: test RED → restyle → GREEN → gates → commit `feat(dashboard): hero net-worth card, account carousel, asset performance restyle`.

---

### Task 6: Transaction dialog + sheet polish

**Files:**
- Modify: `lib/features/transactions/ui/transaction_dialog.dart`
- Test: update `test/features/transactions/transaction_dialog_test.dart`

**Behavior spec:** type dropdown → `SegmentedButton<String>` (three segments, icons + labels, selected color = `amountColorFor` at 15% alpha container); amount field first, `textAlign: center`, `headlineMedium` style with tabular figures, `TextInputType.numberWithOptions(decimal: true)`; remaining fields unchanged in order/semantics; save button full-width `FilledButton` with `_submitting` spinner; sheet content wrapped in `SafeArea` + consistent 20px padding. Save payload code untouched (assert via existing dialog test still passing). Update dialog test: type selection now taps segment (`find.text('Expense')` inside SegmentedButton) — adjust finders.

Steps: adjust tests RED where finders break → restyle → GREEN → gates → commit `feat(transactions-ui): segmented type selector and amount-first dialog`.

---

### Task 7: Screen sweep — accounts, auth, shell

**Files:**
- Modify: `lib/features/accounts/ui/accounts_screen.dart`, `lib/features/auth/ui/{login,register,server_setup}_screen.dart`, `lib/screens/shell_screen.dart`
- Test: update `test/features/auth/login_screen_test.dart` if finders break

**Behavior spec:**
- Accounts: tiles → Cards with type icon in tinted circle, `AmountText(balance)` trailing (no type coloring — plain onSurface), group label chip when `accountGroup` set; loading `SkeletonLoader.tiles()`; `EmptyState(icon: Icons.account_balance_wallet, message: 'No accounts yet', actionLabel: 'Add account', onAction: openAddSheet)`; reorder + dialogs functionally unchanged; delete confirm switches to `showConfirmSheet`.
- Auth screens: logo + `HeroCard`-free clean layout — centered column, app icon, `headlineMedium` title, fields with the themed InputDecoration, full-width `FilledButton`, error text in `colorScheme.error`. Structure/flow unchanged (fields, buttons, links).
- Shell: `NavigationBar` uses themed colors automatically (verify); AppBar title `titleLarge` w700; refresh button unchanged.

Steps: restyle → run full suite (fix broken finders) → gates → commit `feat(ui): accounts, auth, shell restyle`.

---

### Task 8: Screen sweep — categories, payees, tags, currencies, assets, scheduled, settings

**Files:**
- Modify: the seven `lib/features/*/ui/*_screen.dart` files
- Test: existing suite green (no new tests; these screens have no widget tests)

**Behavior spec (uniform, per screen):**
- Loading → `SkeletonLoader.tiles()` via AsyncValueWidget `skeleton:`; error → `onRetry: () => ref.invalidate(<provider>)`; empty → `EmptyState` with per-domain icon/message/add-action (categories `Icons.category` 'No categories yet'; payees `Icons.storefront`; tags `Icons.sell`; currencies `Icons.currency_exchange`; assets `Icons.show_chart`; scheduled `Icons.schedule`).
- Delete confirmations → `showConfirmSheet`.
- Tiles → Cards consistent with accounts pattern; scheduled tile shows next-occurrence chip + enabled switch as today, amount via `AmountText(type:)`; assets tile shows price + refresh icon-button (spinner while awaiting) as today.
- Settings: section headers via `SectionHeader`; rows unchanged apart from the (already removed) color picker; About row stays.
- No functional changes; all saves/payloads untouched.

Steps: restyle seven screens → full gates → commit `feat(ui): catalog, portfolio, scheduled, settings restyle`.

---

### Task 9: Statistics charts restyle

**Files:**
- Modify: `lib/features/statistics/ui/statistics_screen.dart`
- Test: existing suite green

**Behavior spec:** colors from `context.cuentiColors.chartPalette` (replace any scheme-derived/hardcoded chart colors); line/area charts: `isCurved: true, curveSmoothness: 0.35`, gradient fill `belowBarData` (palette color → transparent), no dots except touched; bar charts: `borderRadius: BorderRadius.circular(6)`, width 14; enable `LineTouchData`/`BarTouchData` tooltips (default fl_chart tooltip, background `surfaceContainerHighest`, labels via `AmountText`-equivalent formatting util); grid lines `outlineVariant` at 50% alpha, no vertical grid; legends → `Wrap` of chips (color dot + category label) replacing any built-in legend; income/expense summary numbers → `AmountText`. Category pie/donut (if present) keeps ≤6 slices + 'Other' aggregation if more — check existing behavior first and preserve aggregation logic. Range/account pickers restyled as chips consistent with Task 4's bar.

Steps: restyle → gates → commit `feat(statistics): chart restyle with brand palette, tooltips, legend chips`.

---

### Task 10: Final gate + smoke addendum

- [ ] Full: `flutter analyze --no-fatal-infos` exit 0, `flutter test` all green, `flutter build apk --debug`.
- [ ] Grep gates: `grep -rn "Color(0x" lib/features lib/screens --include=*.dart` → ZERO hits (raw hex only allowed in `lib/core/theme/`); `grep -rn "CircularProgressIndicator" lib/features --include=*.dart` → only inline button spinners (list-loading spinners should be skeletons); record both outputs.
- [ ] Update `docs/superpowers/plans/2026-07-12-mobile-rearchitect-SMOKE.md`: remove the "search filters only loaded pages" quirk (now server-side); append a short Phase 3 visual checklist (dark+light theme sanity per screen, swipe actions, filter chips, chart tooltips, reduced-motion setting disables transitions).
- [ ] Commit stragglers: `docs: phase 3 smoke updates`.
