import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/categories_screen.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
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
}
