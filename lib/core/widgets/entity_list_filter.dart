import 'package:cuentimobile/core/widgets/entity_list_header.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'entity_list_filter.g.dart';

/// What a list screen is currently showing: the text searched for, and the
/// chip sorting it.
class EntityFilter {
  const EntityFilter({
    this.query = '',
    this.sort = SortSelection.none,
  });

  final String query;
  final SortSelection sort;

  EntityFilter copyWith({String? query, SortSelection? sort}) =>
      EntityFilter(query: query ?? this.query, sort: sort ?? this.sort);
}

/// The search and sort a list screen is holding, kept per [screen].
///
/// It lives outside the widget because the screens are rebuilt from scratch
/// on every navigation: state held in the State object meant that stepping
/// into an account and back threw away what had been typed. Kept alive for
/// the session, and separate per screen so a search on Konten does not
/// follow the reader into Tags.
@Riverpod(keepAlive: true)
class EntityListFilter extends _$EntityListFilter {
  @override
  EntityFilter build(String screen) => const EntityFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setSort(SortSelection sort) => state = state.copyWith(sort: sort);

  /// Drops the search but leaves the sort alone: clearing a filter that
  /// found nothing is not a request to undo the ordering as well.
  void clearQuery() => state = state.copyWith(query: '');
}
