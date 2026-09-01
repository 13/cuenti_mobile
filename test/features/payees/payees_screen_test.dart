import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/payees/data/payees_repository.dart';
import 'package:cuentimobile/features/payees/domain/payee.dart';
import 'package:cuentimobile/features/payees/ui/payees_screen.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPayeesRepository extends Mock implements PayeesRepository {}

void main() {
  setUpAll(
    () => registerFallbackValue(const Payee(id: 1, name: 'Aral Tankstelle')),
  );

  late MockPayeesRepository repo;

  setUp(() {
    repo = MockPayeesRepository();
    when(
      () => repo.getAll(),
    ).thenAnswer((_) async => [const Payee(id: 1, name: 'Aral Tankstelle')]);
  });

  Future<void> pumpScreen(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [payeesRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: const PayeesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists what the server returned', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Aral Tankstelle'), findsOneWidget);
  });

  testWidgets('offers to add one when there are none', (tester) async {
    when(() => repo.getAll()).thenAnswer((_) async => []);

    await pumpScreen(tester);

    expect(find.text('No payees yet'), findsOneWidget);
  });

  testWidgets('a swipe asks before deleting and cancelling keeps the row', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.drag(find.text('Aral Tankstelle'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete Payee?'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.delete(any()));
    expect(find.text('Aral Tankstelle'), findsOneWidget);
  });

  testWidgets('confirming a swipe deletes it', (tester) async {
    when(() => repo.delete(any())).thenAnswer((_) async {});

    await pumpScreen(tester);

    await tester.drag(find.text('Aral Tankstelle'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => repo.delete(1)).called(1);
  });

  testWidgets('the FAB opens the add sheet', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('saving confirms it happened', (tester) async {
    when(
      () => repo.save(any()),
    ).thenAnswer((_) async => const Payee(id: 1, name: 'Aral Tankstelle'));

    await pumpScreen(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Something');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Payee saved'), findsOneWidget);
  });

  testWidgets('the confirmation speaks the chosen language', (tester) async {
    when(
      () => repo.save(any()),
    ).thenAnswer((_) async => const Payee(id: 1, name: 'Aral Tankstelle'));

    await pumpScreen(tester, locale: const Locale('de'));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Something');
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Empfänger gespeichert'), findsOneWidget);
  });
}
