import 'dart:io';

import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/ui/transaction_dialog.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:cuentimobile/features/vehicles/data/vehicles_repository.dart';
import 'package:cuentimobile/features/vehicles/domain/vehicle_report.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockAccountsRepository extends Mock implements AccountsRepository {}

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

class MockVehiclesRepository extends Mock implements VehiclesRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Transaction(amount: 0, transactionDate: DateTime(2026)),
    );
  });

  late MockTransactionsRepository txRepo;
  late MockAccountsRepository accountsRepo;
  late MockCategoriesRepository categoriesRepo;
  late MockVehiclesRepository vehiclesRepo;
  late Directory outboxDir;

  setUp(() {
    txRepo = MockTransactionsRepository();
    accountsRepo = MockAccountsRepository();
    categoriesRepo = MockCategoriesRepository();
    vehiclesRepo = MockVehiclesRepository();
    outboxDir = Directory.systemTemp.createTempSync('fuel_dialog_outbox');
    addTearDown(() => outboxDir.deleteSync(recursive: true));

    when(
      () => accountsRepo.getAll(),
    ).thenAnswer((_) async => [const Account(id: 1, accountName: 'Giro')]);
    when(() => categoriesRepo.getAll(type: any(named: 'type'))).thenAnswer(
      (_) async => const [
        Category(id: 9, name: 'Tanken'),
        Category(id: 2, name: 'Food'),
      ],
    );
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
    // Category 9 is a fuel category with a known last odometer.
    when(
      () => vehiclesRepo.getReport(
        categoryId: 9,
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer(
      (_) async => VehicleReport(
        entries: [
          FuelEntry(date: DateTime(2026, 7), odometer: 100000, liters: 40),
        ],
      ),
    );
    // Category 2 has no fuel entries.
    when(
      () => vehiclesRepo.getReport(
        categoryId: 2,
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) async => const VehicleReport());
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    Transaction? transaction,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(txRepo),
          accountsRepositoryProvider.overrideWithValue(accountsRepo),
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
          vehiclesRepositoryProvider.overrideWithValue(vehiclesRepo),
          transactionOutboxProvider.overrideWithValue(
            TransactionOutbox(outboxDir),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(
                  transactionsControllerProvider(),
                );
                return TransactionDialog(transaction: transaction);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectCategory(WidgetTester tester, String name) async {
    final field = find.byType(CategoryPickerField).first;
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

  testWidgets('fuel section hidden for non-fuel category', (tester) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Food');
    expect(find.byKey(const Key('fuel-odometer')), findsNothing);
  });

  testWidgets('fuel section appears for fuel category with last-odometer '
      'hint', (tester) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');
    expect(find.byKey(const Key('fuel-odometer')), findsOneWidget);
    expect(find.byKey(const Key('fuel-liters')), findsOneWidget);
    expect(find.byKey(const Key('fuel-full')), findsOneWidget);
    expect(find.textContaining('last: 100000'), findsOneWidget);
  });

  testWidgets('field edits write the canonical memo', (tester) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');

    await tester.enterText(
      find.byKey(const Key('fuel-odometer')),
      '100650',
    );
    await tester.enterText(find.byKey(const Key('fuel-liters')), '41,3');
    final fullSwitch = find.byKey(const Key('fuel-full'));
    await tester.ensureVisible(fullSwitch);
    await tester.pumpAndSettle();
    await tester.tap(fullSwitch);
    await tester.pumpAndSettle();

    final memoField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Memo').first,
    );
    expect(memoField.controller!.text, 'd=100650 l=41.3 full');
  });

  testWidgets('editing a fuel transaction populates the fields', (
    tester,
  ) async {
    final existing = Transaction(
      id: 5,
      amount: 70,
      fromAccountId: 1,
      categoryId: 9,
      transactionDate: DateTime(2026, 8),
      memo: 'd=100650 l=41.3 full Aral',
    );
    await pumpDialog(tester, transaction: existing);

    expect(find.byKey(const Key('fuel-odometer')), findsOneWidget);
    final odometer = tester.widget<TextFormField>(
      find.byKey(const Key('fuel-odometer')),
    );
    final liters = tester.widget<TextFormField>(
      find.byKey(const Key('fuel-liters')),
    );
    expect(odometer.controller!.text, '100650');
    expect(liters.controller!.text, '41.3');
    final fullSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('fuel-full')),
    );
    expect(fullSwitch.value, isTrue);
  });

  testWidgets('typing memo reparses into fields', (tester) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Memo').first,
      'd=100700 l=30',
    );
    await tester.pumpAndSettle();

    final odometer = tester.widget<TextFormField>(
      find.byKey(const Key('fuel-odometer')),
    );
    final liters = tester.widget<TextFormField>(
      find.byKey(const Key('fuel-liters')),
    );
    expect(odometer.controller!.text, '100700');
    expect(liters.controller!.text, '30');
  });

  testWidgets('non-increasing odometer shows warning', (tester) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');

    await tester.enterText(find.byKey(const Key('fuel-odometer')), '99000');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('not higher than the last reading'),
      findsOneWidget,
    );
  });

  testWidgets('plausible full-tank entry shows distance and consumption', (
    tester,
  ) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');

    await tester.enterText(find.byKey(const Key('fuel-odometer')), '100340');
    await tester.enterText(find.byKey(const Key('fuel-liters')), '41,3');
    final fullSwitch = find.byKey(const Key('fuel-full'));
    await tester.ensureVisible(fullSwitch);
    await tester.pumpAndSettle();
    await tester.tap(fullSwitch);
    await tester.pumpAndSettle();

    // 340 km since last, 41.3 / 340 * 100 = 12.1 L/100km
    expect(find.textContaining('340 km since last'), findsOneWidget);
    expect(find.textContaining('12.1'), findsOneWidget);
  });

  testWidgets('implausible liters shows field warning', (tester) async {
    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');

    await tester.enterText(find.byKey(const Key('fuel-liters')), '413');
    await tester.pumpAndSettle();

    expect(find.text('Implausible liters value'), findsOneWidget);
  });

  testWidgets(
    'editing the newest fill-up compares against the prior reading, not '
    'itself',
    (tester) async {
      // Two readings in the category: the transaction being edited is the
      // newest one (2026-08-01, d=100650). The baseline for the warning
      // must be the *older* reading (2026-07-01, d=100000) — comparing
      // against itself would give distance 0 and a false warning.
      when(
        () => vehiclesRepo.getReport(
          categoryId: 9,
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer(
        (_) async => VehicleReport(
          entries: [
            FuelEntry(date: DateTime(2026, 8), odometer: 100650, liters: 40),
            FuelEntry(date: DateTime(2026, 7), odometer: 100000, liters: 38),
          ],
        ),
      );

      final existing = Transaction(
        id: 5,
        amount: 70,
        fromAccountId: 1,
        categoryId: 9,
        transactionDate: DateTime(2026, 8),
        memo: 'd=100650 l=40',
      );
      await pumpDialog(tester, transaction: existing);

      expect(
        find.textContaining('not higher than'),
        findsNothing,
      );
      expect(find.textContaining('650 km since last'), findsOneWidget);
    },
  );

  testWidgets('empty fuel fields on save show SnackBar, save proceeds', (
    tester,
  ) async {
    when(() => txRepo.save(any())).thenAnswer(
      (invocation) async =>
          invocation.positionalArguments.single as Transaction,
    );

    await pumpDialog(tester);
    await selectCategory(tester, 'Tanken');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '60',
    );
    // EXPENSE requires a From Account.
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giro').last);
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pump(); // SnackBar appears before the dialog pops

    expect(
      find.textContaining('will not appear in the vehicle report'),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    verify(() => txRepo.save(any())).called(1);
  });
}
