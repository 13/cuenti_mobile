import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/amount_text.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/features/vehicles/domain/vehicle_report.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/chart_labels.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The read-only halves of the vehicles screen: the figures, the chart and
/// the list of fill-ups.
///
/// They were private classes inside a 539-line screen file, which made them
/// reachable only by building the whole screen -- a category has to be
/// chosen, a report stubbed, a chart laid out -- to assert on any one of
/// them. Public and on their own, each takes a [VehicleReport] and can be
/// pumped directly.

class VehicleStatCards extends StatelessWidget {
  const VehicleStatCards({required this.report, super.key});
  final VehicleReport report;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        VehicleStatCard(
          label: L.of(context).vehiclesTotalCost,
          valueWidget: AmountText(
            report.totalCost,
            currency: report.currency,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        VehicleStatCard(
          label: L.of(context).fuelLiters,
          valueWidget: Text(
            '${formatNumber(report.totalLiters, decimals: 1)} L',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        VehicleStatCard(
          label: L.of(context).vehiclesDistance,
          valueWidget: Text(
            '${formatNumber(report.totalDistance, decimals: 0)} km',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        VehicleStatCard(
          label: L.of(context).vehiclesAvgConsumption,
          valueWidget: Text(
            report.avgConsumption != null
                ? '${formatNumber(report.avgConsumption!, decimals: 1)} l/100km'
                : '—',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        VehicleStatCard(
          label: L.of(context).vehiclesAvgPricePerLiter,
          // Three decimals because fuel is priced to a tenth of a cent, but
          // otherwise an amount like any other: the currency's punctuation,
          // and hidden along with the rest under privacy mode.
          valueWidget: report.avgPricePerLiter != null
              ? AmountText(
                  report.avgPricePerLiter!,
                  currency: report.currency,
                  fractionDigits: 3,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : const Text(
                  '—',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
        ),
      ],
    );
  }
}

class VehicleStatCard extends StatelessWidget {
  const VehicleStatCard({
    required this.label,
    required this.valueWidget,
    super.key,
  });
  final String label;
  final Widget valueWidget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              valueWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class ConsumptionChart extends StatelessWidget {
  const ConsumptionChart({required this.entries, super.key});
  final List<FuelEntry> entries;

  @override
  Widget build(BuildContext context) {
    final points = entries.where((e) => e.consumption != null).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (points.length < 2) {
      return SizedBox(
        height: 200,
        child: EmptyState(
          icon: Icons.show_chart,
          message: L.of(context).vehiclesNotEnoughData,
        ),
      );
    }

    final cuenti = context.cuentiColors;
    final colorScheme = Theme.of(context).colorScheme;
    final lineColor = cuenti.chartPalette[0];
    final gridColor = colorScheme.outlineVariant.withValues(alpha: 0.5);
    final dateFmt = DateFormat('d MMM');

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].consumption!),
    ];

    return SizedBox(
      height: 200,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stride = labelStride(
            pointCount: points.length,
            width: constraints.maxWidth,
          );
          return LineChart(
            LineChartData(
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: gridColor, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    // One tick per fill-up. Without it fl_chart chooses its own
                    // positions, and a tick at 1.5 used to truncate to 1 and
                    // print that point's date a second time, under nothing.
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value != value.roundToDouble()) {
                        return const SizedBox.shrink();
                      }
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox.shrink();
                      }
                      if (!showsLabel(idx, points.length, stride)) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          dateFmt.format(points[idx].date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                getTouchedSpotIndicator: (barData, indexes) => indexes.map((i) {
                  return TouchedSpotIndicatorData(
                    FlLine(color: lineColor),
                    FlDotData(
                      getDotPainter: (spot, percent, bar, idx) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: lineColor,
                            strokeWidth: 2,
                            strokeColor: colorScheme.surface,
                          ),
                    ),
                  );
                }).toList(),
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.surfaceContainerHighest,
                  // The date as well as the figure: once labels are thinned,
                  // it is the only way to tell which fill-up is under a finger.
                  // Text wears text ink, not the series colour -- the line
                  // beside it already carries the identity.
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        '${dateFmt.format(points[s.x.toInt()].date)}\n'
                        '${formatNumber(s.y, decimals: 1)} l/100km',
                        TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  // A point per fill-up: 8px across with a surface-coloured
                  // ring, so a dot stays legible where the line runs under it.
                  dotData: FlDotData(
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                          radius: 4,
                          color: lineColor,
                          strokeWidth: 2,
                          strokeColor: colorScheme.surface,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        lineColor.withValues(alpha: 0.35),
                        lineColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FuelEntriesList extends StatelessWidget {
  const FuelEntriesList({
    required this.entries,
    required this.currency,
    super.key,
  });
  final List<FuelEntry> entries;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return EmptyState(
        icon: Icons.local_gas_station,
        message: L.of(context).vehiclesNoEntries,
      );
    }

    final dateFmt = DateFormat('d MMM yyyy');

    return Column(
      children: entries.map((e) {
        final subtitleParts = <String>[
          if (e.odometer != null)
            '${formatNumber(e.odometer!, decimals: 0)} km',
          if (e.liters != null) '${formatNumber(e.liters!, decimals: 1)} L',
        ];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.local_gas_station)),
              title: Text('${dateFmt.format(e.date)} · ${e.station ?? 'Fuel'}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (subtitleParts.isNotEmpty) Text(subtitleParts.join(' · ')),
                  if (e.consumption != null)
                    Text(
                      '${formatNumber(e.consumption!, decimals: 1)} l/100km',
                    ),
                ],
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AmountText(
                    e.amount ?? 0,
                    currency: e.currency ?? currency,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (e.fullTank) ...[
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(
                        L.of(context).vehiclesFull,
                        style: const TextStyle(fontSize: 10),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
