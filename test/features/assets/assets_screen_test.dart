import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/widgets/privacy_blur.dart';
import 'package:cuentimobile/features/assets/data/assets_repository.dart';
import 'package:cuentimobile/features/assets/domain/asset.dart';
import 'package:cuentimobile/features/assets/ui/assets_screen.dart';
import 'package:cuentimobile/features/currencies/data/currencies_repository.dart';
import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetsRepository extends Mock implements AssetsRepository {}

class MockCurrenciesRepository extends Mock implements CurrenciesRepository {}

class _PrivateMode extends PrivacyMode {
  @override
  bool build() => true;
}

/// A Euro written the German way, which is what the currencies screen edits
/// and what every other amount in the app already honours.
const _euro = Currency(
  id: 1,
  code: 'EUR',
  name: 'Euro',
  symbol: '€',
);

void main() {
  setUpAll(
    () => registerFallbackValue(const Asset(id: 1, symbol: 'X', name: 'X')),
  );

  late MockAssetsRepository repo;
  late MockCurrenciesRepository currenciesRepo;

  const many = [
    Asset(
      id: 1,
      symbol: 'VWCE.DE',
      name: 'Vanguard All-World',
      type: 'ETF',
      currentPrice: 128.4,
      currency: 'EUR',
    ),
    Asset(
      id: 2,
      symbol: 'BTC',
      name: 'Bitcoin',
      type: 'CRYPTO',
      currentPrice: 61000,
      currency: 'EUR',
    ),
    Asset(
      id: 3,
      symbol: 'SAP.DE',
      name: 'SAP SE',
      currentPrice: 201.1,
      currency: 'EUR',
    ),
  ];

  setUp(() {
    repo = MockAssetsRepository();
    currenciesRepo = MockCurrenciesRepository();
    when(() => repo.getAll()).thenAnswer((_) async => many);
    when(() => currenciesRepo.getAll()).thenAnswer((_) async => [_euro]);
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Locale? locale,
    bool privacy = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetsRepositoryProvider.overrideWithValue(repo),
          currenciesRepositoryProvider.overrideWithValue(currenciesRepo),
          if (privacy) privacyModeProvider.overrideWith(_PrivateMode.new),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: const AssetsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double rowY(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  testWidgets('lists what the server returned', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('SAP SE'), findsOneWidget);
  });

  testWidgets('offers to add one when there are none', (tester) async {
    when(() => repo.getAll()).thenAnswer((_) async => []);

    await pumpScreen(tester);

    expect(find.text('No assets yet'), findsOneWidget);
  });

  group('search and sort', () {
    testWidgets('searches the name', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'bitcoin');
      await tester.pumpAndSettle();

      expect(find.text('Bitcoin'), findsOneWidget);
      expect(find.text('SAP SE'), findsNothing);
    });

    testWidgets('searches the ticker symbol too', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'vwce');
      await tester.pumpAndSettle();

      expect(find.text('Vanguard All-World'), findsOneWidget);
      expect(find.text('Bitcoin'), findsNothing);
    });

    testWidgets('searches the type, so "crypto" narrows to the coins', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'crypto');
      await tester.pumpAndSettle();

      expect(find.text('Bitcoin'), findsOneWidget);
      expect(find.text('SAP SE'), findsNothing);
    });

    testWidgets('a search matching nothing offers to clear it', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No assets match'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('Bitcoin'), findsOneWidget);
    });

    testWidgets('the name chip sorts A to Z', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Name'));
      await tester.pumpAndSettle();

      expect(rowY(tester, 'Bitcoin'), lessThan(rowY(tester, 'SAP SE')));
      expect(
        rowY(tester, 'SAP SE'),
        lessThan(rowY(tester, 'Vanguard All-World')),
      );
    });

    testWidgets('the price chip sorts by price, cheapest first', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Price'));
      await tester.pumpAndSettle();

      expect(
        rowY(tester, 'Vanguard All-World'),
        lessThan(rowY(tester, 'SAP SE')),
      );
      expect(rowY(tester, 'SAP SE'), lessThan(rowY(tester, 'Bitcoin')));
    });

    testWidgets('tapping the price chip again puts the dearest on top', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Price'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Price'));
      await tester.pumpAndSettle();

      expect(
        rowY(tester, 'Bitcoin'),
        lessThan(rowY(tester, 'Vanguard All-World')),
      );
    });

    testWidgets('an asset with no price sorts last rather than crashing', (
      tester,
    ) async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => [
          const Asset(id: 9, symbol: 'NEW', name: 'Unpriced'),
          ...many,
        ],
      );
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Price'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(rowY(tester, 'Bitcoin'), lessThan(rowY(tester, 'Unpriced')));
    });
  });

  testWidgets(
    'an asset whose type this build does not know still opens for editing',
    (tester) async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => [
          const Asset(id: 1, symbol: 'DE0001', name: 'Bund', type: 'BOND'),
        ],
      );

      await pumpScreen(tester);
      await tester.tap(find.text('Bund'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('BOND'), findsOneWidget);
    },
  );

  testWidgets(
    'a save that fails in a way the app did not anticipate says so and '
    'leaves the sheet usable, rather than spinning for ever',
    (tester) async {
      when(() => repo.save(any())).thenThrow(Exception('boom'));

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
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    },
  );

  testWidgets('names an asset type in words on the tile', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('Crypto'), findsOneWidget);
    expect(find.textContaining('CRYPTO'), findsNothing);
  });

  group('prices and dates read like the rest of the app', () {
    testWidgets('a price is written the way its currency says', (tester) async {
      await pumpScreen(tester);

      expect(find.textContaining('61.000,00'), findsOneWidget);
      expect(
        find.textContaining('61000.00'),
        findsNothing,
        reason: 'the raw toStringAsFixed form',
      );
    });

    testWidgets('privacy mode hides asset prices, as it hides every other '
        'amount', (tester) async {
      await pumpScreen(tester, privacy: true);

      // The blur keeps the text in the tree so layout does not jump; the
      // price has to sit behind one.
      expect(
        find.ancestor(
          of: find.textContaining('61.000,00'),
          matching: find.byType(PrivacyBlur),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an asset with no price still says so', (tester) async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => [const Asset(id: 9, symbol: 'NEW', name: 'Unpriced')],
      );

      await pumpScreen(tester);

      expect(find.text('No price'), findsOneWidget);
    });

    testWidgets("the last-update date follows the reader's locale", (
      tester,
    ) async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => [
          Asset(
            id: 1,
            symbol: 'BTC',
            name: 'Bitcoin',
            type: 'CRYPTO',
            currentPrice: 61000,
            currency: 'EUR',
            lastUpdate: DateTime(2026, 9, 3, 14, 5),
          ),
        ],
      );

      await pumpScreen(tester, locale: const Locale('en'));
      expect(find.textContaining('9/3/2026'), findsOneWidget);

      await pumpScreen(tester, locale: const Locale('de'));
      expect(
        find.textContaining('3.9.2026'),
        findsOneWidget,
        reason:
            'German writes the day first, and the app used to hard-code '
            'that order for every language',
      );
    });
  });
}
