import 'dart:io';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:cuentimobile/features/payees/data/payees_repository.dart';
import 'package:cuentimobile/features/payees/domain/payee.dart';
import 'package:cuentimobile/features/payees/ui/payee_picker_field.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_split.dart';
import 'package:cuentimobile/features/transactions/ui/transaction_dialog.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockAccountsRepository extends Mock implements AccountsRepository {}

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

class MockPayeesRepository extends Mock implements PayeesRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Transaction(amount: 0, transactionDate: DateTime(2026)),
    );
    registerFallbackValue(const Category(name: 'fallback'));
    registerFallbackValue(const Payee(name: 'fallback'));
  });

  late MockTransactionsRepository txRepo;
  late MockAccountsRepository accountsRepo;
  late MockCategoriesRepository categoriesRepo;
  late MockPayeesRepository payeesRepo;
  late Directory outboxDir;

  setUp(() {
    txRepo = MockTransactionsRepository();
    accountsRepo = MockAccountsRepository();
    categoriesRepo = MockCategoriesRepository();
    payeesRepo = MockPayeesRepository();
    outboxDir = Directory.systemTemp.createTempSync('tx_dialog_outbox');
    addTearDown(() => outboxDir.deleteSync(recursive: true));
    when(() => payeesRepo.getAll()).thenAnswer((_) async => []);
    when(() => payeesRepo.save(any())).thenAnswer(
      (i) async => i.positionalArguments.first as Payee,
    );

    when(
      () => accountsRepo.getAll(),
    ).thenAnswer((_) async => [const Account(id: 1, accountName: 'Giro')]);
    when(
      () => categoriesRepo.getAll(type: any(named: 'type')),
    ).thenAnswer((_) async => []);
    when(
      () => txRepo.getPage(),
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
    Locale? locale,
    TransactionFilter filter = const TransactionFilter(),
    Transaction? transaction,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(txRepo),
          accountsRepositoryProvider.overrideWithValue(accountsRepo),
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
          payeesRepositoryProvider.overrideWithValue(payeesRepo),
          transactionOutboxProvider.overrideWithValue(
            TransactionOutbox(outboxDir),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            // The real screen keeps the family provider alive by watching
            // it while the modal sheet with the dialog is open; mirror
            // that here so the dialog's `ref.invalidateSelf()` on save
            // doesn't hit an already-disposed provider.
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(transactionsControllerProvider(filter: filter));
                return TransactionDialog(
                  filter: filter,
                  transaction: transaction,
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the category picker at [index] (0 is the main Category field,
  /// the rest are split rows) and picks the entry labelled [name].
  Future<void> selectCategoryAt(
    WidgetTester tester,
    int index,
    String name,
  ) async {
    final field = find.byType(CategoryPickerField).at(index);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(CategorySearchSheet),
        matching: find.text(name),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Sets the payee through its picker: open the sheet, type, and take the
  /// create row. The field stopped being a plain text box when it became a
  /// picker like the category one.
  Future<void> setPayee(WidgetTester tester, String name) async {
    final field = find.byType(PayeePickerField);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, name);
    await tester.pumpAndSettle();
    // Found by its icon rather than its words: this helper runs under the
    // German locale too, where the row reads "„Baker“ anlegen".
    await tester.tap(find.widgetWithIcon(ListTile, Icons.add));
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSave(
    WidgetTester tester, {
    String amountLabel = 'Amount',
    String payeeLabel = 'Payee',
    String saveLabel = 'Save',
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, amountLabel),
      '12,34',
    );
    await setPayee(tester, 'Baker');

    // EXPENSE type requires a From Account.
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giro').last);
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, saveLabel);
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
      when(() => txRepo.getPage(filter: filter)).thenAnswer(
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
        () => txRepo.getPage(filter: filter),
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
          Category(id: 1, name: 'Food'),
          Category(id: 2, name: 'Transport'),
        ],
      );
      final existing = Transaction(
        id: 5,
        amount: 40,
        fromAccountId: 1,
        transactionDate: DateTime(2026),
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
          Category(id: 1, name: 'Food'),
          Category(id: 2, name: 'Transport'),
          Category(id: 3, name: 'Misc'),
        ],
      );
      final existing = Transaction(
        id: 5,
        amount: 40,
        fromAccountId: 1,
        transactionDate: DateTime(2026),
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
      await selectCategoryAt(tester, 3, 'Misc');

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
          Category(id: 1, name: 'Food'),
          Category(id: 2, name: 'Transport'),
          Category(id: 3, name: 'Misc'),
        ],
      );
      final existing = Transaction(
        id: 5,
        amount: 40,
        fromAccountId: 1,
        transactionDate: DateTime(2026),
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
      await selectCategoryAt(tester, 3, 'Misc');

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
          Category(id: 1, name: 'Food'),
          Category(id: 2, name: 'Transport'),
        ],
      );
      final existing = Transaction(
        id: 5,
        amount: 40,
        fromAccountId: 1,
        transactionDate: DateTime(2026),
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

  testWidgets(
    'switching a transaction with existing splits to TRANSFER saves with '
    'splitsTouched: true and an empty splits list (regression: omitting '
    'the key let the backend preserve the old splits on the now-transfer '
    'row permanently)',
    (tester) async {
      when(() => categoriesRepo.getAll(type: any(named: 'type'))).thenAnswer(
        (_) async => const [
          Category(id: 1, name: 'Food'),
          Category(id: 2, name: 'Transport'),
        ],
      );
      final existing = Transaction(
        id: 5,
        amount: 40,
        fromAccountId: 1,
        transactionDate: DateTime(2026),
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

      // Switch to TRANSFER without touching the splits section at all.
      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();
      expect(find.text('Splits'), findsNothing);

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

      final captured = verify(
        () => txRepo.save(
          captureAny(),
          splitsTouched: captureAny(named: 'splitsTouched'),
        ),
      ).captured;
      expect((captured[0] as Transaction).splits, isEmpty);
      expect(captured[1], isTrue);
    },
  );

  /// Presents the dialog the way the app does -- in a modal sheet over a
  /// Scaffold -- so that popping it leaves the messenger's Scaffold standing.
  /// The flat host above cannot show a snackbar raised as the dialog closes.
  Future<void> pumpDialogInSheet(
    WidgetTester tester, {
    Locale? locale,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(txRepo),
          accountsRepositoryProvider.overrideWithValue(accountsRepo),
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
          payeesRepositoryProvider.overrideWithValue(payeesRepo),
          transactionOutboxProvider.overrideWithValue(
            TransactionOutbox(outboxDir),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(transactionsControllerProvider());
              return Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const TransactionDialog(),
                    ),
                    child: const Text('open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('the payee field', () {
    const known = [
      Payee(id: 1, name: 'Aral Tankstelle'),
      Payee(id: 2, name: 'Rewe Markt'),
    ];

    Future<void> openPayeeSheet(WidgetTester tester) async {
      when(() => payeesRepo.getAll()).thenAnswer((_) async => known);
      await pumpDialog(tester);
      await tester.ensureVisible(find.byType(PayeePickerField));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PayeePickerField));
      await tester.pumpAndSettle();
    }

    testWidgets('lists the payees the account knows, and picking one fills '
        'the field', (tester) async {
      await openPayeeSheet(tester);
      await tester.enterText(find.byType(TextField).last, 'tank');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aral Tankstelle').last);
      await tester.pumpAndSettle();

      expect(find.text('Aral Tankstelle'), findsWidgets);
    });

    testWidgets('offers to create one it does not know', (tester) async {
      await openPayeeSheet(tester);
      await tester.enterText(find.byType(TextField).last, 'Bäckerei');
      await tester.pumpAndSettle();

      expect(find.text('Create "Bäckerei"'), findsOneWidget);
    });

    testWidgets('creating one saves it', (tester) async {
      when(() => payeesRepo.save(any())).thenAnswer(
        (i) async => i.positionalArguments.first as Payee,
      );
      await openPayeeSheet(tester);
      await tester.enterText(find.byType(TextField).last, 'Bäckerei');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create "Bäckerei"'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => payeesRepo.save(captureAny())).captured.single as Payee;
      expect(saved.name, 'Bäckerei');
    });

    testWidgets('a payee the server refuses still goes on the transaction, '
        'because the transaction carries the name itself', (tester) async {
      when(() => payeesRepo.save(any())).thenThrow(
        const ValidationException('Name already taken'),
      );
      await openPayeeSheet(tester);
      await tester.enterText(find.byType(TextField).last, 'Bäckerei');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create "Bäckerei"'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Bäckerei'), findsWidgets);
    });
  });

  testWidgets('saving confirms it happened, rather than closing in silence', (
    tester,
  ) async {
    when(() => txRepo.save(any())).thenAnswer(
      (invocation) async =>
          invocation.positionalArguments.single as Transaction,
    );

    await pumpDialogInSheet(tester);
    await fillAndSave(tester);

    expect(find.text('Transaction saved'), findsOneWidget);
  });

  testWidgets('a failed save says so and does not claim success', (
    tester,
  ) async {
    when(() => txRepo.save(any())).thenThrow(
      const ServerException(
        'Server error (500)',
        serverMessage: 'Account is closed',
        statusCode: 500,
      ),
    );

    await pumpDialogInSheet(tester);
    await fillAndSave(tester);

    expect(
      find.text('Account is closed'),
      findsOneWidget,
      reason: 'a server that explained itself is quoted, not translated over',
    );
    expect(find.text('Transaction saved'), findsNothing);
  });

  testWidgets('the confirmation is in the chosen language', (tester) async {
    when(() => txRepo.save(any())).thenAnswer(
      (invocation) async =>
          invocation.positionalArguments.single as Transaction,
    );

    await pumpDialogInSheet(tester, locale: const Locale('de'));
    await fillAndSave(
      tester,
      amountLabel: 'Betrag',
      payeeLabel: 'Empfänger',
      saveLabel: 'Speichern',
    );

    expect(find.text('Buchung gespeichert'), findsOneWidget);
  });

  testWidgets(
    'a transaction whose payment method this build does not know still opens '
    'for editing',
    (tester) async {
      await pumpDialog(
        tester,
        transaction: Transaction(
          id: 1,
          amount: 12,
          transactionDate: DateTime(2026),
          paymentMethod: 'DIRECT_DEBIT',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('DIRECT_DEBIT'), findsOneWidget);
    },
  );

  group('creating a category from the form', () {
    const existing = [
      Category(id: 10, name: 'Auto', fullName: 'Auto'),
    ];

    Future<void> pumpWithCategories(WidgetTester tester) async {
      when(
        () => categoriesRepo.getAll(type: any(named: 'type')),
      ).thenAnswer((_) async => existing);
      when(() => categoriesRepo.save(any())).thenAnswer(
        (i) async => (i.positionalArguments.first as Category).copyWith(id: 77),
      );
      await pumpDialog(tester);
    }

    Future<void> openPickerAndType(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.byType(CategoryPickerField));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CategoryPickerField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, text);
      await tester.pumpAndSettle();
    }

    testWidgets('offers to create a category the search did not find', (
      tester,
    ) async {
      await pumpWithCategories(tester);
      await openPickerAndType(tester, 'Werkstatt');

      expect(find.text('Create "Werkstatt"'), findsOneWidget);
    });

    testWidgets('saves it with the type the form is on', (tester) async {
      await pumpWithCategories(tester);
      await openPickerAndType(tester, 'Werkstatt');
      await tester.tap(find.text('Create "Werkstatt"'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => categoriesRepo.save(captureAny())).captured.single
              as Category;
      expect(saved.name, 'Werkstatt');
      expect(saved.type, 'EXPENSE');
      expect(saved.parentId, isNull);
    });

    testWidgets('files it under the parent the typed path names', (
      tester,
    ) async {
      await pumpWithCategories(tester);
      await openPickerAndType(tester, 'Auto:Werkstatt');
      await tester.tap(find.text('Create "Auto:Werkstatt"'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => categoriesRepo.save(captureAny())).captured.single
              as Category;
      expect(saved.name, 'Werkstatt');
      expect(saved.parentId, 10);
    });

    testWidgets('a create the server refuses says so and does not select '
        'anything', (tester) async {
      when(
        () => categoriesRepo.getAll(type: any(named: 'type')),
      ).thenAnswer((_) async => existing);
      when(() => categoriesRepo.save(any())).thenThrow(
        const ValidationException('Name already taken'),
      );
      await pumpDialog(tester);
      await openPickerAndType(tester, 'Werkstatt');
      await tester.tap(find.text('Create "Werkstatt"'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
