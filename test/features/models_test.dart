import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/statistics/domain/statistics_data.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Account parses ints as doubles and defaults', () {
    final a = Account.fromJson(const {
      'id': 1, 'accountName': 'Giro', 'accountType': 'BANK',
      'currency': 'EUR', 'startBalance': 100, 'balance': 250,
    });
    expect(a.balance, 250.0);
    expect(a.excludeFromReports, false);
    expect(a.displayType, 'Bank');
  });

  test('Transaction parses splits and date', () {
    final t = Transaction.fromJson(const {
      'id': 5, 'type': 'EXPENSE', 'amount': 50,
      'transactionDate': '2026-05-01T12:00:00',
      'splits': [
        {'id': 1, 'categoryId': 2, 'categoryName': 'Food', 'amount': 30},
        {'id': 2, 'categoryId': 3, 'amount': 20, 'memo': 'x'},
      ],
    });
    expect(t.splits.length, 2);
    expect(t.splits.first.amount, 30.0);
    expect(t.transactionDate.year, 2026);
  });

  test('Transaction without splits key defaults to empty list', () {
    final t = Transaction.fromJson(const {
      'type': 'EXPENSE', 'amount': 10, 'transactionDate': '2026-01-01T00:00:00',
    });
    expect(t.splits, isEmpty);
  });

  test('TransactionPage parses envelope', () {
    final p = TransactionPage.fromJson(const {
      'content': [
        {'type': 'EXPENSE', 'amount': 10, 'transactionDate': '2026-01-01T00:00:00'},
      ],
      'page': 0, 'size': 50, 'totalElements': 1, 'totalPages': 1,
    });
    expect(p.content.single.amount, 10.0);
    expect(p.totalPages, 1);
  });

  test('StatisticsData parses category maps', () {
    final s = StatisticsData.fromJson(const {
      'totalIncome': 100, 'totalExpense': 40, 'balance': 60,
      'currency': 'EUR', 'transactionCount': 3,
      'expenseByCategory': {'Food': 25, 'Fuel': 15},
    });
    expect(s.expenseByCategory['Food'], 25.0);
    expect(s.monthlyIncome, isEmpty);
  });

  test('UserProfile isAdmin and vehicle category', () {
    final u = UserProfile.fromJson(const {
      'username': 'demo', 'email': 'd@x', 'firstName': 'D', 'lastName': 'M',
      'roles': ['ROLE_ADMIN'], 'defaultVehicleCategoryId': 7,
    });
    expect(u.isAdmin, true);
    expect(u.defaultVehicleCategoryId, 7);
  });
}
