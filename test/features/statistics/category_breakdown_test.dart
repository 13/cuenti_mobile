import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/statistics/domain/category_breakdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// A three-level expense tree: Food > Groceries > Organic, plus Transport >
/// Fuel. Ids matter, names are what the statistics endpoint sends back.
const _categories = [
  Category(id: 1, name: 'Food'),
  Category(id: 2, name: 'Groceries', parentId: 1),
  Category(id: 3, name: 'Organic', parentId: 2),
  Category(id: 4, name: 'Transport'),
  Category(id: 5, name: 'Fuel', parentId: 4),
  Category(id: 6, name: 'Salary', type: 'INCOME'),
];

List<CategoryNode> build(Map<String, double> amounts) =>
    buildCategoryBreakdown(amounts, _categories, type: 'EXPENSE');

CategoryNode named(List<CategoryNode> nodes, String name) =>
    nodes.firstWhere((n) => n.name == name);

void main() {
  test('a leaf amount rolls up to its top-level ancestor', () {
    final roots = build({'Groceries': 100});

    expect(roots.map((n) => n.name), ['Food']);
    expect(named(roots, 'Food').total, 100);
  });

  test('a root totals everything beneath it, however deep', () {
    final roots = build({'Organic': 30, 'Groceries': 70});

    expect(named(roots, 'Food').total, 100);
  });

  test('drilling down reaches each level in turn', () {
    final food = named(build({'Organic': 30, 'Groceries': 70}), 'Food');
    final groceries = named(food.children, 'Groceries');

    expect(groceries.total, 100);
    expect(named(groceries.children, 'Organic').total, 30);
  });

  test('a parent keeps its own spending as well as its children', () {
    final food = named(build({'Food': 40, 'Groceries': 60}), 'Food');

    expect(food.ownAmount, 40);
    expect(food.total, 100);
  });

  test('every level accounts for its own total: children plus own amount '
      'always add back up, so drilling down never loses money', () {
    final roots = build({'Food': 40, 'Groceries': 60, 'Organic': 25});
    for (final node in [...roots, ...roots.expand((n) => n.children)]) {
      final fromChildren = node.children.fold<double>(
        0,
        (sum, c) => sum + c.total,
      );
      expect(node.total, closeTo(node.ownAmount + fromChildren, 0.0001));
    }
  });

  test('a category with no amount anywhere in its subtree is left out '
      'rather than shown as an empty slice', () {
    final roots = build({'Fuel': 50});

    expect(roots.map((n) => n.name), ['Transport']);
  });

  test('a name the categories do not know stays a top-level entry, which is '
      'how it renders today -- the amount is real either way', () {
    final roots = build({'Groceries': 100, 'Mystery': 25});

    expect(named(roots, 'Mystery').total, 25);
    expect(named(roots, 'Mystery').children, isEmpty);
    expect(named(roots, 'Mystery').id, isNull);
  });

  test('a name belonging to two different parents is not guessed at: it '
      'stays top-level rather than being filed under the wrong one', () {
    const ambiguous = [
      Category(id: 1, name: 'Food'),
      Category(id: 2, name: 'Fuel', parentId: 1),
      Category(id: 3, name: 'Transport'),
      Category(id: 4, name: 'Fuel', parentId: 3),
    ];

    final roots = buildCategoryBreakdown(
      {
        'Fuel': 80,
      },
      ambiguous,
      type: 'EXPENSE',
    );

    expect(roots.map((n) => n.name), ['Fuel']);
    expect(named(roots, 'Fuel').total, 80);
  });

  test('categories of the other type cannot capture an amount', () {
    final roots = buildCategoryBreakdown(
      {
        'Salary': 3200,
      },
      _categories,
      type: 'INCOME',
    );

    expect(named(roots, 'Salary').total, 3200);
    expect(named(roots, 'Salary').id, 6);
  });

  test('no categories at all still yields the flat list, so the chart works '
      'while the category list is loading or unavailable', () {
    final roots = buildCategoryBreakdown(
      {
        'Food': 30,
        'Transport': 10,
      },
      const [],
      type: 'EXPENSE',
    );

    expect(roots.map((n) => n.name), ['Food', 'Transport']);
    expect(roots.every((n) => n.children.isEmpty), isTrue);
  });

  test('roots come back largest first, as the chart draws them', () {
    final roots = build({'Fuel': 500, 'Groceries': 100});

    expect(roots.map((n) => n.name), ['Transport', 'Food']);
  });

  test('children are sorted largest first too', () {
    const deep = [
      Category(id: 1, name: 'Food'),
      Category(id: 2, name: 'Groceries', parentId: 1),
      Category(id: 3, name: 'Dining', parentId: 1),
    ];

    final food = named(
      buildCategoryBreakdown(
        {
          'Groceries': 10,
          'Dining': 90,
        },
        deep,
        type: 'EXPENSE',
      ),
      'Food',
    );

    expect(food.children.map((n) => n.name), ['Dining', 'Groceries']);
  });

  test('a cycle in the parent links does not hang the build', () {
    const cyclic = [
      Category(id: 1, name: 'A', parentId: 2),
      Category(id: 2, name: 'B', parentId: 1),
    ];

    final roots = buildCategoryBreakdown(
      {
        'A': 10,
      },
      cyclic,
      type: 'EXPENSE',
    );

    expect(roots.fold<double>(0, (s, n) => s + n.total), 10);
  });
}
