import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/payees/data/payees_repository.dart';
import 'package:cuentimobile/features/payees/domain/payee.dart';
import 'package:cuentimobile/features/payees/ui/payees_screen.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPayeesRepository extends Mock implements PayeesRepository {}

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

const _categories = [
  Category(id: 7, name: 'Tanken', fullName: 'Auto:Tanken', parentId: 4),
  Category(id: 4, name: 'Auto', fullName: 'Auto'),
];

void main() {
  setUpAll(
    () => registerFallbackValue(const Payee(id: 1, name: 'Aral Tankstelle')),
  );

  late MockPayeesRepository repo;
  late MockCategoriesRepository categoriesRepo;

  setUp(() {
    repo = MockPayeesRepository();
    categoriesRepo = MockCategoriesRepository();
    when(
      () => repo.getAll(),
    ).thenAnswer((_) async => [const Payee(id: 1, name: 'Aral Tankstelle')]);
    when(() => categoriesRepo.getAll()).thenAnswer((_) async => _categories);
  });

  Future<void> pumpScreen(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          payeesRepositoryProvider.overrideWithValue(repo),
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
        ],
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
    await tester.enterText(find.byType(TextField).last, 'Something');
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
    await tester.enterText(find.byType(TextField).last, 'Something');
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Empfänger gespeichert'), findsOneWidget);
  });

  group('the default category field', () {
    testWidgets(
      'a payee that already has one opens for editing instead of throwing',
      (tester) async {
        when(() => repo.getAll()).thenAnswer(
          (_) async => [
            const Payee(
              id: 1,
              name: 'Aral Tankstelle',
              defaultCategoryId: 7,
              defaultCategoryName: 'Auto:Tanken',
            ),
          ],
        );

        await pumpScreen(tester);
        await tester.tap(find.text('Aral Tankstelle'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
      },
    );

    testWidgets('shows the category the payee is already set to', (
      tester,
    ) async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => [
          const Payee(id: 1, name: 'Aral Tankstelle', defaultCategoryId: 7),
        ],
      );

      await pumpScreen(tester);
      await tester.tap(find.text('Aral Tankstelle'));
      await tester.pumpAndSettle();

      expect(find.text('Auto:Tanken'), findsOneWidget);
    });

    testWidgets('offers the real categories, not just "None"', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Default Category'));
      await tester.pumpAndSettle();

      expect(find.text('Auto:Tanken'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
    });

    testWidgets('the category picked is the one saved', (tester) async {
      when(() => repo.save(any())).thenAnswer(
        (_) async => const Payee(id: 2, name: 'Shell'),
      );

      await pumpScreen(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Shell');
      await tester.tap(find.text('Default Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Auto:Tanken'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final saved = verify(() => repo.save(captureAny())).captured.single;
      expect((saved as Payee).defaultCategoryId, 7);
    });
  });

  group('search and sort', () {
    const many = [
      Payee(id: 1, name: 'Aral Tankstelle'),
      Payee(id: 2, name: 'Rewe', notes: 'Supermarkt'),
      Payee(id: 3, name: 'Shell', defaultCategoryName: 'Auto:Tanken'),
    ];

    double rowY(WidgetTester tester, String text) =>
        tester.getTopLeft(find.text(text)).dy;

    testWidgets('typing keeps only the payees that match', (tester) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'shell');
      await tester.pumpAndSettle();

      expect(find.text('Shell'), findsOneWidget);
      expect(find.text('Rewe'), findsNothing);
    });

    testWidgets('the notes are searched too', (tester) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'supermarkt');
      await tester.pumpAndSettle();

      expect(find.text('Rewe'), findsOneWidget);
      expect(find.text('Aral Tankstelle'), findsNothing);
    });

    testWidgets('a search matching nothing offers to clear it', (tester) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No payees match'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('Rewe'), findsOneWidget);
    });

    testWidgets('the name chip sorts A to Z, and reverses on a second tap', (
      tester,
    ) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Name'));
      await tester.pumpAndSettle();
      expect(
        rowY(tester, 'Aral Tankstelle'),
        lessThan(rowY(tester, 'Shell')),
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Name'));
      await tester.pumpAndSettle();
      expect(
        rowY(tester, 'Shell'),
        lessThan(rowY(tester, 'Aral Tankstelle')),
      );
    });
  });

  testWidgets(
    'a payee whose default payment method this build does not know still '
    'opens for editing',
    (tester) async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => [
          const Payee(
            id: 1,
            name: 'Stadtwerke',
            defaultPaymentMethod: 'DIRECT_DEBIT',
          ),
        ],
      );

      await pumpScreen(tester);
      await tester.tap(find.text('Stadtwerke'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('DIRECT_DEBIT'), findsOneWidget);
    },
  );

  testWidgets('names payment methods in words, not as wire constants', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    expect(find.text('Bank Transfer'), findsWidgets);
    expect(find.text('BANK_TRANSFER'), findsNothing);
  });
}
