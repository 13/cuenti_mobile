import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rule two callers share and neither can ask the server about: a queued
/// create the server has never seen, and a filtered list cut locally out of a
/// cached unfiltered one.
void main() {
  Transaction tx({
    String type = 'EXPENSE',
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
    DateTime? date,
    String? payee,
    String? memo,
  }) => Transaction(
    type: type,
    amount: 10,
    transactionDate: date ?? DateTime(2026, 3, 15),
    fromAccountId: fromAccountId,
    toAccountId: toAccountId,
    categoryId: categoryId,
    payee: payee,
    memo: memo,
  );

  test('an empty filter matches everything', () {
    expect(const TransactionFilter().matches(tx()), isTrue);
  });

  group('account', () {
    test('matches on either side, so a transfer counts for both', () {
      const f = TransactionFilter(accountId: 3);
      expect(f.matches(tx(fromAccountId: 3)), isTrue);
      expect(f.matches(tx(toAccountId: 3)), isTrue);
    });

    test('rejects a row on neither side, including one with no account', () {
      const f = TransactionFilter(accountId: 3);
      expect(f.matches(tx(fromAccountId: 9, toAccountId: 8)), isFalse);
      expect(f.matches(tx()), isFalse);
    });
  });

  test('type is exact', () {
    const f = TransactionFilter(type: 'TRANSFER');
    expect(f.matches(tx(type: 'TRANSFER')), isTrue);
    expect(f.matches(tx(type: 'INCOME')), isFalse);
  });

  test('category is exact', () {
    const f = TransactionFilter(categoryId: 4);
    expect(f.matches(tx(categoryId: 4)), isTrue);
    expect(f.matches(tx(categoryId: 5)), isFalse);
    expect(f.matches(tx()), isFalse);
  });

  group('date range', () {
    test('is inclusive of both ends', () {
      final f = TransactionFilter(
        start: DateTime(2026, 3, 10),
        end: DateTime(2026, 3, 20),
      );
      expect(f.matches(tx(date: DateTime(2026, 3, 10))), isTrue);
      expect(f.matches(tx(date: DateTime(2026, 3, 20))), isTrue);
      expect(f.matches(tx(date: DateTime(2026, 3, 9))), isFalse);
      expect(f.matches(tx(date: DateTime(2026, 3, 21))), isFalse);
    });

    test('compares by day, so an entry made at 18:00 is inside a range '
        'ending that same day', () {
      final f = TransactionFilter(end: DateTime(2026, 3, 15));

      expect(f.matches(tx(date: DateTime(2026, 3, 15, 18))), isTrue);
    });
  });

  group('search', () {
    test('is a case-insensitive substring of the payee or the memo', () {
      const f = TransactionFilter(search: 'aldi');
      expect(f.matches(tx(payee: 'ALDI Süd')), isTrue);
      expect(f.matches(tx(memo: 'weekly Aldi run')), isTrue);
      expect(f.matches(tx(payee: 'Rewe')), isFalse);
    });

    test('a row with neither payee nor memo is not a match', () {
      expect(const TransactionFilter(search: 'aldi').matches(tx()), isFalse);
    });

    test('an empty search narrows nothing', () {
      expect(const TransactionFilter(search: '').matches(tx()), isTrue);
    });
  });

  test('every field has to agree, not just one', () {
    final f = TransactionFilter(
      accountId: 3,
      type: 'TRANSFER',
      start: DateTime(2026, 3),
    );

    expect(
      f.matches(tx(type: 'TRANSFER', fromAccountId: 3)),
      isTrue,
    );
    // Right account and date, wrong type.
    expect(f.matches(tx(fromAccountId: 3)), isFalse);
  });
}
