import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock implements TransactionsRepository {}

class MockAccountsRepository extends Mock implements AccountsRepository {}

void main() {
  late MockTransactionsRepository txRepo;
  late MockAccountsRepository accountsRepo;

  Transaction tx(int id) => Transaction(
        id: id,
        payee: 'Payee $id',
        amount: 10,
        transactionDate: DateTime(2026, 1, 1),
      );

  setUp(() {
    txRepo = MockTransactionsRepository();
    accountsRepo = MockAccountsRepository();

    when(() => accountsRepo.getAll()).thenAnswer(
        (_) async => [const Account(id: 1, accountName: 'Giro')]);

    when(() => txRepo.getPage(accountId: null, page: 0, size: 50)).thenAnswer(
        (_) async => TransactionPage(
            content: List.generate(50, (i) => tx(i + 1)),
            page: 0,
            size: 50,
            totalElements: 60,
            totalPages: 2));
    when(() => txRepo.getPage(accountId: null, page: 1, size: 50)).thenAnswer(
        (_) async => TransactionPage(
            content: List.generate(10, (i) => tx(51 + i)),
            page: 1,
            size: 50,
            totalElements: 60,
            totalPages: 2));
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(txRepo),
          accountsRepositoryProvider.overrideWithValue(accountsRepo),
        ],
        child: const MaterialApp(home: TransactionsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders first page and loads more on scroll to bottom',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Payee 1'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -100000));
    await tester.pumpAndSettle();

    verify(() => txRepo.getPage(accountId: null, page: 1, size: 50)).called(1);
  });
}
