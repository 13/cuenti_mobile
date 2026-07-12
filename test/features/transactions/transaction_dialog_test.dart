import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_split.dart';
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
    Transaction? transaction,
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
                return TransactionDialog(filter: filter, transaction: transaction);
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

  testWidgets(
    'editing a transaction with existing splits without touching the '
    'section calls save with splitsTouched: false '
    '(repository then omits the splits key so the server leaves them alone)',
    (tester) async {
      when(() => categoriesRepo.getAll(type: any(named: 'type'))).thenAnswer(
        (_) async => const [
          Category(id: 1, name: 'Food', type: 'EXPENSE'),
          Category(id: 2, name: 'Transport', type: 'EXPENSE'),
        ],
      );
      final existing = Transaction(
        id: 5,
        type: 'EXPENSE',
        amount: 40,
        fromAccountId: 1,
        transactionDate: DateTime(2026, 1, 1),
        splits: const [
          TransactionSplit(id: 10, categoryId: 1, amount: 10),
          TransactionSplit(id: 11, categoryId: 2, amount: 20),
        ],
      );
      when(
        () => txRepo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      ).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.single as Transaction,
      );

      await pumpDialog(tester, transaction: existing);

      final saveButton = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final captured = verify(
        () => txRepo.save(
          captureAny(),
          splitsTouched: captureAny(named: 'splitsTouched'),
        ),
      ).captured;
      expect((captured[0] as Transaction).splits, hasLength(2));
      expect(captured[1], isFalse);
    },
  );

  testWidgets(
    'adding a split that makes the sum mismatch disables Save and shows '
    'the validation banner',
    (tester) async {
      when(() => categoriesRepo.getAll(type: any(named: 'type'))).thenAnswer(
        (_) async => const [
          Category(id: 1, name: 'Food', type: 'EXPENSE'),
          Category(id: 2, name: 'Transport', type: 'EXPENSE'),
          Category(id: 3, name: 'Misc', type: 'EXPENSE'),
        ],
      );
      final existing = Transaction(
        id: 5,
        type: 'EXPENSE',
        amount: 40,
        fromAccountId: 1,
        transactionDate: DateTime(2026, 1, 1),
        splits: const [
          TransactionSplit(id: 10, categoryId: 1, amount: 10),
          TransactionSplit(id: 11, categoryId: 2, amount: 20),
        ],
      );

      await pumpDialog(tester, transaction: existing);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Give the new (3rd) row a category so only the sum mismatches
      // (10 + 20 + 0 = 30, main amount is 40).
      final newRowCategory = find.byType(DropdownButtonFormField<int?>).at(3);
      await tester.ensureVisible(newRowCategory);
      await tester.pumpAndSettle();
      await tester.tap(newRowCategory);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Misc').last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Splits must sum to the amount'),
        findsOneWidget,
      );
      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(saveButton.onPressed, isNull);
    },
  );

  testWidgets(
    'fixing the split sum re-enables Save and the saved transaction '
    'carries all splits',
    (tester) async {
      when(() => categoriesRepo.getAll(type: any(named: 'type'))).thenAnswer(
        (_) async => const [
          Category(id: 1, name: 'Food', type: 'EXPENSE'),
          Category(id: 2, name: 'Transport', type: 'EXPENSE'),
          Category(id: 3, name: 'Misc', type: 'EXPENSE'),
        ],
      );
      final existing = Transaction(
        id: 5,
        type: 'EXPENSE',
        amount: 40,
        fromAccountId: 1,
        transactionDate: DateTime(2026, 1, 1),
        splits: const [
          TransactionSplit(id: 10, categoryId: 1, amount: 10),
          TransactionSplit(id: 11, categoryId: 2, amount: 20),
        ],
      );
      when(
        () => txRepo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      ).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.single as Transaction,
      );

      await pumpDialog(tester, transaction: existing);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      final newRowCategory = find.byType(DropdownButtonFormField<int?>).at(3);
      await tester.ensureVisible(newRowCategory);
      await tester.pumpAndSettle();
      await tester.tap(newRowCategory);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Misc').last);
      await tester.pumpAndSettle();

      // 10 + 20 + 10 = 40, matching the main amount.
      final newRowAmount = find.widgetWithText(TextFormField, 'Amount').at(3);
      await tester.ensureVisible(newRowAmount);
      await tester.pumpAndSettle();
      await tester.enterText(newRowAmount, '10');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Splits must sum to the amount'),
        findsNothing,
      );

      final saveButton = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final captured = verify(
        () => txRepo.save(
          captureAny(),
          splitsTouched: captureAny(named: 'splitsTouched'),
        ),
      ).captured;
      expect((captured[0] as Transaction).splits, hasLength(3));
      expect(captured[1], isTrue);
    },
  );

  testWidgets(
    'switching to TRANSFER with an invalid split drafted re-enables Save '
    'and saves with splitsTouched: false (regression: hidden splits '
    'section kept Save permanently disabled)',
    (tester) async {
      when(() => categoriesRepo.getAll(type: any(named: 'type'))).thenAnswer(
        (_) async => const [
          Category(id: 1, name: 'Food', type: 'EXPENSE'),
          Category(id: 2, name: 'Transport', type: 'EXPENSE'),
        ],
      );
      final existing = Transaction(
        id: 5,
        type: 'EXPENSE',
        amount: 40,
        fromAccountId: 1,
        transactionDate: DateTime(2026, 1, 1),
      );
      when(
        () => txRepo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      ).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.single as Transaction,
      );

      await pumpDialog(tester, transaction: existing);

      // Draft an invalid split (no category, empty amount) under EXPENSE:
      // banner shown, Save disabled.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('Each split needs a category'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNull,
      );

      // Switch to TRANSFER: section and banner disappear, Save re-enabled.
      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();
      expect(find.text('Each split needs a category'), findsNothing);
      expect(find.text('Splits'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNotNull,
      );

      // TRANSFER also needs a To Account before saving.
      final toAccount = find.byType(DropdownButtonFormField<int>).at(1);
      await tester.ensureVisible(toAccount);
      await tester.pumpAndSettle();
      await tester.tap(toAccount);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giro').last);
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // splitsTouched: false → repository omits the splits key entirely
      // (pinned by transaction_splits_payload_test.dart).
      final captured = verify(
        () => txRepo.save(
          captureAny(),
          splitsTouched: captureAny(named: 'splitsTouched'),
        ),
      ).captured;
      expect((captured[0] as Transaction).splits, isEmpty);
      expect(captured[1], isFalse);
    },
  );
}
