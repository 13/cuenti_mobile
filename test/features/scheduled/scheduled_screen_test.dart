import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/currencies/data/currencies_repository.dart';
import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:cuentimobile/features/scheduled/data/scheduled_repository.dart';
import 'package:cuentimobile/features/scheduled/domain/scheduled_transaction.dart';
import 'package:cuentimobile/features/scheduled/ui/scheduled_screen.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockScheduledRepository extends Mock implements ScheduledRepository {}

class _Currencies implements CurrenciesRepository {
  @override
  Future<List<Currency>> getAll() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockScheduledRepository repo;

  final rent = ScheduledTransaction(
    id: 1,
    amount: 800,
    nextOccurrence: DateTime(2099, 3),
    payee: 'Landlord',
    fromAccountName: 'Giro',
  );

  setUpAll(() {
    registerFallbackValue(
      ScheduledTransaction(amount: 0, nextOccurrence: DateTime(2099)),
    );
  });

  setUp(() {
    repo = MockScheduledRepository();
    when(repo.getAll).thenAnswer((_) async => [rent]);
    when(() => repo.save(any())).thenAnswer((_) async => rent);
    when(() => repo.delete(any())).thenAnswer((_) async {});
    when(() => repo.post(any())).thenAnswer((_) async {});
    when(() => repo.skip(any())).thenAnswer((_) async {});
  });

  Future<void> pumpScreen(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduledRepositoryProvider.overrideWithValue(repo),
          currenciesRepositoryProvider.overrideWithValue(_Currencies()),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: const Scaffold(body: ScheduledScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists what the server returned', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Landlord'), findsOneWidget);
  });

  testWidgets('says so when there is nothing scheduled', (tester) async {
    when(repo.getAll).thenAnswer((_) async => []);

    await pumpScreen(tester);

    expect(find.text('No scheduled transactions'), findsOneWidget);
  });

  group('the wire constants stay off the screen', () {
    testWidgets('an entry with no payee is named by its type in words, not '
        'as EXPENSE', (tester) async {
      when(repo.getAll).thenAnswer(
        (_) async => [
          ScheduledTransaction(
            id: 2,
            amount: 20,
            nextOccurrence: DateTime(2099, 3),
          ),
        ],
      );

      await pumpScreen(tester);

      expect(find.text('EXPENSE'), findsNothing);
      expect(find.text('Expense'), findsOneWidget);
    });

    testWidgets('the recurrence reads as a word, not as MONTHLY', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.textContaining('MONTHLY'), findsNothing);
      expect(find.textContaining('Monthly'), findsOneWidget);
    });

    testWidgets('and it is translated', (tester) async {
      await pumpScreen(tester, locale: const Locale('de'));

      expect(find.textContaining('MONTHLY'), findsNothing);
      expect(find.textContaining('Monatlich'), findsOneWidget);
    });
  });

  group('the actions a row offers', () {
    testWidgets('Post sends it to the server and confirms', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();

      verify(() => repo.post(1)).called(1);
      expect(find.text('Transaction posted'), findsOneWidget);
    });

    testWidgets('a refused Post says why and does not claim success', (
      tester,
    ) async {
      when(() => repo.post(any())).thenThrow(
        const ValidationException('Account is closed'),
      );

      await pumpScreen(tester);
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();

      expect(find.text('Transaction posted'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('a Post that fails unexpectedly does not escape unreported', (
      tester,
    ) async {
      when(() => repo.post(any())).thenThrow(Exception('boom'));

      await pumpScreen(tester);
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('An error occurred'), findsOneWidget);
      expect(find.text('Transaction posted'), findsNothing);
    });

    testWidgets('Skip sends it and confirms', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      verify(() => repo.skip(1)).called(1);
      expect(find.text('Occurrence skipped'), findsOneWidget);
    });

    testWidgets('a Skip that fails unexpectedly is reported', (tester) async {
      when(() => repo.skip(any())).thenThrow(Exception('boom'));

      await pumpScreen(tester);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Occurrence skipped'), findsNothing);
    });

    testWidgets('the switch turns an entry off through the server', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final saved =
          verify(() => repo.save(captureAny())).captured.single
              as ScheduledTransaction;
      expect(saved.enabled, isFalse);
    });

    testWidgets('a switch the server refuses is reported rather than '
        'silently ignored', (tester) async {
      when(() => repo.save(any())).thenThrow(Exception('boom'));

      await pumpScreen(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('An error occurred'), findsOneWidget);
    });
  });

  group('deleting', () {
    testWidgets('a long press asks first, and cancelling keeps the row', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.longPress(find.text('Landlord'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.delete(any()));
      expect(find.text('Landlord'), findsOneWidget);
    });

    testWidgets('confirming deletes it', (tester) async {
      await pumpScreen(tester);

      await tester.longPress(find.text('Landlord'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      verify(() => repo.delete(1)).called(1);
    });

    testWidgets('a delete that fails unexpectedly is reported', (tester) async {
      when(() => repo.delete(any())).thenThrow(Exception('boom'));

      await pumpScreen(tester);
      await tester.longPress(find.text('Landlord'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('An error occurred'), findsOneWidget);
    });
  });

  group('search and sort', () {
    final many = [
      ScheduledTransaction(
        id: 1,
        amount: 800,
        nextOccurrence: DateTime(2099, 3),
        payee: 'Landlord',
      ),
      ScheduledTransaction(
        id: 2,
        amount: 12,
        nextOccurrence: DateTime(2099),
        payee: 'Netflix',
        recurrencePattern: 'WEEKLY',
      ),
      ScheduledTransaction(
        id: 3,
        amount: 60,
        nextOccurrence: DateTime(2099, 6),
        payee: 'Gym',
      ),
    ];

    double rowY(WidgetTester tester, String text) =>
        tester.getTopLeft(find.text(text)).dy;

    Future<void> pumpMany(WidgetTester tester) async {
      when(repo.getAll).thenAnswer((_) async => many);
      await pumpScreen(tester);
    }

    testWidgets('typing keeps only the entries that match', (tester) async {
      await pumpMany(tester);

      await tester.enterText(find.byType(TextField).first, 'netflix');
      await tester.pumpAndSettle();

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Landlord'), findsNothing);
    });

    testWidgets('a search matching nothing offers to clear it', (tester) async {
      await pumpMany(tester);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No scheduled transactions match'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('Landlord'), findsOneWidget);
    });

    testWidgets('the amount chip sorts smallest first', (tester) async {
      await pumpMany(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Amount'));
      await tester.pumpAndSettle();

      expect(rowY(tester, 'Netflix'), lessThan(rowY(tester, 'Gym')));
      expect(rowY(tester, 'Gym'), lessThan(rowY(tester, 'Landlord')));
    });

    testWidgets('the due chip puts the soonest first', (tester) async {
      await pumpMany(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Next'));
      await tester.pumpAndSettle();

      expect(rowY(tester, 'Netflix'), lessThan(rowY(tester, 'Landlord')));
      expect(rowY(tester, 'Landlord'), lessThan(rowY(tester, 'Gym')));
    });
  });

  group('the overdue marker on a row', () {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    Future<void> pumpWith(
      WidgetTester tester,
      DateTime due, {
      bool enabled = true,
    }) async {
      when(repo.getAll).thenAnswer(
        (_) async => [
          ScheduledTransaction(
            id: 1,
            amount: 800,
            nextOccurrence: due,
            payee: 'Landlord',
            enabled: enabled,
          ),
        ],
      );
      await pumpScreen(tester);
    }

    testWidgets('an entry due today is not late, however late in the day it '
        'is read', (tester) async {
      await pumpWith(tester, DateTime(today.year, today.month, today.day));

      expect(find.textContaining('(LATE!)'), findsNothing);
    });

    testWidgets('an entry due yesterday is late', (tester) async {
      await pumpWith(
        tester,
        DateTime(yesterday.year, yesterday.month, yesterday.day),
      );

      expect(find.textContaining('(LATE!)'), findsOneWidget);
    });

    testWidgets('a paused entry is not shouted at, matching the badge that '
        'does not count it', (tester) async {
      await pumpWith(
        tester,
        DateTime(yesterday.year, yesterday.month, yesterday.day),
        enabled: false,
      );

      expect(find.textContaining('(LATE!)'), findsNothing);
    });
  });
}
