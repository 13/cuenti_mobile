import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/widgets/entity_edit_sheet.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Opens the sheet over a bare page, with whatever fields and gate the
  /// test wants.
  Future<void> pumpSheet(
    WidgetTester tester, {
    required TextEditingController name,
    bool Function()? canSave,
    Future<void> Function()? onSave,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showEntityEditSheet(
                context: context,
                title: 'Edit thing',
                successMessage: 'Thing saved',
                canSave: canSave,
                fields: (context, rebuild) => [
                  TextField(
                    controller: name,
                    onChanged: (_) => rebuild(),
                  ),
                ],
                onSave: onSave ?? () async {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  VoidCallback? saveButton(WidgetTester tester) => tester
      .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
      .onPressed;

  testWidgets('Save is available when no gate is given', (tester) async {
    await pumpSheet(tester, name: TextEditingController());

    expect(saveButton(tester), isNotNull);
  });

  testWidgets('a gate that refuses keeps Save out of reach', (tester) async {
    await pumpSheet(
      tester,
      name: TextEditingController(),
      canSave: () => false,
    );

    expect(saveButton(tester), isNull);
  });

  testWidgets('the gate is asked again as the fields change, so filling the '
      'form in enables Save', (tester) async {
    final name = TextEditingController();

    await pumpSheet(
      tester,
      name: name,
      canSave: () => name.text.trim().isNotEmpty,
    );
    expect(saveButton(tester), isNull);

    await tester.enterText(find.byType(TextField), 'Something');
    await tester.pumpAndSettle();

    expect(saveButton(tester), isNotNull);
  });

  testWidgets('a failure that is not an ApiException still reports and lets '
      'the user try again', (tester) async {
    await pumpSheet(
      tester,
      name: TextEditingController(),
      onSave: () async => throw Exception('boom'),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('An error occurred'), findsOneWidget);
    expect(saveButton(tester), isNotNull);
  });

  testWidgets('a successful save closes the sheet and confirms', (
    tester,
  ) async {
    await pumpSheet(tester, name: TextEditingController());

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Edit thing'), findsNothing);
    expect(find.text('Thing saved'), findsOneWidget);
  });
}
