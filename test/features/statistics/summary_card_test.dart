import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/summary_card.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    double income = 3200,
    double expense = 1800,
    double width = 360,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: Scaffold(
            body: SummaryCard(
              income: income,
              expense: expense,
              balance: income - expense,
              currency: 'EUR',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the labels are translated, not hardcoded English', (
    tester,
  ) async {
    await pumpCard(tester, locale: const Locale('de'));

    expect(find.text('Saldo'), findsOneWidget);
    expect(find.text('Sparquote'), findsOneWidget);
    expect(find.text('Balance'), findsNothing);
  });

  testWidgets('shows the savings rate alongside the three totals', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);
    expect(find.textContaining('43,8'), findsOneWidget);
  });

  testWidgets('a month with no income shows a dash, not a rate invented '
      'from a division by zero', (tester) async {
    await pumpCard(tester, income: 0, expense: 250);

    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('six-figure amounts on a narrow phone do not overflow', (
    tester,
  ) async {
    await pumpCard(tester, income: 987654.32, expense: 876543.21, width: 320);

    expect(
      tester.takeException(),
      isNull,
      reason:
          'a RenderFlex overflow throws in tests, and this is exactly '
          'the case that used to run off the line',
    );
  });
}
