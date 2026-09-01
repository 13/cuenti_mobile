import 'package:cuentimobile/features/transactions/domain/split_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? validate({
    String type = 'EXPENSE',
    bool touched = true,
    List<SplitEntry> splits = const [],
    double mainAmount = 40,
  }) => splitsValidationMessage(
    type: type,
    touched: touched,
    splits: splits,
    mainAmount: mainAmount,
  );

  test('accepts splits summing to the amount', () {
    expect(
      validate(
        splits: const [
          (categoryId: 1, amount: 10),
          (categoryId: 2, amount: 30),
        ],
      ),
      isNull,
    );
  });

  test('rejects a split with no category', () {
    expect(
      validate(splits: const [(categoryId: null, amount: 40)]),
      'Each split needs a category',
    );
  });

  test('rejects a sum that misses the amount', () {
    expect(
      validate(splits: const [(categoryId: 1, amount: 30)]),
      contains('Splits must sum to the amount'),
    );
  });

  test('tolerates half-cent rounding', () {
    expect(
      validate(
        splits: const [
          (categoryId: 1, amount: 13.333),
          (categoryId: 2, amount: 13.333),
          (categoryId: 3, amount: 13.335),
        ],
      ),
      isNull,
    );
  });

  test('stays quiet until the editor is touched', () {
    expect(
      validate(touched: false, splits: const [(categoryId: null, amount: 0)]),
      isNull,
    );
  });

  test('stays quiet for a transfer, which cannot be split', () {
    expect(
      validate(type: 'TRANSFER', splits: const [(categoryId: null, amount: 0)]),
      isNull,
    );
  });

  test('stays quiet with no splits drafted', () {
    expect(validate(), isNull);
  });
}
