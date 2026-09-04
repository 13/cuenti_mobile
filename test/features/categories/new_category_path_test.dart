import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const categories = [
    Category(id: 1, name: 'Auto', fullName: 'Auto'),
    Category(id: 2, name: 'Tanken', fullName: 'Auto:Tanken', parentId: 1),
    Category(id: 3, name: 'Wohnen', fullName: 'Wohnen'),
  ];

  group('parseNewCategoryPath', () {
    test('a bare name is a top-level category', () {
      final parsed = parseNewCategoryPath('Werkstatt', categories);

      expect(parsed.name, 'Werkstatt');
      expect(parsed.parentId, isNull);
    });

    test('a path files the name under the parent it names', () {
      final parsed = parseNewCategoryPath('Auto:Werkstatt', categories);

      expect(parsed.name, 'Werkstatt');
      expect(parsed.parentId, 1);
    });

    test('a deeper path takes everything before the last colon as the '
        'parent', () {
      final parsed = parseNewCategoryPath('Auto:Tanken:Diesel', categories);

      expect(parsed.name, 'Diesel');
      expect(parsed.parentId, 2);
    });

    test('a prefix nothing accounts for is not invented into a parent -- the '
        'whole thing becomes the name, where it can be seen and fixed', () {
      final parsed = parseNewCategoryPath('Nirgendwo:Werkstatt', categories);

      expect(parsed.name, 'Nirgendwo:Werkstatt');
      expect(parsed.parentId, isNull);
    });

    test(
      'surrounding space is trimmed, from the name and the parent alike',
      () {
        final parsed = parseNewCategoryPath('  Auto : Werkstatt  ', categories);

        expect(parsed.name, 'Werkstatt');
        expect(parsed.parentId, 1);
      },
    );

    test('the parent matches case-insensitively, the way the search does', () {
      expect(parseNewCategoryPath('auto:Werkstatt', categories).parentId, 1);
    });

    test('a parent named by its bare name works too, not only by its path', () {
      final parsed = parseNewCategoryPath('Tanken:Diesel', categories);

      expect(parsed.name, 'Diesel');
      expect(parsed.parentId, 2);
    });

    test('a trailing colon leaves no name, so there is nothing to create', () {
      expect(parseNewCategoryPath('Auto:', categories).name, isEmpty);
    });

    test('blank text yields no name', () {
      expect(parseNewCategoryPath('   ', categories).name, isEmpty);
    });
  });

  group('offersCreate', () {
    test('offers to create what does not exist yet', () {
      expect(offersCreate('Werkstatt', categories), isTrue);
    });

    test('does not offer to create something already there, by path', () {
      expect(offersCreate('Auto:Tanken', categories), isFalse);
    });

    test('nor by bare name', () {
      expect(offersCreate('Tanken', categories), isFalse);
    });

    test('ignores case and padding when deciding that', () {
      expect(offersCreate('  auto:tanken ', categories), isFalse);
    });

    test('still offers when a partial match is on screen: typing Werk with '
        'Werkstatt Nord listed should not stop you making Werk', () {
      const withPartial = [
        Category(id: 9, name: 'Werkstatt Nord', fullName: 'Werkstatt Nord'),
      ];

      expect(offersCreate('Werk', withPartial), isTrue);
    });

    test('offers nothing for blank text', () {
      expect(offersCreate('  ', categories), isFalse);
    });
  });
}
