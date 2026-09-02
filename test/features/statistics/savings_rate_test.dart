import 'package:cuentimobile/features/statistics/domain/savings_rate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the share of income that was not spent', () {
    expect(savingsRate(income: 1000, expense: 600), 40);
  });

  test('spending everything earned saves nothing', () {
    expect(savingsRate(income: 1000, expense: 1000), 0);
  });

  test('spending more than was earned is a negative rate, not a floor at '
      'zero -- a month in the red should look like one', () {
    expect(savingsRate(income: 1000, expense: 1500), -50);
  });

  test('no income leaves the rate undefined rather than zero: dividing by '
      'nothing is not the same as having saved nothing', () {
    expect(savingsRate(income: 0, expense: 400), isNull);
  });

  test('negative income is undefined too, not a wildly wrong percentage', () {
    expect(savingsRate(income: -100, expense: 50), isNull);
  });

  test('income with no spending at all is the whole of it', () {
    expect(savingsRate(income: 800, expense: 0), 100);
  });
}
