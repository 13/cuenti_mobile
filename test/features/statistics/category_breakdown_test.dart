import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/statistics/domain/category_breakdown.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/real_fixture.dart';

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

  group('joining against whatever the server actually sends', () {
    test('a server that reports types in lower case still builds the tree, '
        'rather than matching nothing and flattening everything', () {
      const lowercase = [
        Category(id: 1, name: 'Food', type: 'expense'),
        Category(id: 2, name: 'Groceries', parentId: 1, type: 'expense'),
      ];

      final roots = buildCategoryBreakdown(
        {
          'Groceries': 100,
        },
        lowercase,
        type: 'EXPENSE',
      );

      expect(roots.map((n) => n.name), ['Food']);
      expect(named(roots, 'Food').children.single.name, 'Groceries');
    });

    test('a mixed-case type is matched too', () {
      const mixed = [
        Category(id: 1, name: 'Salary', type: 'Income'),
      ];

      final roots = buildCategoryBreakdown(
        {
          'Salary': 3200,
        },
        mixed,
        type: 'INCOME',
      );

      expect(named(roots, 'Salary').id, 1);
    });

    test('a category name that differs only by case or padding still '
        'matches the amount reported for it', () {
      const padded = [
        Category(id: 1, name: 'Food'),
        Category(id: 2, name: ' groceries ', parentId: 1),
      ];

      final roots = buildCategoryBreakdown(
        {
          'Groceries': 100,
        },
        padded,
        type: 'EXPENSE',
      );

      expect(named(roots, 'Food').total, 100);
    });

    test('two categories whose names differ only by case are still treated '
        'as ambiguous, not silently merged into one', () {
      const clashing = [
        Category(id: 1, name: 'Fuel'),
        Category(id: 2, name: 'FUEL'),
      ];

      final roots = buildCategoryBreakdown(
        {
          'fuel': 80,
        },
        clashing,
        type: 'EXPENSE',
      );

      expect(roots.single.name, 'fuel');
      expect(roots.single.id, isNull);
      expect(roots.single.total, 80);
    });

    test('the type still separates income from expense', () {
      final roots = buildCategoryBreakdown(
        {
          'Salary': 3200,
        },
        _categories,
        type: 'EXPENSE',
      );

      expect(
        named(roots, 'Salary').id,
        isNull,
        reason: 'Salary is an income category and cannot claim expense',
      );
    });
  });

  group('the names the real backend sends', () {
    // Captured from this backend in test/fixtures/real_tx_envelope.json,
    // whose categoryName values are 'Einkommen:Gehalt' and 'Wohnen:Miete'.
    // The statistics endpoint keys its amounts the same way, so the join
    // has to cope with a full path and not only a bare leaf name.
    const categories = [
      Category(id: 1, name: 'Wohnen', fullName: 'Wohnen'),
      Category(id: 2, name: 'Miete', fullName: 'Wohnen:Miete', parentId: 1),
      Category(id: 3, name: 'Strom', fullName: 'Wohnen:Strom', parentId: 1),
    ];

    test('a full-path key is filed under its parent, not left at the top', () {
      final roots = buildCategoryBreakdown(
        {'Wohnen:Miete': 900, 'Wohnen:Strom': 100},
        categories,
        type: 'EXPENSE',
      );

      expect(roots, hasLength(1));
      expect(roots.single.name, 'Wohnen');
      expect(roots.single.hasChildren, isTrue);
      expect(roots.single.total, 1000);
      expect(
        roots.single.children.map((c) => c.name),
        containsAll(['Miete', 'Strom']),
      );
    });

    test('a bare name still works, so a server that sends leaves is not '
        'broken by this', () {
      final roots = buildCategoryBreakdown(
        {'Miete': 900},
        categories,
        type: 'EXPENSE',
      );

      expect(roots.single.name, 'Wohnen');
      expect(roots.single.hasChildren, isTrue);
    });

    test('the full path wins over a bare name shared by two categories, '
        'which the bare-name rule has to refuse', () {
      const ambiguous = [
        Category(id: 1, name: 'Auto', fullName: 'Auto'),
        Category(id: 2, name: 'Boot', fullName: 'Boot'),
        Category(id: 3, name: 'Tanken', fullName: 'Auto:Tanken', parentId: 1),
        Category(id: 4, name: 'Tanken', fullName: 'Boot:Tanken', parentId: 2),
      ];

      final roots = buildCategoryBreakdown(
        {'Auto:Tanken': 50},
        ambiguous,
        type: 'EXPENSE',
      );

      expect(roots.single.name, 'Auto');
      expect(roots.single.children.single.name, 'Tanken');
    });

    test('a path nothing accounts for still shows its amount', () {
      final roots = buildCategoryBreakdown(
        {'Nirgendwo:Irgendwas': 7},
        categories,
        type: 'EXPENSE',
      );

      expect(roots.single.name, 'Nirgendwo:Irgendwas');
      expect(roots.single.total, 7);
    });
  });

  group('driven by the captured response rather than invented names', () {
    test('every category name the real server sent joins into a tree', () {
      final names = realCategoryNames();
      expect(names, isNotEmpty, reason: 'the fixture should hold some');
      expect(
        names.every((n) => n.contains(':')),
        isTrue,
        reason: 'this backend names categories by path: $names',
      );

      final roots = buildCategoryBreakdown(
        {for (final n in names) n: 100},
        categoriesForRealNames(),
        type: 'EXPENSE',
      );

      expect(
        roots.every((r) => r.id != null),
        isTrue,
        reason: 'a null id means the name was never placed',
      );
      expect(
        roots.any((r) => r.hasChildren),
        isTrue,
        reason: 'nothing drillable means the chart cannot be opened',
      );
    });

    test('no amount is lost in the join', () {
      final names = realCategoryNames();
      final roots = buildCategoryBreakdown(
        {for (final n in names) n: 100},
        categoriesForRealNames(),
        type: 'EXPENSE',
      );

      expect(
        roots.fold<double>(0, (sum, r) => sum + r.total),
        names.length * 100,
      );
    });
  });
}
