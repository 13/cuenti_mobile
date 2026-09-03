import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/currencies/data/currencies_repository.dart';
import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:cuentimobile/features/vehicles/domain/vehicle_report.dart';
import 'package:cuentimobile/features/vehicles/ui/widgets/vehicle_report_parts.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// AmountText reads the currency list; an empty one keeps a bare pump from
/// leaving a request in flight at teardown.
class _Currencies implements CurrenciesRepository {
  @override
  Future<List<Currency>> getAll() async => const [
    Currency(
      id: 1,
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currenciesRepositoryProvider.overrideWithValue(_Currencies()),
        ],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('VehicleStatCards', () {
    testWidgets('writes the total the way its currency does', (tester) async {
      await pump(
        tester,
        const VehicleStatCards(report: VehicleReport(totalCost: 1234.5)),
      );

      expect(find.textContaining('1.234,50'), findsOneWidget);
    });

    testWidgets('keeps three decimals on the price per litre', (tester) async {
      await pump(
        tester,
        const VehicleStatCards(report: VehicleReport(avgPricePerLiter: 1.859)),
      );

      expect(find.textContaining('1,859'), findsOneWidget);
    });

    testWidgets('an empty report shows dashes rather than zeroes, which '
        'would read as a real figure', (tester) async {
      await pump(tester, const VehicleStatCards(report: VehicleReport()));

      expect(find.text('—'), findsWidgets);
    });
  });

  group('ConsumptionChart', () {
    testWidgets('says so when there is nothing to plot', (tester) async {
      await pump(tester, const ConsumptionChart(entries: []));

      expect(tester.takeException(), isNull);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('a single fill-up does not break the chart', (tester) async {
      await pump(
        tester,
        ConsumptionChart(
          entries: [
            FuelEntry(
              date: DateTime(2026, 3),
              consumption: 6.2,
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('FuelEntriesList', () {
    final entries = <FuelEntry>[
      FuelEntry(
        date: DateTime(2026, 3),
        amount: 72.4,
        consumption: 6.2,
      ),
      FuelEntry(date: DateTime(2026, 2), amount: 65),
    ];

    testWidgets('lists a row per fill-up', (tester) async {
      await pump(tester, FuelEntriesList(entries: entries, currency: 'EUR'));

      expect(find.textContaining('72,40'), findsOneWidget);
      expect(find.textContaining('65,00'), findsOneWidget);
    });

    testWidgets('an entry without a consumption figure still renders', (
      tester,
    ) async {
      await pump(
        tester,
        FuelEntriesList(entries: [entries.last], currency: 'EUR'),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('no entries renders nothing rather than an empty frame', (
      tester,
    ) async {
      await pump(tester, const FuelEntriesList(entries: [], currency: 'EUR'));

      expect(tester.takeException(), isNull);
    });
  });
}
