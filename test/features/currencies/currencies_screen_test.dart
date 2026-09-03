import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/currencies/data/currencies_repository.dart';
import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:cuentimobile/features/currencies/ui/currencies_screen.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCurrenciesRepository extends Mock implements CurrenciesRepository {}

void main() {
  late MockCurrenciesRepository repo;

  setUp(() {
    repo = MockCurrenciesRepository();
    when(() => repo.getAll()).thenAnswer(
      (_) async => [const Currency(id: 1, code: 'EUR', name: 'Euro')],
    );
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currenciesRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: const CurrenciesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists what the server returned', (tester) async {
    await pumpScreen(tester);

    expect(find.text('EUR - Euro'), findsOneWidget);
  });

  testWidgets('offers to add one when there are none', (tester) async {
    when(() => repo.getAll()).thenAnswer((_) async => []);

    await pumpScreen(tester);

    expect(find.text('No currencies yet'), findsOneWidget);
  });

  testWidgets('a swipe asks before deleting and cancelling keeps the row', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.drag(find.text('EUR - Euro'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete Currency?'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.delete(any()));
    expect(find.text('EUR - Euro'), findsOneWidget);
  });

  testWidgets('confirming a swipe deletes it', (tester) async {
    when(() => repo.delete(any())).thenAnswer((_) async {});

    await pumpScreen(tester);

    await tester.drag(find.text('EUR - Euro'), const Offset(-500, 0));
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

  group('search and sort', () {
    const many = [
      Currency(id: 1, code: 'USD', name: 'US Dollar', symbol: r'$'),
      Currency(id: 2, code: 'EUR', name: 'Euro', symbol: '€'),
      Currency(id: 3, code: 'CHF', name: 'Swiss Franc', symbol: 'Fr'),
    ];

    double rowY(WidgetTester tester, String text) =>
        tester.getTopLeft(find.text(text)).dy;

    testWidgets('searches the code', (tester) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'chf');
      await tester.pumpAndSettle();

      expect(find.text('CHF - Swiss Franc'), findsOneWidget);
      expect(find.text('EUR - Euro'), findsNothing);
    });

    testWidgets('searches the name too, not just the code', (tester) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'franc');
      await tester.pumpAndSettle();

      expect(find.text('CHF - Swiss Franc'), findsOneWidget);
      expect(find.text('USD - US Dollar'), findsNothing);
    });

    testWidgets('a search matching nothing offers to clear it', (tester) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No currencies match'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('EUR - Euro'), findsOneWidget);
    });

    testWidgets('the code chip sorts by code', (tester) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Code'));
      await tester.pumpAndSettle();

      expect(
        rowY(tester, 'CHF - Swiss Franc'),
        lessThan(rowY(tester, 'EUR - Euro')),
      );
      expect(
        rowY(tester, 'EUR - Euro'),
        lessThan(rowY(tester, 'USD - US Dollar')),
      );
    });

    testWidgets('the name chip sorts by name, which is a different order', (
      tester,
    ) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Name'));
      await tester.pumpAndSettle();

      expect(
        rowY(tester, 'EUR - Euro'),
        lessThan(rowY(tester, 'CHF - Swiss Franc')),
      );
    });
  });
}
