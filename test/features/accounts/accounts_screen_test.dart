import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_screen.dart';
import 'package:cuentimobile/features/currencies/data/currencies_repository.dart';
import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountsRepository extends Mock implements AccountsRepository {}

class MockCurrenciesRepository extends Mock implements CurrenciesRepository {}

void main() {
  late MockAccountsRepository accountsRepo;
  late MockCurrenciesRepository currenciesRepo;

  setUp(() {
    accountsRepo = MockAccountsRepository();
    currenciesRepo = MockCurrenciesRepository();

    when(() => accountsRepo.getAll()).thenAnswer(
      (_) async => [
        const Account(id: 1, accountName: 'Giro', currency: 'EUR'),
      ],
    );
    when(() => currenciesRepo.getAll()).thenAnswer(
      (_) async => [const Currency(id: 1, code: 'EUR', name: 'Euro')],
    );
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsRepositoryProvider.overrideWithValue(accountsRepo),
          currenciesRepositoryProvider.overrideWithValue(currenciesRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AccountsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping an account card opens the edit sheet', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Giro'), findsOneWidget);

    await tester.tap(find.text('Giro'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Account'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}
