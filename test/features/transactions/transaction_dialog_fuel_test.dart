import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/ui/transaction_dialog.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:cuentimobile/features/vehicles/data/vehicles_repository.dart';
import 'package:cuentimobile/features/vehicles/domain/vehicle_report.dart';
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
      Transaction(amount: 0, transactionDate: DateTime(2026, 1, 1)),
    );
  });

  late MockTransactionsRepository txRepo;
  late MockAccountsRepository accountsRepo;
  late MockCategoriesRepository categoriesRepo;
  late MockVehiclesRepository vehiclesRepo;

  setUp(() {
    txRepo = MockTransactionsRepository();
    accountsRepo = MockAccountsRepository();
    categoriesRepo = MockCategoriesRepository();
    vehiclesRepo = MockVehiclesRepository();

    when(
      () => accountsRepo.getAll(),
    ).thenAnswer((_) async => [const Account(id: 1, accountName: 'Giro')]);
    when(() => categoriesRepo.getAll(type: any(named: 'type'))).thenAnswer(
      (_) async => const [
        Category(id: 9, name: 'Tanken', type: 'EXPENSE'),
        Category(id: 2, name: 'Food', type: 'EXPENSE'),
      ],
    );
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
          FuelEntry(date: DateTime(2026, 7, 1), odometer: 100000, liters: 40),
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
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(
                  transactionsControllerProvider(
                    filter: const TransactionFilter(),
                  ),
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
    final dropdown = find.byType(DropdownButtonFormField<int?>).first;
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
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
      type: 'EXPENSE',
      amount: 70,
      fromAccountId: 1,
      categoryId: 9,
      transactionDate: DateTime(2026, 8, 1),
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
}
