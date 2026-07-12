import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/amount_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('expense is colored and signed', (tester) async {
    await tester.pumpWidget(
      host(const AmountText(12.5, type: 'EXPENSE', signed: true)),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, startsWith('−'));
    expect(text.style!.color, CuentiColors.light.expense);
    expect(
      text.style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('income signed plus, transfer neutral', (tester) async {
    await tester.pumpWidget(
      host(const AmountText(3, type: 'INCOME', signed: true)),
    );
    expect(tester.widget<Text>(find.byType(Text)).data, startsWith('+'));
    await tester.pumpWidget(
      host(const AmountText(3, type: 'TRANSFER', signed: true)),
    );
    expect(
      tester.widget<Text>(find.byType(Text)).style!.color,
      CuentiColors.light.transfer,
    );
  });

  testWidgets('untyped amount uses ambient style color', (tester) async {
    await tester.pumpWidget(host(const AmountText(99)));
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, isNot(startsWith('−')));
  });
}
