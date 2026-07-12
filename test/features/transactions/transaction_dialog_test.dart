import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/ui/transaction_dialog.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockAccountsRepository extends Mock implements AccountsRepository {}

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Transaction(amount: 0, transactionDate: DateTime(2026, 1, 1)),
    );
  });

  late MockTransactionsRepository txRepo;
  late MockAccountsRepository accountsRepo;
  late MockCategoriesRepository categoriesRepo;

  setUp(() {
    txRepo = MockTransactionsRepository();
    accountsRepo = MockAccountsRepository();
    categoriesRepo = MockCategoriesRepository();

    when(
      () => accountsRepo.getAll(),
    ).thenAnswer((_) async => [const Account(id: 1, accountName: 'Giro')]);
    when(
      () => categoriesRepo.getAll(type: any(named: 'type')),
    ).thenAnswer((_) async => []);
    when(
      () =>
          txRepo.getPage(filter: const TransactionFilter(), page: 0, size: 50),
    ).thenAnswer(
      (_) async => const TransactionPage(
        content: [],
        page: 0,
        size: 50,
        totalElements: 0,
        totalPages: 0,
      ),
    );
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    TransactionFilter filter = const TransactionFilter(),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(txRepo),
          accountsRepositoryProvider.overrideWithValue(accountsRepo),
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            // The real screen keeps the family provider alive by watching
            // it while the modal sheet with the dialog is open; mirror
            // that here so the dialog's `ref.invalidateSelf()` on save
            // doesn't hit an already-disposed provider.
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(transactionsControllerProvider(filter: filter));
                return TransactionDialog(filter: filter);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSave(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '12,34',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Payee'),
      'Baker',
    );

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
  }

  testWidgets('save posts a transaction without splits key', (tester) async {
    when(() => txRepo.save(any())).thenAnswer(
      (invocation) async =>
          invocation.positionalArguments.single as Transaction,
    );

    await pumpDialog(tester);
    await fillAndSave(tester);

    final captured =
        verify(() => txRepo.save(captureAny())).captured.single as Transaction;
    expect(captured.amount, 12.34);
    expect(captured.payee, 'Baker');
    expect(captured.splits, isEmpty);
  });

  testWidgets(
    'save refreshes the controller instance keyed by the active filter '
    '(regression: filtered list went stale after save)',
    (tester) async {
      const filter = TransactionFilter(search: 'coffee');
      when(() => txRepo.getPage(filter: filter, page: 0, size: 50)).thenAnswer(
        (_) async => const TransactionPage(
          content: [],
          page: 0,
          size: 50,
          totalElements: 0,
          totalPages: 0,
        ),
      );
      when(() => txRepo.save(any())).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.single as Transaction,
      );

      await pumpDialog(tester, filter: filter);
      await fillAndSave(tester);

      // Initial build + post-save invalidateSelf refetch, both for the
      // exact filter instance the screen is watching.
      verify(
        () => txRepo.getPage(filter: filter, page: 0, size: 50),
      ).called(greaterThanOrEqualTo(2));
    },
  );
}
