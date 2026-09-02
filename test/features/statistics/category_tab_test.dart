import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/category_tab.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

const _categories = [
  Category(id: 1, name: 'Food'),
  Category(id: 2, name: 'Groceries', parentId: 1),
  Category(id: 3, name: 'Organic', parentId: 2),
  Category(id: 4, name: 'Transport'),
  Category(id: 5, name: 'Fuel', parentId: 4),
];

void main() {
  late MockCategoriesRepository categoriesRepo;

  setUp(() {
    categoriesRepo = MockCategoriesRepository();
    when(() => categoriesRepo.getAll()).thenAnswer((_) async => _categories);
  });

  Future<void> pumpTab(
    WidgetTester tester, {
    Map<String, double> data = const {
      'Groceries': 300,
      'Organic': 100,
      'Fuel': 50,
    },
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: Scaffold(
            body: CategoryTab(
              data: data,
              title: 'Expense by Category',
              currency: 'EUR',
              type: 'EXPENSE',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The row for [name] in the breakdown list below the chart. Keyed
  /// rather than matched by text, since the chip legend repeats the name.
  Finder row(String name) => find.byKey(ValueKey('category-row-$name'));

  testWidgets('opens on the top-level categories, not on every leaf', (
    tester,
  ) async {
    await pumpTab(tester);

    expect(row('Food'), findsOneWidget);
    expect(row('Transport'), findsOneWidget);
    expect(
      row('Groceries'),
      findsNothing,
      reason: 'Groceries sits under Food and belongs one level down',
    );
  });

  testWidgets('a parent totals what its whole subtree holds', (tester) async {
    await pumpTab(tester);

    expect(find.textContaining('400,00'), findsOneWidget);
  });

  testWidgets('tapping a parent drills into its children', (tester) async {
    await pumpTab(tester);
    await tester.tap(row('Food'));
    await tester.pumpAndSettle();

    expect(row('Groceries'), findsOneWidget);
    expect(
      row('Transport'),
      findsNothing,
      reason: 'the level shows what is inside Food, not its siblings',
    );
  });

  testWidgets('drilling goes as deep as the tree does', (tester) async {
    await pumpTab(tester);
    await tester.tap(row('Food'));
    await tester.pumpAndSettle();
    await tester.tap(row('Groceries'));
    await tester.pumpAndSettle();

    expect(row('Organic'), findsOneWidget);
  });

  testWidgets('the breadcrumb names the path and walks back up', (
    tester,
  ) async {
    await pumpTab(tester);
    await tester.tap(row('Food'));
    await tester.pumpAndSettle();

    expect(find.text('All categories'), findsOneWidget);
    expect(find.text('Food'), findsWidgets);

    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();

    expect(row('Transport'), findsOneWidget);
  });

  testWidgets('the back gesture climbs one level instead of leaving the '
      'screen', (tester) async {
    await pumpTab(tester);
    await tester.tap(row('Food'));
    await tester.pumpAndSettle();

    final popped = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(popped, isTrue, reason: 'the tab consumed the pop');
    expect(row('Transport'), findsOneWidget);
  });

  testWidgets('a leaf category cannot be drilled into', (tester) async {
    await pumpTab(tester);
    await tester.tap(row('Transport'));
    await tester.pumpAndSettle();

    expect(row('Fuel'), findsOneWidget);
    await tester.tap(row('Fuel'));
    await tester.pumpAndSettle();

    expect(
      row('Fuel'),
      findsOneWidget,
      reason: 'tapping a leaf leaves the level where it was',
    );
  });

  testWidgets('money booked on the parent itself is not lost when drilling '
      'in: it appears as its own entry', (tester) async {
    await pumpTab(
      tester,
      data: const {'Food': 40, 'Groceries': 60},
    );
    await tester.tap(row('Food'));
    await tester.pumpAndSettle();

    expect(row('Food (direct)'), findsOneWidget);
    expect(row('Groceries'), findsOneWidget);
    expect(
      find.textContaining('40,00'),
      findsWidgets,
      reason: 'the 40 booked on Food itself is still on screen',
    );
  });

  testWidgets('falls back to a flat list while the categories are still '
      'loading, rather than an empty chart', (tester) async {
    when(() => categoriesRepo.getAll()).thenThrow(Exception('offline'));

    await pumpTab(tester);

    expect(row('Groceries'), findsOneWidget);
    expect(row('Fuel'), findsOneWidget);
  });

  testWidgets('the breadcrumb is translated', (tester) async {
    await pumpTab(tester, locale: const Locale('de'));
    await tester.tap(row('Food'));
    await tester.pumpAndSettle();

    expect(find.text('Alle Kategorien'), findsOneWidget);
  });
}
