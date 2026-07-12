import 'package:cuentimobile/api/api_client.dart' as legacy;
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/ui/transaction_dialog.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:cuentimobile/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart' hide Consumer;

class MockTransactionsRepository extends Mock implements TransactionsRepository {}

class MockAccountsRepository extends Mock implements AccountsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Transaction(amount: 0, transactionDate: DateTime(2026, 1, 1)));
  });

  late MockTransactionsRepository txRepo;
  late MockAccountsRepository accountsRepo;
  late DataProvider dataProvider;

  setUp(() {
    txRepo = MockTransactionsRepository();
    accountsRepo = MockAccountsRepository();
    dataProvider = DataProvider(legacy.ApiClient());

    when(() => accountsRepo.getAll()).thenAnswer(
        (_) async => [const Account(id: 1, accountName: 'Giro')]);
    when(() => txRepo.getPage(accountId: null, page: 0, size: 50)).thenAnswer(
        (_) async => const TransactionPage(
            content: [], page: 0, size: 50, totalElements: 0, totalPages: 0));
  });

  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(txRepo),
          accountsRepositoryProvider.overrideWithValue(accountsRepo),
        ],
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<DataProvider>.value(value: dataProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              // The real screen keeps the family provider alive by watching
              // it while the modal sheet with the dialog is open; mirror
              // that here so the dialog's `ref.invalidateSelf()` on save
              // doesn't hit an already-disposed provider.
              body: Consumer(builder: (context, ref, _) {
                ref.watch(transactionsControllerProvider(accountId: null));
                return const TransactionDialog(accountId: null);
              }),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('save posts a transaction without splits key', (tester) async {
    when(() => txRepo.save(any())).thenAnswer((invocation) async =>
        invocation.positionalArguments.single as Transaction);

    await pumpDialog(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '12,34');
    await tester.enterText(find.widgetWithText(TextFormField, 'Payee'), 'Baker');

    // EXPENSE type requires a From Account.
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giro').last);
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final captured =
        verify(() => txRepo.save(captureAny())).captured.single as Transaction;
    expect(captured.amount, 12.34);
    expect(captured.payee, 'Baker');
    expect(captured.splits, isEmpty);
  });
}
