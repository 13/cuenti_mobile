import 'dart:async';

import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/dashboard/data/dashboard_repository.dart';
import 'package:cuentimobile/features/dashboard/domain/asset_performance.dart';
import 'package:cuentimobile/features/dashboard/domain/dashboard_data.dart';
import 'package:cuentimobile/features/dashboard/ui/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late MockDashboardRepository dashboardRepo;

  setUp(() {
    dashboardRepo = MockDashboardRepository();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(dashboardRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          // DashboardScreen is always mounted inside ShellScreen's Scaffold
          // in the real app; wrap it here too so the themed DefaultTextStyle
          // (set by Material) is present, matching production.
          home: const Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('displays net worth hero card with label and amount', (
    tester,
  ) async {
    when(
      () => dashboardRepo.load(),
    ).thenAnswer(
      (_) async => DashboardData(
        availableCash: 500,
        portfolioValue: 1000,
        netWorth: 1500,
        accounts: [
          const Account(
            id: 1,
            accountName: 'Main Bank',
            accountType: 'BANK',
            balance: 1500,
          ),
        ],
        assetPerformance: [
          const AssetPerformance(
            assetName: 'Apple Stock',
            assetSymbol: 'AAPL',
            totalUnits: 10,
            totalCost: 900,
            currentValue: 1000,
            currentPrice: 100,
            gainLoss: 100,
            gainLossPercent: 11.11,
          ),
        ],
      ),
    );

    await pumpScreen(tester);

    expect(find.text('Net worth'), findsOneWidget);
    expect(find.text('1.500,00 EUR'), findsWidgets);
    // Cash stat chip keeps the currency suffix.
    expect(find.text('500,00 EUR'), findsOneWidget);
    expect(find.textContaining('EUR'), findsWidgets);
    expect(find.text('Main Bank'), findsOneWidget);
  });

  testWidgets('shows loading state with skeleton loaders', (tester) async {
    final completer = Completer<DashboardData>();
    when(
      () => dashboardRepo.load(),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(dashboardRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          // DashboardScreen is always mounted inside ShellScreen's Scaffold
          // in the real app; wrap it here too so the themed DefaultTextStyle
          // (set by Material) is present, matching production.
          home: const Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SkeletonLoader), findsWidgets);
  });

  testWidgets('error state shows retry button', (tester) async {
    when(
      () => dashboardRepo.load(),
    ).thenThrow(Exception('Network error'));

    await pumpScreen(tester);

    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
