import 'package:cuentimobile/core/widgets/search_create_sheet.dart';
import 'package:cuentimobile/features/payees/domain/payee.dart';
import 'package:cuentimobile/features/payees/ui/payee_picker_field.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _payees = [
  Payee(id: 1, name: 'Aral Tankstelle'),
  Payee(id: 2, name: 'Rewe'),
  Payee(id: 3, name: 'Shell'),
];

Finder inSheet(String text) => find.descendant(
  of: find.byType(SearchCreateSheet<Payee>),
  matching: find.text(text),
);

void main() {
  /// Pumps the field over a controller and returns it, so a test can read
  /// what the field put in it.
  Future<TextEditingController> pumpField(
    WidgetTester tester, {
    String initial = '',
    Future<bool> Function(String typed)? onCreate,
  }) async {
    final controller = TextEditingController(text: initial);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(
          body: PayeePickerField(
            controller: controller,
            payees: _payees,
            onCreate: onCreate,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byType(PayeePickerField));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the payee already on the transaction', (tester) async {
    await pumpField(tester, initial: 'Rewe');

    expect(find.text('Rewe'), findsOneWidget);
  });

  testWidgets('opens a sheet listing the payees the account knows', (
    tester,
  ) async {
    await pumpField(tester);
    await openSheet(tester);

    expect(inSheet('Aral Tankstelle'), findsOneWidget);
    expect(inSheet('Rewe'), findsOneWidget);
  });

  testWidgets('typing filters the list', (tester) async {
    await pumpField(tester);
    await openSheet(tester);

    await tester.enterText(find.byType(TextField).last, 'ta');
    await tester.pumpAndSettle();

    expect(inSheet('Aral Tankstelle'), findsOneWidget);
    expect(inSheet('Rewe'), findsNothing);
  });

  testWidgets('picking one fills the field and closes the sheet', (
    tester,
  ) async {
    final controller = await pumpField(tester);
    await openSheet(tester);

    await tester.tap(inSheet('Shell'));
    await tester.pumpAndSettle();

    expect(controller.text, 'Shell');
    expect(find.byType(SearchCreateSheet<Payee>), findsNothing);
  });

  testWidgets('clearing empties the field, since a transaction need not '
      'name a payee', (tester) async {
    final controller = await pumpField(tester, initial: 'Rewe');
    await openSheet(tester);

    await tester.tap(inSheet('None'));
    await tester.pumpAndSettle();

    expect(controller.text, isEmpty);
  });

  group('a payee that is not on the list yet', () {
    testWidgets('offers to create it', (tester) async {
      await pumpField(tester, onCreate: (_) async => true);
      await openSheet(tester);

      await tester.enterText(find.byType(TextField).last, 'Bäckerei Süß');
      await tester.pumpAndSettle();

      expect(inSheet('Create "Bäckerei Süß"'), findsOneWidget);
    });

    testWidgets('offers nothing for one already known', (tester) async {
      await pumpField(tester, onCreate: (_) async => true);
      await openSheet(tester);

      await tester.enterText(find.byType(TextField).last, 'Rewe');
      await tester.pumpAndSettle();

      expect(find.textContaining('Create'), findsNothing);
    });

    testWidgets('creating saves it and fills the field', (tester) async {
      final created = <String>[];
      final controller = await pumpField(
        tester,
        onCreate: (name) async {
          created.add(name);
          return true;
        },
      );
      await openSheet(tester);
      await tester.enterText(find.byType(TextField).last, 'Bäckerei Süß');
      await tester.pumpAndSettle();
      await tester.tap(inSheet('Create "Bäckerei Süß"'));
      await tester.pumpAndSettle();

      expect(created, ['Bäckerei Süß']);
      expect(controller.text, 'Bäckerei Süß');
    });

    testWidgets(
      'a create the server refuses still puts the name on the transaction: '
      'the payee is a plain string there, so losing the record must not '
      'lose what was typed',
      (tester) async {
        final controller = await pumpField(
          tester,
          onCreate: (_) async => false,
        );
        await openSheet(tester);
        await tester.enterText(find.byType(TextField).last, 'Bäckerei Süß');
        await tester.pumpAndSettle();
        await tester.tap(inSheet('Create "Bäckerei Süß"'));
        await tester.pumpAndSettle();

        expect(controller.text, 'Bäckerei Süß');
        expect(find.byType(SearchCreateSheet<Payee>), findsNothing);
      },
    );
  });
}
