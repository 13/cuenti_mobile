import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/token_search.dart';
import 'package:flutter/material.dart';

/// One chip in an [EntityListHeader]'s sort row: what it is called, and how
/// it orders the list.
///
/// A null [compare] means "leave the order the server sent" -- the Konten
/// screen's custom order, which the user arranges by dragging and which no
/// comparator could reproduce.
class SortOption<T> {
  const SortOption({required this.id, required this.label, this.compare});

  /// Stable across rebuilds and locales, so the selected chip survives a
  /// language change that rewrites every [label].
  final String id;
  final String label;
  final Comparator<T>? compare;

  bool get isManual => compare == null;
}

/// Filters [items] to those matching [query], then orders what survives.
///
/// Filtering runs first so the comparator only sees rows that will be shown.
/// Equal keys keep the order they arrived in -- sorting accounts by type
/// leaves each type block in the custom order the user dragged it into,
/// rather than shuffling it differently on every rebuild.
List<T> applySearchAndSort<T>(
  List<T> items, {
  required String query,
  required String Function(T) searchText,
  SortOption<T>? sort,
  bool descending = false,
}) {
  final filtered = [
    for (final item in items)
      if (matchesAllTokens(searchText(item), query)) item,
  ];

  final compare = sort?.compare;
  if (compare == null) return filtered;

  // Decorated with the arrival index, which breaks ties: List.sort is not
  // stable on its own.
  final decorated = filtered.indexed.toList()
    ..sort((a, b) {
      final result = compare(a.$2, b.$2);
      if (result != 0) return descending ? -result : result;
      return a.$1.compareTo(b.$1);
    });

  return [for (final (_, item) in decorated) item];
}

/// Which sort chip is active, and which way it points.
@immutable
class SortSelection {
  const SortSelection(this.id, {this.descending = false});

  /// Nothing chosen: the list keeps the order the server sent. Screens with
  /// no meaningful manual order start here, so their chips read as "off"
  /// until the user picks one.
  static const none = SortSelection('');

  final String id;
  final bool descending;

  @override
  bool operator ==(Object other) =>
      other is SortSelection &&
      other.id == id &&
      other.descending == descending;

  @override
  int get hashCode => Object.hash(id, descending);

  @override
  String toString() => 'SortSelection($id, descending: $descending)';
}

/// The search field and sort chips the Verwaltung screens share.
///
/// The six of them -- Konten, Empfaenger, Kategorien, Tags, Waehrungen,
/// Anlagen -- want the same header over lists of very different things, so
/// the sort keys arrive as [options] and the entity type only shows up in
/// their comparators.
///
/// The caller owns the query and the selection: this widget reports taps and
/// keystrokes and draws what it is given, which keeps "clear the filters"
/// something the screen can do from its empty state.
class EntityListHeader<T> extends StatelessWidget {
  const EntityListHeader({
    required this.searchController,
    required this.searchHint,
    required this.onSearchChanged,
    required this.options,
    required this.selected,
    required this.onSortChanged,
    super.key,
  });

  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final List<SortOption<T>> options;
  final SortSelection selected;
  final ValueChanged<SortSelection> onSortChanged;

  /// A tap on the active chip reverses it; a tap on any other switches to it
  /// ascending. The manual chip has no direction to reverse, so tapping it
  /// while active does nothing rather than pretending to flip a dragged
  /// order.
  void _onChipTapped(SortOption<T> option) {
    if (option.id != selected.id) {
      onSortChanged(SortSelection(option.id));
      return;
    }
    if (option.isManual) return;
    onSortChanged(SortSelection(option.id, descending: !selected.descending));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: onSearchChanged,
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final option = options[i];
              final active = option.id == selected.id;
              return FilterChip(
                label: Text(option.label),
                selected: active,
                // The arrow says which way it sorts, which a check mark
                // cannot, so it takes the avatar slot instead.
                showCheckmark: false,
                // The arrow is the only thing saying which way the sort
                // runs, and an icon says nothing out loud.
                avatar: active && !option.isManual
                    ? Semantics(
                        label: selected.descending
                            ? L.of(context).sortDescending
                            : L.of(context).sortAscending,
                        child: Icon(
                          selected.descending
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 18,
                        ),
                      )
                    : null,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => _onChipTapped(option),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The option [selection] names, or null when it names none -- in which case
/// [applySearchAndSort] leaves the order alone.
SortOption<T>? sortOptionFor<T>(
  List<SortOption<T>> options,
  SortSelection selection,
) {
  for (final option in options) {
    if (option.id == selection.id) return option;
  }
  return null;
}
