import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockAccountsRepository extends Mock implements AccountsRepository {}

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

void main() {
  late MockTransactionsRepository txRepo;
  late MockAccountsRepository accountsRepo;
  late MockCategoriesRepository categoriesRepo;

  Transaction tx(int id, {DateTime? date}) => Transaction(
    id: id,
    payee: 'Payee $id',
    amount: 10,
    transactionDate: date ?? DateTime(2026),
  );

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
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(txRepo),
          accountsRepositoryProvider.overrideWithValue(accountsRepo),
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const TransactionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders first page and loads more on scroll to bottom', (
    tester,
  ) async {
    when(
      () =>
          txRepo.getPage(filter: const TransactionFilter(), page: 0, size: 50),
    ).thenAnswer(
      (_) async => TransactionPage(
        content: List.generate(50, (i) => tx(i + 1)),
        page: 0,
        size: 50,
        totalElements: 60,
        totalPages: 2,
      ),
    );
    when(
      () =>
          txRepo.getPage(filter: const TransactionFilter(), page: 1, size: 50),
    ).thenAnswer(
      (_) async => TransactionPage(
        content: List.generate(10, (i) => tx(51 + i)),
        page: 1,
        size: 50,
        totalElements: 60,
        totalPages: 2,
      ),
    );

    await pumpScreen(tester);

    expect(find.text('Payee 1'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100000));
    await tester.pumpAndSettle();

    verify(
      () =>
          txRepo.getPage(filter: const TransactionFilter(), page: 1, size: 50),
    ).called(1);
  });

  testWidgets('shows a sticky day header per distinct day', (tester) async {
    final dayOne = DateTime(2020, 3, 5);
    final dayTwo = DateTime(2020, 3, 6);
    when(
      () =>
          txRepo.getPage(filter: const TransactionFilter(), page: 0, size: 50),
    ).thenAnswer(
      (_) async => TransactionPage(
        content: [
          tx(1, date: dayTwo),
          tx(2, date: dayOne),
        ],
        page: 0,
        size: 50,
        totalElements: 2,
        totalPages: 1,
      ),
    );

    await pumpScreen(tester);

    final labelOne = DateFormat('EEE, d MMM yyyy').format(dayOne);
    final labelTwo = DateFormat('EEE, d MMM yyyy').format(dayTwo);

    expect(find.text(labelOne), findsOneWidget);
    expect(find.text(labelTwo), findsOneWidget);
  });

  testWidgets('debounces search input and requeries the repository with the '
      'search filter', (tester) async {
    when(
      () =>
          txRepo.getPage(filter: const TransactionFilter(), page: 0, size: 50),
    ).thenAnswer(
      (_) async => TransactionPage(
        content: [tx(1)],
        page: 0,
        size: 50,
        totalElements: 1,
        totalPages: 1,
      ),
    );
    when(
      () => txRepo.getPage(
        filter: const TransactionFilter(search: 'coffee'),
        page: 0,
        size: 50,
      ),
    ).thenAnswer(
      (_) async => TransactionPage(
        content: [tx(2)],
        page: 0,
        size: 50,
        totalElements: 1,
        totalPages: 1,
      ),
    );

    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pump(const Duration(milliseconds: 200));
    verifyNever(
      () => txRepo.getPage(
        filter: const TransactionFilter(search: 'coffee'),
        page: 0,
        size: 50,
      ),
    );

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    verify(
      () => txRepo.getPage(
        filter: const TransactionFilter(search: 'coffee'),
        page: 0,
        size: 50,
      ),
    ).called(1);
  });

  testWidgets('swipe endToStart shows the delete confirm sheet and confirming '
      'removes the row', (tester) async {
    var content = [tx(1)];
    when(
      () =>
          txRepo.getPage(filter: const TransactionFilter(), page: 0, size: 50),
    ).thenAnswer(
      (_) async => TransactionPage(
        content: content,
        page: 0,
        size: 50,
        totalElements: content.length,
        totalPages: content.isEmpty ? 0 : 1,
      ),
    );
    when(() => txRepo.delete(1)).thenAnswer((_) async => content = []);

    await pumpScreen(tester);

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete transaction?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => txRepo.delete(1)).called(1);
    expect(find.text('Payee 1'), findsNothing);
  });

  testWidgets('shows empty state with clear-filters action when no results', (
    tester,
  ) async {
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

    await pumpScreen(tester);

    expect(find.text('No transactions match'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Clear filters'), findsOneWidget);
  });
}
