import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _categories = [
  Category(
    id: 1,
    name: 'Groceries',
    fullName: 'Food:Groceries',
    type: 'EXPENSE',
  ),
  Category(
    id: 2,
    name: 'Organic',
    fullName: 'Food:Groceries:Organic',
    type: 'EXPENSE',
  ),
  Category(
    id: 3,
    name: 'Grocery delivery',
    fullName: 'Home:Grocery delivery',
    type: 'EXPENSE',
  ),
  Category(id: 4, name: 'Fuel', fullName: 'Transport:Fuel', type: 'EXPENSE'),
];

/// Finds text inside the open picker sheet only, ignoring the field
/// underneath that shows the same label for the current selection.
Finder inSheet(String text) =>
    find.descendant(of: find.byType(CategorySearchSheet), matching: find.text(text));

void main() {
  /// Pumps a [CategoryPickerField] wired to local state and returns the
  /// list that records every value the field reports.
  Future<List<int?>> pumpPicker(
    WidgetTester tester, {
    List<Category> categories = _categories,
    int? selectedId,
    bool allowNone = true,
  }) async {
    final changes = <int?>[];
    var current = selectedId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => CategoryPickerField(
              categories: categories,
              selectedId: current,
              allowNone: allowNone,
              onChanged: (value) => setState(() {
                changes.add(value);
                current = value;
              }),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return changes;
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byType(CategoryPickerField));
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();
  }

  group('filterCategories', () {
    test('matches case-insensitively on the full path', () {
      final result = filterCategories(_categories, 'GROC');
      expect(result.map((c) => c.id), [1, 2, 3]);
    });

    test('requires every whitespace-separated token to match', () {
      final result = filterCategories(_categories, 'food groc');
      expect(result.map((c) => c.id), [1, 2]);
    });

    test('falls back to name when fullName is missing', () {
      const flat = [Category(id: 9, name: 'Tanken', type: 'EXPENSE')];
      expect(filterCategories(flat, 'tank').map((c) => c.id), [9]);
    });

    test('returns everything for a blank query', () {
      expect(filterCategories(_categories, '   ').length, _categories.length);
    });
  });

  testWidgets('field shows the selected category path', (tester) async {
    await pumpPicker(tester, selectedId: 2);

    expect(find.text('Food:Groceries:Organic'), findsOneWidget);
  });

  testWidgets('field shows the placeholder when nothing is selected', (
    tester,
  ) async {
    await pumpPicker(tester);

    expect(find.text('None'), findsOneWidget);
  });

  testWidgets('field shows the placeholder when the selected id is unknown', (
    tester,
  ) async {
    await pumpPicker(tester, selectedId: 999);

    expect(find.text('None'), findsOneWidget);
  });

  testWidgets('tapping the field opens a sheet listing every category', (
    tester,
  ) async {
    await pumpPicker(tester);
    await openSheet(tester);

    expect(inSheet('Food:Groceries'), findsOneWidget);
    expect(inSheet('Food:Groceries:Organic'), findsOneWidget);
    expect(inSheet('Home:Grocery delivery'), findsOneWidget);
    expect(inSheet('Transport:Fuel'), findsOneWidget);
  });

  testWidgets('typing filters the list', (tester) async {
    await pumpPicker(tester);
    await openSheet(tester);
    await search(tester, 'food groc');

    expect(inSheet('Food:Groceries'), findsOneWidget);
    expect(inSheet('Food:Groceries:Organic'), findsOneWidget);
    expect(inSheet('Home:Grocery delivery'), findsNothing);
    expect(inSheet('Transport:Fuel'), findsNothing);
  });

  testWidgets('a query matching nothing shows an empty-state message', (
    tester,
  ) async {
    await pumpPicker(tester);
    await openSheet(tester);
    await search(tester, 'zzz');

    expect(inSheet('No matching categories'), findsOneWidget);
  });

  testWidgets('the clear button restores the full list', (tester) async {
    await pumpPicker(tester);
    await openSheet(tester);
    await search(tester, 'zzz');

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(inSheet('Transport:Fuel'), findsOneWidget);
  });

  testWidgets('picking a result reports its id and closes the sheet', (
    tester,
  ) async {
    final changes = await pumpPicker(tester);
    await openSheet(tester);
    await search(tester, 'organic');
    await tester.tap(inSheet('Food:Groceries:Organic'));
    await tester.pumpAndSettle();

    expect(changes, [2]);
    expect(find.byType(CategorySearchSheet), findsNothing);
    expect(find.text('Food:Groceries:Organic'), findsOneWidget);
  });

  testWidgets('picking None reports a null id', (tester) async {
    final changes = await pumpPicker(tester, selectedId: 1);
    await openSheet(tester);
    await tester.tap(inSheet('None'));
    await tester.pumpAndSettle();

    expect(changes, [null]);
  });

  testWidgets('None stays reachable while a query is filtering', (
    tester,
  ) async {
    await pumpPicker(tester, selectedId: 1);
    await openSheet(tester);
    await search(tester, 'zzz');

    expect(inSheet('None'), findsOneWidget);
  });

  testWidgets('None is absent when the field does not allow it', (
    tester,
  ) async {
    await pumpPicker(tester, selectedId: 1, allowNone: false);
    await openSheet(tester);

    expect(inSheet('None'), findsNothing);
  });

  testWidgets('a long list still fits above an open keyboard', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    addTearDown(tester.view.reset);

    await pumpPicker(
      tester,
      categories: [
        for (var i = 0; i < 60; i++)
          Category(id: i + 1, name: 'Category $i', type: 'EXPENSE'),
      ],
    );
    await openSheet(tester);

    // The keyboard covers the bottom 400 of the 800-tall screen, so every
    // part of the sheet has to sit above that line to stay usable.
    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomLeft(find.byType(ListView)).dy,
      lessThanOrEqualTo(400.0),
    );
    expect(
      tester.getBottomLeft(find.byType(TextField)).dy,
      lessThanOrEqualTo(400.0),
    );
  });

  testWidgets('dismissing the sheet leaves the selection untouched', (
    tester,
  ) async {
    final changes = await pumpPicker(tester, selectedId: 1);
    await openSheet(tester);
    Navigator.of(tester.element(find.byType(CategorySearchSheet))).pop();
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(find.text('Food:Groceries'), findsOneWidget);
  });
}
