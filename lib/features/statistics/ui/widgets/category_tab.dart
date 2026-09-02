import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/amount_text.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/section_header.dart';
import 'package:cuentimobile/features/categories/ui/categories_controller.dart';
import 'package:cuentimobile/features/statistics/domain/category_breakdown.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/category_breadcrumb.dart';
import 'package:cuentimobile/features/statistics/ui/widgets/category_breakdown_row.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The category breakdown for one period, drillable into subcategories.
///
/// The statistics endpoint sends amounts keyed by bare category name, so the
/// tree comes from joining those against the category list. That list is a
/// separate request: until it arrives -- or if it never does -- the chart
/// falls back to the flat breakdown it always showed, which is exactly what
/// [buildCategoryBreakdown] returns for no categories.
class CategoryTab extends ConsumerStatefulWidget {
  const CategoryTab({
    required this.data,
    required this.title,
    required this.currency,
    required this.type,
    super.key,
  });
  final Map<String, double> data;
  final String title;
  final String currency;
  final String type;

  @override
  ConsumerState<CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends ConsumerState<CategoryTab> {
  /// The categories drilled into, outermost first. Empty at the top level.
  List<String> _path = [];

  /// Walks [_path] down [roots], stopping wherever it no longer matches --
  /// a period with different categories must not strand the user on a level
  /// that no longer exists. Returns the path as far as it resolves and the
  /// node it lands on, null being the top level.
  ({List<String> path, CategoryNode? node}) _resolve(List<CategoryNode> roots) {
    final resolved = <String>[];
    CategoryNode? current;
    var level = roots;
    for (final name in _path) {
      final next = level.where((n) => n.name == name).firstOrNull;
      if (next == null || !next.hasChildren) break;
      resolved.add(name);
      current = next;
      level = next.children;
    }
    return (path: resolved, node: current);
  }

  /// What to draw at [node]: its children, plus an entry for anything
  /// booked on [node] itself. Without that entry, drilling into a category
  /// spent on directly would show less than the level above it claimed.
  List<CategoryNode> _entriesUnder(CategoryNode node, L l) {
    if (node.ownAmount <= 0) return node.children;
    return [
      ...node.children,
      CategoryNode(
        name: l.statsDirectAmount(node.name),
        id: null,
        ownAmount: node.ownAmount,
        children: const [],
      ),
    ]..sort((a, b) => b.total.compareTo(a.total));
  }

  void _drillInto(CategoryNode node) {
    if (!node.hasChildren) return;
    setState(() => _path = [..._path, node.name]);
  }

  void _popTo(int depth) => setState(() => _path = _path.sublist(0, depth));

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final hidden = ref.watch(privacyModeProvider);
    // A category list that is loading or failed leaves the breakdown flat
    // rather than empty: the amounts are already in hand.
    final categories = ref.watch(categoriesControllerProvider).value ?? [];
    final roots = buildCategoryBreakdown(
      widget.data,
      categories,
      type: widget.type,
    );

    final resolved = _resolve(roots);
    final path = resolved.path;
    final level = resolved.node == null
        ? roots
        : _entriesUnder(resolved.node!, l);
    final total = level.fold<double>(0, (sum, n) => sum + n.total);
    final palette = context.cuentiColors.chartPalette;
    final colors = List.generate(
      level.length,
      (i) => palette[i % palette.length],
    );

    return PopScope(
      // Inside a subcategory the back gesture belongs to the drill-down;
      // leaving the statistics screen from three levels deep would lose
      // every step at once.
      canPop: path.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && path.isNotEmpty) _popTo(path.length - 1);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(widget.title),
          if (path.isNotEmpty) CategoryBreadcrumb(path: path, onPopTo: _popTo),
          Row(
            children: [
              Text(l.statsTotal, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 4),
              AmountText(
                total,
                type: widget.type,
                currency: widget.currency,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (level.isNotEmpty) ...[
            SizedBox(
              height: 220,
              // Announced by name only: the same figures follow as real
              // text in the list below, which a screen reader can read.
              child: Semantics(
                label: l.a11yChartCategories,
                container: true,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    pieTouchData: PieTouchData(
                      // FlTapUpEvent, explicitly, is the completed tap.
                      // isInterestedForInteractions looks like the right
                      // guard and is not: it exists to drive hover
                      // highlighting, so it excludes the up events and
                      // admits the down ones. Gating on it drilled in the
                      // moment a finger landed -- so a scroll that began on
                      // the chart navigated instead -- and fired twice per
                      // tap besides.
                      touchCallback: (event, response) {
                        if (event is! FlTapUpEvent) return;
                        final index =
                            response?.touchedSection?.touchedSectionIndex;
                        if (index == null ||
                            index < 0 ||
                            index >= level.length) {
                          return;
                        }
                        _drillInto(level[index]);
                      },
                    ),
                    sections: List.generate(level.length, (i) {
                      final pct = total > 0
                          ? (level[i].total / total * 100)
                          : 0.0;
                      return PieChartSectionData(
                        value: level[i].total,
                        title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                        color: colors[i],
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(level.length, (i) {
                return Chip(
                  avatar: CircleAvatar(backgroundColor: colors[i], radius: 6),
                  label: Text(
                    level[i].name,
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }),
            ),
            const SizedBox(height: 16),
          ] else
            EmptyState(
              icon: Icons.pie_chart_outline,
              message: l.commonNoData,
            ),
          for (var i = 0; i < level.length; i++)
            CategoryBreakdownRow(
              node: level[i],
              color: colors[i],
              total: total,
              currency: widget.currency,
              hidden: hidden,
              onDrillInto: _drillInto,
            ),
        ],
      ),
    );
  }
}
