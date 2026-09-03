import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/categories_screen.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

const _tree = [
  Category(id: 1, name: 'Food'),
  Category(id: 2, name: 'Groceries', parentId: 1),
  Category(id: 3, name: 'Salary', type: 'INCOME'),
];

void main() {
  late MockCategoriesRepository repo;

  setUp(() {
    repo = MockCategoriesRepository();
    when(
      () => repo.getAll(type: any(named: 'type')),
    ).thenAnswer((_) async => _tree);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [categoriesRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: const CategoriesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists top-level categories and hides children until expanded', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Groceries'), findsNothing);
  });

  testWidgets('expanding a parent reveals its children', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsOneWidget);
  });

  testWidgets('offers to add one when there are none', (tester) async {
    when(
      () => repo.getAll(type: any(named: 'type')),
    ).thenAnswer((_) async => []);

    await pumpScreen(tester);

    expect(find.text('No categories yet'), findsOneWidget);
  });

  testWidgets('deleting asks first and cancelling keeps the category', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.delete).first);
    await tester.pumpAndSettle();

    expect(find.text('Delete Category?'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.delete(any()));
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets('the add sheet offers a searchable parent picker', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Add Category'), findsOneWidget);
    expect(find.byType(CategoryPickerField), findsOneWidget);
    expect(find.text('None (Top Level)'), findsOneWidget);
  });

  testWidgets('the parent picker lists only top-level categories', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CategoryPickerField));
    await tester.pumpAndSettle();

    Finder inSheet(String text) => find.descendant(
      of: find.byType(CategorySearchSheet),
      matching: find.text(text),
    );
    expect(inSheet('Food'), findsOneWidget);
    expect(inSheet('Salary'), findsOneWidget);
    expect(
      inSheet('Groceries'),
      findsNothing,
      reason: 'a child cannot itself be a parent',
    );
  });

  group('search and sort', () {
    const bigger = [
      Category(id: 1, name: 'Food', fullName: 'Food'),
      Category(
        id: 2,
        name: 'Groceries',
        fullName: 'Food:Groceries',
        parentId: 1,
      ),
      Category(
        id: 5,
        name: 'Restaurants',
        fullName: 'Food:Restaurants',
        parentId: 1,
      ),
      Category(id: 3, name: 'Salary', fullName: 'Salary', type: 'INCOME'),
      Category(id: 4, name: 'Auto', fullName: 'Auto'),
    ];

    double rowY(WidgetTester tester, String text) =>
        tester.getTopLeft(find.text(text)).dy;

    Future<void> pumpBigger(WidgetTester tester) async {
      when(
        () => repo.getAll(type: any(named: 'type')),
      ).thenAnswer((_) async => bigger);
      await pumpScreen(tester);
    }

    testWidgets('searching a parent keeps it', (tester) async {
      await pumpBigger(tester);

      await tester.enterText(find.byType(TextField).first, 'auto');
      await tester.pumpAndSettle();

      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Salary'), findsNothing);
    });

    testWidgets(
      'searching a child keeps its parent and shows the child, which is '
      'otherwise collapsed out of sight',
      (tester) async {
        await pumpBigger(tester);

        await tester.enterText(find.byType(TextField).first, 'groceries');
        await tester.pumpAndSettle();

        expect(find.text('Food'), findsOneWidget);
        expect(find.text('Groceries'), findsOneWidget);
        expect(find.text('Auto'), findsNothing);
      },
    );

    testWidgets('a child that does not match stays out of the results', (
      tester,
    ) async {
      await pumpBigger(tester);

      await tester.enterText(find.byType(TextField).first, 'groceries');
      await tester.pumpAndSettle();

      expect(find.text('Restaurants'), findsNothing);
    });

    testWidgets('matching the parent brings all of its children along', (
      tester,
    ) async {
      await pumpBigger(tester);

      await tester.enterText(find.byType(TextField).first, 'food');
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Restaurants'), findsOneWidget);
    });

    testWidgets('the full path is searchable, so "food groc" finds it', (
      tester,
    ) async {
      await pumpBigger(tester);

      await tester.enterText(find.byType(TextField).first, 'food groc');
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Salary'), findsNothing);
    });

    testWidgets('a search matching nothing offers to clear it', (tester) async {
      await pumpBigger(tester);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No categories match'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('Salary'), findsOneWidget);
    });

    testWidgets('the name chip sorts the top level A to Z', (tester) async {
      await pumpBigger(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Name'));
      await tester.pumpAndSettle();

      expect(rowY(tester, 'Auto'), lessThan(rowY(tester, 'Food')));
      expect(rowY(tester, 'Food'), lessThan(rowY(tester, 'Salary')));
    });

    testWidgets('the type chip puts the income categories together', (
      tester,
    ) async {
      await pumpBigger(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Type'));
      await tester.pumpAndSettle();

      // EXPENSE sorts before INCOME, so Salary lands last.
      expect(rowY(tester, 'Food'), lessThan(rowY(tester, 'Salary')));
      expect(rowY(tester, 'Auto'), lessThan(rowY(tester, 'Salary')));
    });
  });

  testWidgets('names a category type in words, not as the wire constant', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Expense'), findsWidgets);
    expect(find.text('EXPENSE'), findsNothing);
  });

  group('nothing is hidden from the management screen', () {
    testWidgets(
      'a category nested deeper than the screen draws still shows up, '
      'rather than being invisible and so uneditable',
      (tester) async {
        when(() => repo.getAll(type: any(named: 'type'))).thenAnswer(
          (_) async => const [
            Category(id: 1, name: 'Food', fullName: 'Food'),
            Category(
              id: 2,
              name: 'Groceries',
              fullName: 'Food:Groceries',
              parentId: 1,
            ),
            Category(
              id: 6,
              name: 'Organic',
              fullName: 'Food:Groceries:Organic',
              parentId: 2,
            ),
          ],
        );

        await pumpScreen(tester);

        expect(find.text('Organic'), findsOneWidget);
      },
    );

    testWidgets('a category whose parent is missing from the response is '
        'still reachable', (tester) async {
      when(() => repo.getAll(type: any(named: 'type'))).thenAnswer(
        (_) async => const [
          Category(id: 1, name: 'Food', fullName: 'Food'),
          Category(id: 7, name: 'Ghost', fullName: 'Gone:Ghost', parentId: 99),
        ],
      );

      await pumpScreen(tester);

      expect(find.text('Ghost'), findsOneWidget);
    });

    testWidgets('a promoted category is not also drawn under a parent', (
      tester,
    ) async {
      when(() => repo.getAll(type: any(named: 'type'))).thenAnswer(
        (_) async => const [
          Category(id: 1, name: 'Food', fullName: 'Food'),
          Category(
            id: 2,
            name: 'Groceries',
            fullName: 'Food:Groceries',
            parentId: 1,
          ),
          Category(
            id: 6,
            name: 'Organic',
            fullName: 'Food:Groceries:Organic',
            parentId: 2,
          ),
        ],
      );

      await pumpScreen(tester);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      expect(find.text('Organic'), findsOneWidget);
    });

    testWidgets('a deep category can still be searched for', (tester) async {
      when(() => repo.getAll(type: any(named: 'type'))).thenAnswer(
        (_) async => const [
          Category(id: 1, name: 'Food', fullName: 'Food'),
          Category(
            id: 6,
            name: 'Organic',
            fullName: 'Food:Groceries:Organic',
            parentId: 2,
          ),
        ],
      );

      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField).first, 'organic');
      await tester.pumpAndSettle();

      expect(find.text('Organic'), findsOneWidget);
      expect(find.text('Food'), findsNothing);
    });
  });
}
