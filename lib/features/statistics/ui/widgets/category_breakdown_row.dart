import 'package:cuentimobile/core/widgets/privacy_blur.dart';
import 'package:cuentimobile/features/statistics/domain/category_breakdown.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:flutter/material.dart';

/// One category in the breakdown list: swatch, name, amount, share, and a
/// bar. Tappable when there is a level below it to drill into.
class CategoryBreakdownRow extends StatelessWidget {
  const CategoryBreakdownRow({
    required this.node,
    required this.color,
    required this.total,
    required this.currency,
    required this.hidden,
    required this.onDrillInto,
    super.key,
  });

  final CategoryNode node;
  final Color color;

  /// The level's total, which the share and the bar are measured against.
  final double total;
  final String currency;

  /// Whether privacy mode is blurring amounts.
  final bool hidden;

  final void Function(CategoryNode node) onDrillInto;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (node.total / total * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        // Keyed by name so a test -- and a screen reader walking the list --
        // can address one row without matching on the chip legend, which
        // renders an InkWell of its own around the same text.
        key: ValueKey('category-row-${node.name}'),
        onTap: node.hasChildren ? () => onDrillInto(node) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(node.name, overflow: TextOverflow.ellipsis),
                      ),
                      if (node.hasChildren)
                        const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
                // Percentages are inherently relative, so they stay
                // visible when privacy mode blurs the absolute amount.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hidden)
                      ExcludeSemantics(
                        child: PrivacyBlur(
                          child: Text(
                            '${formatNumber(node.total)} $currency',
                          ),
                        ),
                      )
                    else
                      Text('${formatNumber(node.total)} $currency'),
                    Text(' (${pct.toStringAsFixed(1)}%)'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: total > 0 ? node.total / total : 0,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ],
        ),
      ),
    );
  }
}
