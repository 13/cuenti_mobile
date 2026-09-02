import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/saved_views/data/saved_views_repository.dart';
import 'package:cuentimobile/features/saved_views/domain/saved_view.dart';
import 'package:cuentimobile/features/saved_views/ui/saved_views_sheet.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSavedViewsRepository extends Mock implements SavedViewsRepository {}

void main() {
  late MockSavedViewsRepository repo;

  const mobileView = SavedView(
    id: 1,
    name: 'My groceries',
    params: '{"v":1,"categoryId":2}',
  );
  const webView = SavedView(
    id: 2,
    name: 'Web view',
    params: '{"someWebFormat":true}',
  );

  setUp(() {
    repo = MockSavedViewsRepository();
    when(() => repo.getAll()).thenAnswer((_) async => [mobileView, webView]);
    when(() => repo.delete(any())).thenAnswer((_) async {});
  });

  Future<TransactionFilter?> pumpAndOpenSheet(
    WidgetTester tester, {
    required TransactionFilter current,
  }) async {
    TransactionFilter? applied;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [savedViewsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showSavedViewsSheet(
                    context,
                    ref,
                    current: current,
                    onApply: (f) => applied = f,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return applied;
  }

  testWidgets('shows one enabled tile and one disabled tile for web view', (
    tester,
  ) async {
    await pumpAndOpenSheet(tester, current: const TransactionFilter());

    expect(find.text('My groceries'), findsOneWidget);
    expect(find.text('Web view'), findsOneWidget);
    expect(find.text('Saved by web app'), findsOneWidget);

    final mobileTile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('My groceries'),
        matching: find.byType(ListTile),
      ),
    );
    final webTile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Web view'),
        matching: find.byType(ListTile),
      ),
    );
    expect(mobileTile.enabled, isTrue);
    expect(webTile.enabled, isFalse);
  });

  testWidgets('tapping the enabled tile applies the decoded filter and pops', (
    tester,
  ) async {
    final applied = <TransactionFilter>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [savedViewsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showSavedViewsSheet(
                    context,
                    ref,
                    current: const TransactionFilter(),
                    onApply: applied.add,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('My groceries'));
    await tester.pumpAndSettle();

    expect(applied, hasLength(1));
    expect(applied.single, const TransactionFilter(categoryId: 2));
    // Sheet should have closed.
    expect(find.text('My groceries'), findsNothing);
  });

  testWidgets(
    "'Save current view' is disabled for the default filter and enabled "
    'once the filter has a search term',
    (tester) async {
      await pumpAndOpenSheet(tester, current: const TransactionFilter());
      final defaultButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save current view'),
      );
      expect(defaultButton.onPressed, isNull);
    },
  );

  testWidgets("'Save current view' is enabled with a non-default filter", (
    tester,
  ) async {
    await pumpAndOpenSheet(
      tester,
      current: const TransactionFilter(search: 'coffee'),
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save current view'),
    );
    expect(button.onPressed, isNotNull);
  });

  group('deleting a saved view', () {
    testWidgets('asks first, and cancelling keeps the view', (tester) async {
      await pumpAndOpenSheet(tester, current: const TransactionFilter());

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.delete(any()));
      expect(find.text('My groceries'), findsOneWidget);
    });

    testWidgets('confirming deletes that view', (tester) async {
      await pumpAndOpenSheet(tester, current: const TransactionFilter());

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      verify(() => repo.delete(1)).called(1);
    });

    testWidgets("a refused delete says why, in the user's language, rather "
        'than leaving the view looking deleted', (tester) async {
      when(() => repo.delete(any())).thenThrow(
        const ValidationException(
          'Invalid request',
          serverMessage: 'View is in use',
        ),
      );

      await pumpAndOpenSheet(tester, current: const TransactionFilter());
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('View is in use'), findsOneWidget);
      expect(find.text('My groceries'), findsOneWidget);
    });

    testWidgets('a view written by the web app cannot be deleted from here '
        'either, since it cannot be read from here', (tester) async {
      await pumpAndOpenSheet(tester, current: const TransactionFilter());

      final webTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Web view'),
          matching: find.byType(ListTile),
        ),
      );
      expect(webTile.enabled, isFalse);
    });
  });
}
