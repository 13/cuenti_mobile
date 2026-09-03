import 'package:cuentimobile/core/widgets/entity_list_filter.dart';
import 'package:cuentimobile/core/widgets/entity_list_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  EntityFilter read(String screen) =>
      container.read(entityListFilterProvider(screen));

  EntityListFilter notifier(String screen) =>
      container.read(entityListFilterProvider(screen).notifier);

  test('a screen starts unfiltered and unsorted', () {
    expect(read('tags').query, '');
    expect(read('tags').sort, SortSelection.none);
  });

  test('remembers what was typed', () {
    notifier('tags').setQuery('urlaub');

    expect(read('tags').query, 'urlaub');
  });

  test('remembers the chosen sort', () {
    notifier('tags').setSort(const SortSelection('name', descending: true));

    expect(read('tags').sort, const SortSelection('name', descending: true));
  });

  test('the sort survives a change of query, and the other way round', () {
    notifier('tags')
      ..setSort(const SortSelection('name'))
      ..setQuery('urlaub');

    expect(read('tags').sort, const SortSelection('name'));
    expect(read('tags').query, 'urlaub');
  });

  test('clearing drops the query but keeps the sort, which the user did not '
      'ask to undo', () {
    notifier('tags')
      ..setSort(const SortSelection('name'))
      ..setQuery('urlaub')
      ..clearQuery();

    expect(read('tags').query, '');
    expect(read('tags').sort, const SortSelection('name'));
  });

  test(
    'each screen keeps its own, so searching Konten does not filter Tags',
    () {
      notifier('accounts').setQuery('giro');

      expect(read('tags').query, '');
    },
  );
}
