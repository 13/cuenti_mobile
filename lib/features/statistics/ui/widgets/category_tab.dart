import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/amount_text.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/privacy_blur.dart';
import 'package:cuentimobile/core/widgets/section_header.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryTab extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(privacyModeProvider);
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<double>(0, (sum, e) => sum + e.value);
    final palette = context.cuentiColors.chartPalette;
    final colors = List.generate(
      sorted.length,
      (i) => palette[i % palette.length],
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(title),
        Row(
          children: [
            Text(
              L.of(context).statsTotal,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            AmountText(
              total,
              type: type,
              currency: currency,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Pie chart for categories
        if (sorted.isNotEmpty) ...[
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(sorted.length, (i) {
                  final pct = total > 0 ? (sorted[i].value / total * 100) : 0.0;
                  return PieChartSectionData(
                    value: sorted[i].value,
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
          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(sorted.length, (i) {
              return Chip(
                avatar: CircleAvatar(backgroundColor: colors[i], radius: 6),
                label: Text(
                  sorted[i].key,
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
            message: L.of(context).commonNoData,
          ),

        ...sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final pct = total > 0 ? (e.value / total * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[i],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(e.key, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    // Percentages are inherently relative, so they stay
                    // visible when privacy mode blurs the absolute amount.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hidden)
                          ExcludeSemantics(
                            child: PrivacyBlur(
                              child: Text('${formatNumber(e.value)} $currency'),
                            ),
                          )
                        else
                          Text('${formatNumber(e.value)} $currency'),
                        Text(' (${pct.toStringAsFixed(1)}%)'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: total > 0 ? e.value / total : 0,
                  color: colors[i],
                  backgroundColor: colors[i].withValues(alpha: 0.12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
