import 'package:cuentimobile/core/widgets/entity_list_header.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for the entities the Verwaltung screens list: something with a
/// name to search and a number to sort by.
class _Row {
  const _Row(this.name, this.rank);

  final String name;
  final int rank;

  @override
  String toString() => '$name($rank)';
}

const _byName = SortOption<_Row>(id: 'name', label: 'Name', compare: _cmpName);
const _byRank = SortOption<_Row>(id: 'rank', label: 'Rank', compare: _cmpRank);
const _custom = SortOption<_Row>(id: 'custom', label: 'Custom');

int _cmpName(_Row a, _Row b) => a.name.compareTo(b.name);
int _cmpRank(_Row a, _Row b) => a.rank.compareTo(b.rank);

String _name(_Row r) => r.name;

void main() {
  const rows = [
    _Row('Sparkasse Giro', 3),
    _Row('Aral Tankstelle', 1),
    _Row('sparkasse Tagesgeld', 2),
  ];

  group('applySearchAndSort', () {
    test('a blank query keeps every item', () {
      final result = applySearchAndSort(
        rows,
        query: '',
        searchText: _name,
        sort: _custom,
      );

      expect(result, rows);
    });

    test('keeps only the items carrying every token, in any order', () {
      final result = applySearchAndSort(
        rows,
        query: 'tank aral',
        searchText: _name,
        sort: _custom,
      );

      expect(result.map(_name), ['Aral Tankstelle']);
    });

    test('matches regardless of case, so "spar" finds both Sparkassen', () {
      final result = applySearchAndSort(
        rows,
        query: 'SPAR',
        searchText: _name,
        sort: _custom,
      );

      expect(result.map(_name), ['Sparkasse Giro', 'sparkasse Tagesgeld']);
    });

    test('orders by the chosen comparator', () {
      final result = applySearchAndSort(
        rows,
        query: '',
        searchText: _name,
        sort: _byRank,
      );

      expect(result.map((r) => r.rank), [1, 2, 3]);
    });

    test('descending reverses that order', () {
      final result = applySearchAndSort(
        rows,
        query: '',
        searchText: _name,
        sort: _byRank,
        descending: true,
      );

      expect(result.map((r) => r.rank), [3, 2, 1]);
    });

    test('an option with no comparator keeps the order the server sent', () {
      final result = applySearchAndSort(
        rows,
        query: '',
        searchText: _name,
        sort: _custom,
        descending: true,
      );

      expect(result, rows, reason: 'custom order has no direction to flip');
    });

    test('filters before sorting, so the two compose', () {
      final result = applySearchAndSort(
        rows,
        query: 'spar',
        searchText: _name,
        sort: _byRank,
      );

      expect(result.map((r) => r.rank), [2, 3]);
    });

    test('leaves the list the caller passed untouched', () {
      final original = [...rows];

      applySearchAndSort(original, query: '', searchText: _name, sort: _byRank);

      expect(original, rows);
    });

    test(
      'holds equal-key items in the order they arrived, so sorting accounts '
      'by type keeps each type block in its saved custom order',
      () {
        const tied = [
          _Row('Third', 1),
          _Row('First', 1),
          _Row('Second', 1),
        ];

        final result = applySearchAndSort(
          tied,
          query: '',
          searchText: _name,
          sort: _byRank,
        );

        expect(result.map(_name), ['Third', 'First', 'Second']);
      },
    );

    test('a null sort leaves the order alone', () {
      final result = applySearchAndSort(rows, query: '', searchText: _name);

      expect(result, rows);
    });
  });

  group('sortOptionFor', () {
    const options = [_custom, _byName, _byRank];

    test('finds the option the selection names', () {
      expect(sortOptionFor(options, const SortSelection('rank')), _byRank);
    });

    test('gives null when nothing is selected, so the list keeps the order '
        'the server sent', () {
      expect(sortOptionFor(options, SortSelection.none), isNull);
    });

    test('gives null for an id no option carries', () {
      expect(sortOptionFor(options, const SortSelection('gone')), isNull);
    });
  });

  group('EntityListHeader', () {
    const options = [_custom, _byName, _byRank];

    /// Pumps the header and hands back the box the chosen sort lands in.
    Future<({List<SortSelection> sorts, List<String> queries})> pumpHeader(
      WidgetTester tester, {
      SortSelection selected = const SortSelection('custom'),
    }) async {
      final sorts = <SortSelection>[];
      final queries = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: Scaffold(
            body: EntityListHeader<_Row>(
              searchController: TextEditingController(),
              searchHint: 'Search rows',
              onSearchChanged: queries.add,
              options: options,
              selected: selected,
              onSortChanged: sorts.add,
            ),
          ),
        ),
      );
      return (sorts: sorts, queries: queries);
    }

    testWidgets('shows the hint the caller gave it', (tester) async {
      await pumpHeader(tester);

      expect(find.text('Search rows'), findsOneWidget);
    });

    testWidgets('reports what the user types', (tester) async {
      final recorded = await pumpHeader(tester);

      await tester.enterText(find.byType(TextField), 'spar');

      expect(recorded.queries, ['spar']);
    });

    testWidgets('renders a chip for every sort option', (tester) async {
      await pumpHeader(tester);

      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Rank'), findsOneWidget);
    });

    testWidgets('tapping an unselected chip sorts by it, ascending', (
      tester,
    ) async {
      final recorded = await pumpHeader(tester);

      await tester.tap(find.text('Rank'));
      await tester.pumpAndSettle();

      expect(recorded.sorts.single.id, 'rank');
      expect(recorded.sorts.single.descending, isFalse);
    });

    testWidgets('tapping the active chip flips the direction', (tester) async {
      final recorded = await pumpHeader(
        tester,
        selected: const SortSelection('rank'),
      );

      await tester.tap(find.text('Rank'));
      await tester.pumpAndSettle();

      expect(recorded.sorts.single.id, 'rank');
      expect(recorded.sorts.single.descending, isTrue);
    });

    testWidgets('tapping a descending chip flips it back to ascending', (
      tester,
    ) async {
      final recorded = await pumpHeader(
        tester,
        selected: const SortSelection('rank', descending: true),
      );

      await tester.tap(find.text('Rank'));
      await tester.pumpAndSettle();

      expect(recorded.sorts.single.descending, isFalse);
    });

    testWidgets(
      'the manual chip offers no direction, since a dragged order has none',
      (tester) async {
        final recorded = await pumpHeader(tester);

        await tester.tap(find.text('Custom'));
        await tester.pumpAndSettle();

        expect(
          recorded.sorts.every((s) => !s.descending),
          isTrue,
          reason: 'a manual order cannot be reversed',
        );
        expect(
          find.descendant(
            of: find.widgetWithText(FilterChip, 'Custom'),
            matching: find.byIcon(Icons.arrow_upward),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('only the active chip carries a direction arrow', (
      tester,
    ) async {
      await pumpHeader(tester, selected: const SortSelection('name'));

      expect(
        find.descendant(
          of: find.widgetWithText(FilterChip, 'Name'),
          matching: find.byIcon(Icons.arrow_upward),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(FilterChip, 'Rank'),
          matching: find.byIcon(Icons.arrow_upward),
        ),
        findsNothing,
      );
    });

    testWidgets('the direction is announced, not left to the arrow alone', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpHeader(tester, selected: const SortSelection('name'));
      // The chip merges its parts into one node, so the direction shows up
      // alongside the chip's own name rather than on its own.
      expect(find.bySemanticsLabel(RegExp('Ascending')), findsOneWidget);

      await pumpHeader(
        tester,
        selected: const SortSelection('name', descending: true),
      );
      expect(find.bySemanticsLabel(RegExp('Descending')), findsOneWidget);

      handle.dispose();
    });

    testWidgets('a descending chip points its arrow down', (tester) async {
      await pumpHeader(
        tester,
        selected: const SortSelection('name', descending: true),
      );

      expect(
        find.descendant(
          of: find.widgetWithText(FilterChip, 'Name'),
          matching: find.byIcon(Icons.arrow_downward),
        ),
        findsOneWidget,
      );
    });
  });
}
