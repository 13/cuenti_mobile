import 'package:cuentimobile/core/widgets/enum_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const types = ['BANK', 'CASH', 'SAVINGS'];

  String? valueOf(DropdownMenuItem<String> item) => item.value;
  String textOf(DropdownMenuItem<String> item) => (item.child as Text).data!;

  group('dropdownItemsFor', () {
    test('builds one entry per value', () {
      final items = dropdownItemsFor(types, 'BANK');

      expect(items.map(valueOf), types);
    });

    test('labels each entry with the value itself by default', () {
      final items = dropdownItemsFor(types, 'BANK');

      expect(items.map(textOf), types);
    });

    test('runs the label function over each value', () {
      final items = dropdownItemsFor(
        types,
        'BANK',
        label: (v) => v.toLowerCase(),
      );

      expect(items.map(textOf), ['bank', 'cash', 'savings']);
    });

    test(
      'carries a selected value the list does not hold, which is what a '
      'server sending an unknown type comes down to',
      () {
        final items = dropdownItemsFor(types, 'CRYPTO_VAULT');

        expect(items.map(valueOf), contains('CRYPTO_VAULT'));
        expect(
          items.where((i) => i.value == 'CRYPTO_VAULT'),
          hasLength(1),
          reason: 'exactly one, or the dropdown asserts just the same',
        );
      },
    );

    test('shows that unknown value first, where it can be seen', () {
      final items = dropdownItemsFor(types, 'CRYPTO_VAULT');

      expect(valueOf(items.first), 'CRYPTO_VAULT');
    });

    test(
      'leaves the unknown value unlabelled rather than inventing a name',
      () {
        final items = dropdownItemsFor(
          types,
          'CRYPTO_VAULT',
          label: (v) => 'known:$v',
        );

        expect(textOf(items.first), 'CRYPTO_VAULT');
      },
    );

    test('does not repeat a selected value the list already holds', () {
      final items = dropdownItemsFor(types, 'CASH');

      expect(items.where((i) => i.value == 'CASH'), hasLength(1));
      expect(items, hasLength(types.length));
    });

    test('an empty list still yields the selected value, so a dropdown '
        'opened before its options loaded has something to show', () {
      final items = dropdownItemsFor(const [], 'EUR');

      expect(items.map(valueOf), ['EUR']);
    });
  });
}
