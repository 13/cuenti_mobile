import 'dart:convert';
import 'dart:io';

import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockAccountsRepository extends Mock implements AccountsRepository {}

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

/// Renders TransactionsScreen against the REAL 50-transaction envelope
/// captured from a live v2.10.0 backend (mixed types, transfers, splits,
/// null payees/categories) — the field-shape coverage the synthetic tests
/// lack.
void main() {
  setUpAll(() => registerFallbackValue(const TransactionFilter()));

  testWidgets('renders full real dataset without exceptions', (tester) async {
    final raw = File(
      'test/fixtures/real_tx_envelope.json',
    ).readAsStringSync();
    final page = TransactionPage.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    final txRepo = MockTransactionsRepository();
    final accountsRepo = MockAccountsRepository();
    final categoriesRepo = MockCategoriesRepository();
    when(
      () => txRepo.getPage(
        filter: any(named: 'filter'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => page);
    when(
      () => accountsRepo.getAll(),
    ).thenAnswer((_) async => [const Account(id: 1, accountName: 'Giro')]);
    when(
      () => categoriesRepo.getAll(type: any(named: 'type')),
    ).thenAnswer((_) async => []);

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

    expect(tester.takeException(), isNull);
    // First (newest) real transaction renders.
    expect(find.textContaining('Sparrate'), findsWidgets);

    // Scroll through the whole list — every tile builds.
    final list = find.byType(CustomScrollView);
    for (var i = 0; i < 12; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    // Flush the row stagger-in timers so none are left pending at teardown.
    await tester.pumpAndSettle();
  });
}
