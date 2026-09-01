import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/widgets/privacy_blur.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/statistics/data/statistics_repository.dart';
import 'package:cuentimobile/features/statistics/domain/statistics_data.dart';
import 'package:cuentimobile/features/statistics/ui/statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStatisticsRepository extends Mock implements StatisticsRepository {}

class MockAccountsRepository extends Mock implements AccountsRepository {}

const _stats = StatisticsData(
  totalIncome: 3200,
  totalExpense: 1800,
  balance: 1400,
  transactionCount: 42,
  expenseByCategory: {'Food': 1200, 'Transport': 600},
  incomeByCategory: {'Salary': 3200},
);

void main() {
  late MockStatisticsRepository statsRepo;
  late MockAccountsRepository accountsRepo;

  setUp(() {
    statsRepo = MockStatisticsRepository();
    accountsRepo = MockAccountsRepository();
    when(
      () => accountsRepo.getAll(),
    ).thenAnswer((_) async => [const Account(id: 1, accountName: 'Giro')]);
    when(
      () => statsRepo.load(
        start: any(named: 'start'),
        end: any(named: 'end'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) async => _stats);
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool privacyMode = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statisticsRepositoryProvider.overrideWithValue(statsRepo),
          accountsRepositoryProvider.overrideWithValue(accountsRepo),
          if (privacyMode) privacyModeProvider.overrideWith(_AlwaysPrivate.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: StatisticsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the three analysis tabs', (tester) async {
    await pumpScreen(tester);

    // "Income"/"Expense" also appear as summary labels, so scope to the bar.
    Finder tab(String label) =>
        find.descendant(of: find.byType(TabBar), matching: find.text(label));
    expect(tab('Overview'), findsOneWidget);
    expect(tab('Income'), findsOneWidget);
    expect(tab('Expense'), findsOneWidget);
  });

  testWidgets('requests the year to date by default', (tester) async {
    await pumpScreen(tester);

    final start =
        verify(
              () => statsRepo.load(
                start: captureAny(named: 'start'),
                end: any(named: 'end'),
                accountId: any(named: 'accountId'),
              ),
            ).captured.first
            as String;
    expect(start, '${DateTime.now().year}-01-01');
  });

  testWidgets('shows the empty state when the period has no transactions', (
    tester,
  ) async {
    when(
      () => statsRepo.load(
        start: any(named: 'start'),
        end: any(named: 'end'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer(
      (_) async =>
          const StatisticsData(totalIncome: 0, totalExpense: 0, balance: 0),
    );

    await pumpScreen(tester);

    expect(find.text('No data'), findsWidgets);
  });

  testWidgets('blurs the figures when privacy mode is on', (tester) async {
    await pumpScreen(tester, privacyMode: true);

    expect(
      find.byType(PrivacyBlur),
      findsWidgets,
      reason: 'amounts stay in the tree but must be visually obscured',
    );
    expect(
      tester.widgetList<ImageFiltered>(find.byType(ImageFiltered)),
      isNotEmpty,
    );
  });
}

class _AlwaysPrivate extends PrivacyMode {
  @override
  bool build() => true;
}
