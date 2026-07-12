import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/widgets/stat_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: SizedBox(width: 200, child: child)),
  ),
);

void main() {
  testWidgets('horizontal (default) renders label + value on one line with '
      'center-aligned FittedBox', (tester) async {
    await tester.pumpWidget(
      host(
        const StatChip(
          icon: Icons.account_balance_wallet,
          label: 'Cash',
          value: '1.234,56 EUR',
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('1.234,56 EUR'), findsOneWidget);

    // The value's FittedBox keeps its original (default) center alignment
    // in the horizontal layout — no left-align behavior change.
    final fittedBox = tester.widget<FittedBox>(
      find.ancestor(
        of: find.text('1.234,56 EUR'),
        matching: find.byType(FittedBox),
      ),
    );
    expect(fittedBox.alignment, Alignment.center);
  });

  testWidgets('vertical stacks label over a left-aligned full-width value',
      (tester) async {
    await tester.pumpWidget(
      host(
        const StatChip(
          icon: Icons.trending_up,
          label: 'Portfolio',
          value: '9.876,54 EUR',
          direction: Axis.vertical,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('9.876,54 EUR'), findsOneWidget);

    final fittedBox = tester.widget<FittedBox>(
      find.ancestor(
        of: find.text('9.876,54 EUR'),
        matching: find.byType(FittedBox),
      ),
    );
    expect(fittedBox.alignment, Alignment.centerLeft);

    // Value sits below the label row, not beside it.
    final labelY = tester.getTopLeft(find.text('Portfolio')).dy;
    final valueY = tester.getTopLeft(find.text('9.876,54 EUR')).dy;
    expect(valueY, greaterThan(labelY));
  });
}
