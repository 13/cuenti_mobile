import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/income_expense_donut.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _PrivateMode extends PrivacyMode {
  @override
  bool build() => true;
}

void main() {
  Future<void> pumpDonut(
    WidgetTester tester, {
    double income = 1200,
    double expense = 800,
    bool privacy = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (privacy) privacyModeProvider.overrideWith(_PrivateMode.new),
        ],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: IncomeExpenseDonut(income: income, expense: expense),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  PieChartData dataOf(WidgetTester tester) =>
      tester.widget<PieChart>(find.byType(PieChart)).data;

  /// Drives fl_chart's touch callback the way a completed tap does, since a
  /// synthetic tap on the canvas cannot say which slice it landed on.
  void tapSlice(WidgetTester tester, int index) {
    dataOf(tester).pieTouchData.touchCallback!(
      FlTapUpEvent(TapUpDetails(kind: PointerDeviceKind.touch)),
      PieTouchResponse(
        touchLocation: Offset.zero,
        touchedSection: PieTouchedSection(
          dataOf(tester).sections[index],
          index,
          0,
          0,
        ),
      ),
    );
  }

  testWidgets('responds to touch at all', (tester) async {
    await pumpDonut(tester);

    expect(dataOf(tester).pieTouchData.touchCallback, isNotNull);
  });

  testWidgets('tapping a slice names it and shows its figure in the middle', (
    tester,
  ) async {
    await pumpDonut(tester);

    tapSlice(tester, 0);
    await tester.pumpAndSettle();

    expect(find.text('Income'), findsWidgets);
    expect(find.textContaining('1.200'), findsOneWidget);
  });

  testWidgets('tapping the other slice switches to it', (tester) async {
    await pumpDonut(tester);

    tapSlice(tester, 1);
    await tester.pumpAndSettle();

    expect(find.textContaining('800'), findsOneWidget);
  });

  testWidgets('tapping the same slice again clears the selection', (
    tester,
  ) async {
    await pumpDonut(tester);

    tapSlice(tester, 0);
    await tester.pumpAndSettle();
    tapSlice(tester, 0);
    await tester.pumpAndSettle();

    expect(find.textContaining('1.200'), findsNothing);
  });

  testWidgets('the touched slice is drawn larger, so it is clear which one '
      'the figure belongs to', (tester) async {
    await pumpDonut(tester);
    final before = dataOf(tester).sections[0].radius;

    tapSlice(tester, 0);
    await tester.pumpAndSettle();

    expect(dataOf(tester).sections[0].radius, greaterThan(before));
    expect(dataOf(tester).sections[1].radius, before);
  });

  testWidgets('privacy mode hides the figure in the middle too, or the '
      'tooltip would give away what the slice labels are covering', (
    tester,
  ) async {
    await pumpDonut(tester, privacy: true);

    tapSlice(tester, 0);
    await tester.pumpAndSettle();

    expect(find.textContaining('1.200'), findsNothing);
    expect(find.text('Income'), findsWidgets);
  });

  testWidgets('says there is no data rather than drawing an empty ring', (
    tester,
  ) async {
    await pumpDonut(tester, income: 0, expense: 0);

    expect(find.byType(PieChart), findsNothing);
    expect(find.text('No data'), findsOneWidget);
  });
}
