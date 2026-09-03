import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_screen.dart';
import 'package:cuentimobile/features/currencies/data/currencies_repository.dart';
import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountsRepository extends Mock implements AccountsRepository {}

class MockCurrenciesRepository extends Mock implements CurrenciesRepository {}

void main() {
  setUpAll(
    () => registerFallbackValue(const Account(accountName: 'fallback')),
  );

  late MockAccountsRepository accountsRepo;
  late MockCurrenciesRepository currenciesRepo;

  setUp(() {
    accountsRepo = MockAccountsRepository();
    currenciesRepo = MockCurrenciesRepository();

    when(() => accountsRepo.getAll()).thenAnswer(
      (_) async => [
        const Account(id: 1, accountName: 'Giro'),
      ],
    );
    when(() => currenciesRepo.getAll()).thenAnswer(
      (_) async => [const Currency(id: 1, code: 'EUR', name: 'Euro')],
    );
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsRepositoryProvider.overrideWithValue(accountsRepo),
          currenciesRepositoryProvider.overrideWithValue(currenciesRepo),
        ],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: const AccountsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping an account card opens the edit sheet', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Giro'), findsOneWidget);

    await tester.tap(find.text('Giro'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Account'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('dragging an account to the end persists the new order', (
    tester,
  ) async {
    when(() => accountsRepo.getAll()).thenAnswer(
      (_) async => [
        const Account(id: 1, accountName: 'Giro'),
        const Account(id: 2, accountName: 'Savings'),
        const Account(id: 3, accountName: 'Cash'),
      ],
    );
    when(() => accountsRepo.updateSortOrder(any())).thenAnswer((_) async {});

    await pumpScreen(tester);

    // Drag the first card past the other two.
    final handle = find.text('Giro');
    final start = tester.getCenter(handle);
    final gesture = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 300));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final sent =
        verify(() => accountsRepo.updateSortOrder(captureAny())).captured.single
            as List<int>;
    expect(
      sent,
      [2, 3, 1],
      reason: 'Giro moved to the end; the other two keep their order',
    );
  });

  group('the currency field on the edit sheet', () {
    testWidgets('the add sheet opens before any currency has loaded', (
      tester,
    ) async {
      when(() => currenciesRepo.getAll()).thenAnswer((_) async => []);

      await pumpScreen(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Add Account'), findsOneWidget);
    });

    testWidgets('the add sheet opens when the server has no EUR', (
      tester,
    ) async {
      when(() => currenciesRepo.getAll()).thenAnswer(
        (_) async => [const Currency(id: 1, code: 'CHF', name: 'Swiss Franc')],
      );

      await pumpScreen(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Add Account'), findsOneWidget);
    });

    testWidgets('an account in a currency the server no longer lists still '
        'opens for editing', (tester) async {
      when(() => accountsRepo.getAll()).thenAnswer(
        (_) async => [
          const Account(id: 1, accountName: 'Old', currency: 'DEM'),
        ],
      );

      await pumpScreen(tester);
      await tester.tap(find.text('Old'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Edit Account'), findsOneWidget);
    });
  });

  group('search and sort', () {
    const many = [
      Account(
        id: 1,
        accountName: 'Giro',
        institution: 'Sparkasse',
        balance: 1200,
      ),
      Account(
        id: 2,
        accountName: 'Savings',
        institution: 'ING',
        accountType: 'SAVINGS',
        accountGroup: 'Rainy day',
        balance: 8400,
      ),
      Account(
        id: 3,
        accountName: 'Cash',
        accountType: 'CASH',
        balance: 60,
      ),
    ];

    double rowY(WidgetTester tester, String text) =>
        tester.getTopLeft(find.text(text)).dy;

    Future<void> pumpMany(WidgetTester tester) async {
      when(() => accountsRepo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);
    }

    /// The long-press drag the reorderable list listens for.
    Future<void> dragFirstToEnd(WidgetTester tester, String label) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(label)),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 300));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('typing keeps only the accounts that match', (tester) async {
      await pumpMany(tester);

      await tester.enterText(find.byType(TextField).first, 'cash');
      await tester.pumpAndSettle();

      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Giro'), findsNothing);
    });

    testWidgets('the institution is searched too', (tester) async {
      await pumpMany(tester);

      await tester.enterText(find.byType(TextField).first, 'sparkasse');
      await tester.pumpAndSettle();

      expect(find.text('Giro'), findsOneWidget);
      expect(find.text('Savings'), findsNothing);
    });

    testWidgets('the group is searched too', (tester) async {
      await pumpMany(tester);

      await tester.enterText(find.byType(TextField).first, 'rainy');
      await tester.pumpAndSettle();

      expect(find.text('Savings'), findsOneWidget);
      expect(find.text('Giro'), findsNothing);
    });

    testWidgets('a search matching nothing offers to clear it', (tester) async {
      await pumpMany(tester);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No accounts match'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('Giro'), findsOneWidget);
    });

    testWidgets('the balance chip sorts smallest first', (tester) async {
      await pumpMany(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Balance'));
      await tester.pumpAndSettle();

      expect(rowY(tester, 'Cash'), lessThan(rowY(tester, 'Giro')));
      expect(rowY(tester, 'Giro'), lessThan(rowY(tester, 'Savings')));
    });

    testWidgets('tapping the balance chip again puts the richest on top', (
      tester,
    ) async {
      await pumpMany(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Balance'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Balance'));
      await tester.pumpAndSettle();

      expect(rowY(tester, 'Savings'), lessThan(rowY(tester, 'Cash')));
    });

    testWidgets('the custom chip is the one selected to begin with', (
      tester,
    ) async {
      await pumpMany(tester);

      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Custom order'),
      );
      expect(chip.selected, isTrue);
      expect(rowY(tester, 'Giro'), lessThan(rowY(tester, 'Savings')));
    });

    testWidgets('a drag under the custom order still saves it', (tester) async {
      when(() => accountsRepo.updateSortOrder(any())).thenAnswer((_) async {});
      await pumpMany(tester);

      await dragFirstToEnd(tester, 'Giro');

      verify(() => accountsRepo.updateSortOrder([2, 3, 1])).called(1);
    });

    testWidgets(
      'a drag while sorted saves nothing, since the drop position would '
      'mean nothing',
      (tester) async {
        when(
          () => accountsRepo.updateSortOrder(any()),
        ).thenAnswer((_) async {});
        await pumpMany(tester);

        await tester.tap(find.widgetWithText(FilterChip, 'Name'));
        await tester.pumpAndSettle();
        await dragFirstToEnd(tester, 'Cash');

        verifyNever(() => accountsRepo.updateSortOrder(any()));
      },
    );

    testWidgets(
      'a drag while searching saves nothing, rather than telling the server '
      'an order that omits the rows filtered out of sight',
      (tester) async {
        when(
          () => accountsRepo.updateSortOrder(any()),
        ).thenAnswer((_) async {});
        await pumpMany(tester);

        await tester.enterText(find.byType(TextField).first, 'i');
        await tester.pumpAndSettle();
        expect(find.text('Cash'), findsNothing, reason: 'filtered out');

        await dragFirstToEnd(tester, 'Giro');

        verifyNever(() => accountsRepo.updateSortOrder(any()));
      },
    );

    testWidgets('the custom chip brings back the order the server sent', (
      tester,
    ) async {
      await pumpMany(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Name'));
      await tester.pumpAndSettle();
      expect(rowY(tester, 'Cash'), lessThan(rowY(tester, 'Giro')));

      await tester.tap(find.widgetWithText(FilterChip, 'Custom order'));
      await tester.pumpAndSettle();

      expect(rowY(tester, 'Giro'), lessThan(rowY(tester, 'Savings')));
      expect(rowY(tester, 'Savings'), lessThan(rowY(tester, 'Cash')));
    });
  });

  testWidgets(
    'an account whose type this build does not know still opens for editing',
    (tester) async {
      when(() => accountsRepo.getAll()).thenAnswer(
        (_) async => [
          const Account(
            id: 1,
            accountName: 'Depot',
            accountType: 'BROKERAGE',
          ),
        ],
      );

      await pumpScreen(tester);
      await tester.tap(find.text('Depot'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('BROKERAGE'), findsOneWidget);
    },
  );

  testWidgets(
    'a save that fails in a way the app did not anticipate says so and '
    'leaves the sheet usable, rather than spinning for ever',
    (tester) async {
      when(() => accountsRepo.save(any())).thenThrow(Exception('boom'));

      await pumpScreen(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      // The taller sheets put Save below the fold on a test-sized screen.
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('An error occurred'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Save'),
        findsOneWidget,
        reason: 'the button came back, so another attempt is possible',
      );
    },
  );
}
