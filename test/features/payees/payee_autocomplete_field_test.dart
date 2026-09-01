import 'package:cuentimobile/features/payees/domain/payee.dart';
import 'package:cuentimobile/features/payees/ui/payee_autocomplete_field.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _payees = [
  Payee(id: 1, name: 'Aral Tankstelle'),
  Payee(id: 2, name: 'Aldi Süd'),
  Payee(id: 3, name: 'Rewe Markt'),
];

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Future<void> pumpField(
    WidgetTester tester, {
    List<Payee> payees = _payees,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(
          body: PayeeAutocompleteField(
            controller: controller,
            payees: payees,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextFormField), text);
    await tester.pumpAndSettle();
  }

  testWidgets('suggests payees matching what has been typed', (tester) async {
    await pumpField(tester);
    await type(tester, 'al');

    expect(find.text('Aral Tankstelle'), findsOneWidget);
    expect(find.text('Aldi Süd'), findsOneWidget);
    expect(find.text('Rewe Markt'), findsNothing);
  });

  testWidgets('matches tokens in any order', (tester) async {
    await pumpField(tester);
    await type(tester, 'tank aral');

    expect(find.text('Aral Tankstelle'), findsOneWidget);
  });

  testWidgets('shows nothing before the user types', (tester) async {
    await pumpField(tester);

    expect(find.text('Rewe Markt'), findsNothing);
  });

  testWidgets('picking a suggestion fills the field', (tester) async {
    await pumpField(tester);
    await type(tester, 'rewe');
    await tester.tap(find.text('Rewe Markt'));
    await tester.pumpAndSettle();

    expect(controller.text, 'Rewe Markt');
  });

  testWidgets('keeps free text that matches no known payee', (tester) async {
    await pumpField(tester);
    await type(tester, 'Some New Shop');

    expect(controller.text, 'Some New Shop');
    expect(find.text('Aral Tankstelle'), findsNothing);
  });

  testWidgets('starts from the value already in the controller', (
    tester,
  ) async {
    controller.text = 'Aldi Süd';
    await pumpField(tester);

    expect(find.widgetWithText(TextFormField, 'Aldi Süd'), findsOneWidget);
  });
}
