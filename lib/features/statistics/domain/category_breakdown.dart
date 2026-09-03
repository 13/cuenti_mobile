import 'package:cuentimobile/features/categories/domain/category.dart';

/// One category in the breakdown, with whatever sits beneath it.
///
/// [ownAmount] is what was booked directly on this category; [total] adds
/// what its children hold. The two are kept apart so a parent that is also
/// spent on directly can show both without counting either twice.
class CategoryNode {
  CategoryNode({
    required this.name,
    required this.id,
    required this.ownAmount,
    required this.children,
  });

  final String name;

  /// Null for a name the category list does not account for -- the amount
  /// is still real, so it is shown, just with nothing to drill into.
  final int? id;

  final double ownAmount;
  final List<CategoryNode> children;

  bool get hasChildren => children.isNotEmpty;

  double get total =>
      ownAmount + children.fold<double>(0, (sum, c) => sum + c.total);
}

/// Arranges [amountsByName] -- what the statistics endpoint reports, keyed
/// by bare category name -- into the tree that [categories] describes,
/// keeping only the branches that carry an amount.
///
/// The endpoint sends no hierarchy, so the join is by name against the
/// categories of this [type]. Two rules keep that join honest:
///
///  * a name no category of this type claims stays a top-level entry, which
///    is how it rendered before there was a tree at all; and
///  * a name claimed by more than one category is ambiguous, so it is left
///    top-level too rather than filed under a parent that may be wrong.
///
/// Both keep every amount visible: no level ever totals less than the sum
/// of what it contains.
List<CategoryNode> buildCategoryBreakdown(
  Map<String, double> amountsByName,
  List<Category> categories, {
  required String type,
}) {
  final ofType = categories.where(
    (c) => _fold(c.type) == _fold(type) && c.id != null,
  );

  // Names claimed by exactly one category can be placed; the rest cannot.
  // Folded, because the two sides of this join come from different
  // endpoints: a server that spells a type "expense" or pads a name must
  // not silently match nothing and flatten the whole chart.
  //
  // Indexed by full path as well as by bare name, and the path is tried
  // first. This backend names a category by its path -- the captured
  // responses in test/fixtures hold 'Wohnen:Miete', not 'Miete' -- and
  // matching only the leaf meant every amount failed the join, landed in
  // `unplaced`, and became a childless root. The chart drew the right
  // numbers and nothing could be drilled into, because there was no tree
  // left to drill. The path is the more specific key too: it separates an
  // 'Auto:Tanken' from a 'Boot:Tanken', which the bare name has to refuse.
  final byName = <String, List<Category>>{};
  final byFullName = <String, List<Category>>{};
  for (final c in ofType) {
    byName.putIfAbsent(_fold(c.name), () => []).add(c);
    final full = c.fullName;
    if (full != null && full.trim().isNotEmpty) {
      byFullName.putIfAbsent(_fold(full), () => []).add(c);
    }
  }
  Map<String, Category> claimedOnce(Map<String, List<Category>> index) => {
    for (final entry in index.entries)
      if (entry.value.length == 1) entry.key: entry.value.single,
  };
  final byPath = claimedOnce(byFullName);
  final byLeaf = claimedOnce(byName);
  final byId = {for (final c in ofType) c.id!: c};

  final ownById = <int, double>{};
  final unplaced = <String, double>{};
  for (final entry in amountsByName.entries) {
    final key = _fold(entry.key);
    final category = byPath[key] ?? byLeaf[key];
    if (category == null) {
      unplaced[entry.key] = (unplaced[entry.key] ?? 0) + entry.value;
    } else {
      ownById[category.id!] = (ownById[category.id!] ?? 0) + entry.value;
    }
  }

  // Only the categories on a path from a root down to an amount matter;
  // the rest would draw empty slices. Walking up from each amount also
  // settles who each node hangs from, once: a node already decided by an
  // earlier walk stops this one, since its chain above is already built.
  final relevant = <int>{};
  final parentOf = <int, int?>{};
  for (final id in ownById.keys) {
    final path = <int>{};
    int? current = id;
    while (current != null &&
        !parentOf.containsKey(current) &&
        path.add(current)) {
      relevant.add(current);
      final next = byId[current]?.parentId;
      // No parent, a parent the list does not describe, or a parent already
      // on this path -- a cycle. All three make this node a root, which is
      // what keeps a cycle from swallowing the amount beneath it instead of
      // showing it somewhere.
      if (next == null || !byId.containsKey(next) || path.contains(next)) {
        parentOf[current] = null;
        break;
      }
      parentOf[current] = next;
      current = next;
    }
  }

  final childIds = <int, List<int>>{};
  final rootIds = <int>[];
  for (final id in relevant) {
    final parentId = parentOf[id];
    if (parentId == null) {
      rootIds.add(id);
    } else {
      childIds.putIfAbsent(parentId, () => []).add(id);
    }
  }

  CategoryNode nodeFor(int id) => CategoryNode(
    name: byId[id]!.name,
    id: id,
    ownAmount: ownById[id] ?? 0,
    children: _sorted([
      for (final child in childIds[id] ?? const <int>[]) nodeFor(child),
    ]),
  );

  return _sorted([
    for (final id in rootIds) nodeFor(id),
    for (final entry in unplaced.entries)
      CategoryNode(
        name: entry.key,
        id: null,
        ownAmount: entry.value,
        children: const [],
      ),
  ]);
}

/// The form names and types are compared in. Folding case and padding
/// keeps the join working across two endpoints that need not agree on
/// either; the ambiguity rule above still refuses to place a name once
/// folding makes two categories collide, so this widens what matches
/// without letting anything match the wrong thing.
String _fold(String value) => value.trim().toLowerCase();

/// Largest first, the order the chart and the list both read in.
List<CategoryNode> _sorted(List<CategoryNode> nodes) =>
    nodes..sort((a, b) => b.total.compareTo(a.total));
