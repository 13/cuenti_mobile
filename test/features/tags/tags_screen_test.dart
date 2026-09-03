import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/tags/data/tags_repository.dart';
import 'package:cuentimobile/features/tags/domain/tag.dart';
import 'package:cuentimobile/features/tags/ui/tags_screen.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTagsRepository extends Mock implements TagsRepository {}

void main() {
  setUpAll(() => registerFallbackValue(const Tag(id: 1, name: 'Urlaub')));

  late MockTagsRepository repo;

  setUp(() {
    repo = MockTagsRepository();
    when(
      () => repo.getAll(),
    ).thenAnswer((_) async => [const Tag(id: 1, name: 'Urlaub')]);
  });

  Future<void> pumpScreen(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tagsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: const TagsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists what the server returned', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Urlaub'), findsOneWidget);
  });

  testWidgets('offers to add one when there are none', (tester) async {
    when(() => repo.getAll()).thenAnswer((_) async => []);

    await pumpScreen(tester);

    expect(find.text('No tags yet'), findsOneWidget);
  });

  testWidgets('a swipe asks before deleting and cancelling keeps the row', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.drag(find.text('Urlaub'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete Tag?'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.delete(any()));
    expect(find.text('Urlaub'), findsOneWidget);
  });

  testWidgets('confirming a swipe deletes it', (tester) async {
    when(() => repo.delete(any())).thenAnswer((_) async {});

    await pumpScreen(tester);

    await tester.drag(find.text('Urlaub'), const Offset(-500, 0));
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
    ).thenAnswer((_) async => const Tag(id: 1, name: 'Urlaub'));

    await pumpScreen(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Something');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Tag saved'), findsOneWidget);
  });

  testWidgets('the confirmation speaks the chosen language', (tester) async {
    when(
      () => repo.save(any()),
    ).thenAnswer((_) async => const Tag(id: 1, name: 'Urlaub'));

    await pumpScreen(tester, locale: const Locale('de'));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Something');
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Tag gespeichert'), findsOneWidget);
  });

  group('search and sort', () {
    const many = [
      Tag(id: 1, name: 'Urlaub'),
      Tag(id: 2, name: 'Arbeit'),
      Tag(id: 3, name: 'Umzug Wien'),
    ];

    /// Vertical position of a row, for asserting on order.
    double rowY(WidgetTester tester, String name) =>
        tester.getTopLeft(find.text(name)).dy;

    testWidgets('typing keeps only the tags that match', (tester) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'u');
      await tester.pumpAndSettle();

      expect(find.text('Urlaub'), findsOneWidget);
      expect(find.text('Umzug Wien'), findsOneWidget);
      expect(find.text('Arbeit'), findsNothing);
    });

    testWidgets('every token has to match, in any order', (tester) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'wien umzug');
      await tester.pumpAndSettle();

      expect(find.text('Umzug Wien'), findsOneWidget);
      expect(find.text('Urlaub'), findsNothing);
    });

    testWidgets('a search matching nothing offers to clear it', (tester) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No tags match'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('Urlaub'), findsOneWidget);
      expect(find.text('Arbeit'), findsOneWidget);
    });

    testWidgets('the name chip sorts A to Z', (tester) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Name'));
      await tester.pumpAndSettle();

      expect(rowY(tester, 'Arbeit'), lessThan(rowY(tester, 'Umzug Wien')));
      expect(rowY(tester, 'Umzug Wien'), lessThan(rowY(tester, 'Urlaub')));
    });

    testWidgets('tapping the name chip again sorts Z to A', (tester) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Name'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Name'));
      await tester.pumpAndSettle();

      expect(rowY(tester, 'Urlaub'), lessThan(rowY(tester, 'Arbeit')));
    });

    testWidgets('a filtered row still deletes the tag it names', (
      tester,
    ) async {
      when(() => repo.getAll()).thenAnswer((_) async => many);
      when(() => repo.delete(any())).thenAnswer((_) async {});
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'arbeit');
      await tester.pumpAndSettle();
      await tester.drag(find.text('Arbeit'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      verify(() => repo.delete(2)).called(1);
    });
  });

  testWidgets(
    'what was typed is still there after leaving the screen and coming back',
    (tester) async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => const [
          Tag(id: 1, name: 'Urlaub'),
          Tag(id: 2, name: 'Arbeit'),
        ],
      );

      // One ProviderScope held across both mounts, which is what navigating
      // away and back amounts to: the screen is rebuilt, the container is not.
      Widget app(Widget home) => ProviderScope(
        overrides: [tagsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: home,
        ),
      );

      await tester.pumpWidget(app(const TagsScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'urlaub');
      await tester.pumpAndSettle();

      await tester.pumpWidget(app(const Scaffold()));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(const TagsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('urlaub'), findsOneWidget);
      expect(find.text('Arbeit'), findsNothing, reason: 'still filtered');
    },
  );
}
