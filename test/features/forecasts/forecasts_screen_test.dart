import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/forecasts/data/forecasts_repository.dart';
import 'package:cuentimobile/features/forecasts/domain/forecast_data.dart';
import 'package:cuentimobile/features/forecasts/ui/forecasts_screen.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockForecastsRepository extends Mock implements ForecastsRepository {}

ForecastData _forecast(int year) => ForecastData(
  year: year,
  totalIncome: 36000,
  totalExpense: 24000,
  netForecast: 12000,
  months: [
    MonthForecast(month: '$year-01', income: 3000, expense: 2000, net: 1000),
    MonthForecast(month: '$year-02', income: 3000, expense: 2000, net: 1000),
  ],
);

void main() {
  late MockForecastsRepository repo;
  final thisYear = DateTime.now().year;

  setUp(() {
    repo = MockForecastsRepository();
    when(
      () => repo.getForecast(any()),
    ).thenAnswer(
      (invocation) async => _forecast(
        invocation.positionalArguments.single as int,
      ),
    );
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [forecastsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: const Scaffold(body: ForecastsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the current year', (tester) async {
    await pumpScreen(tester);

    verify(() => repo.getForecast(thisYear)).called(1);
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '$thisYear'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('offers last year through two years ahead', (tester) async {
    await pumpScreen(tester);

    for (final year in [
      thisYear - 1,
      thisYear,
      thisYear + 1,
      thisYear + 2,
    ]) {
      expect(find.widgetWithText(ChoiceChip, '$year'), findsOneWidget);
    }
  });

  testWidgets('picking another year refetches for it', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, '${thisYear + 1}'));
    await tester.pumpAndSettle();

    verify(() => repo.getForecast(thisYear + 1)).called(1);
  });

  testWidgets('shows the empty state for a year with no forecast', (
    tester,
  ) async {
    when(
      () => repo.getForecast(any()),
    ).thenAnswer((_) async => ForecastData(year: thisYear));

    await pumpScreen(tester);

    expect(find.text('No data'), findsWidgets);
  });
}
