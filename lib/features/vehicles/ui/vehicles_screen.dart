import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/cuenti_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../utils/number_format.dart';
import '../../auth/ui/auth_controller.dart';
import '../../categories/domain/category.dart';
import '../../categories/ui/categories_controller.dart';
import '../../user/data/user_repository.dart';
import '../domain/vehicle_report.dart';
import 'vehicles_controller.dart';

class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  int? _categoryId;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _categoryId = ref.read(authControllerProvider).user?.defaultVehicleCategoryId;
    final now = DateTime.now();
    _start = DateTime(now.year, 1, 1);
    _end = DateTime(now.year, 12, 31);
  }

  bool get _isThisYear {
    final now = DateTime.now();
    return _start == DateTime(now.year, 1, 1) && _end == DateTime(now.year, 12, 31);
  }

  @override
  Widget build(BuildContext context) {
    final categoryId = _categoryId;
    if (categoryId == null) {
      return Center(
        child: EmptyState(
          icon: Icons.directions_car,
          message: 'Pick a fuel category to see your vehicle report',
          actionLabel: 'Choose category',
          onAction: () => _openCategorySheet(context),
        ),
      );
    }

    final reportProv = vehicleReportProvider(
      categoryId: categoryId,
      start: _start,
      end: _end,
    );
    final reportAsync = ref.watch(reportProv);

    return Column(
      children: [
        _buildChipsRow(context),
        const SizedBox(height: 4),
        Expanded(
          child: AsyncValueWidget<VehicleReport>(
            value: reportAsync,
            skeleton: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SkeletonLoader.card(height: 120),
                const SizedBox(height: 24),
                SkeletonLoader.card(height: 220),
                const SizedBox(height: 24),
                SkeletonLoader.tiles(),
              ],
            ),
            onRetry: () => ref.invalidate(reportProv),
            data: (report) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatCardsRow(report: report),
                const SizedBox(height: 24),
                const SectionHeader('Consumption'),
                const SizedBox(height: 8),
                _ConsumptionChart(entries: report.entries),
                const SizedBox(height: 24),
                const SectionHeader('Entries'),
                const SizedBox(height: 8),
                _EntriesList(entries: report.entries, currency: report.currency),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipsRow(BuildContext context) {
    final categories = ref.watch(categoriesControllerProvider).value ?? [];
    final selected = _categoryById(categories, _categoryId);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          InputChip(
            avatar: const Icon(Icons.directions_car, size: 18),
            label: Text(selected != null ? (selected.fullName ?? selected.name) : 'Category'),
            onPressed: () => _openCategorySheet(context),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('This year'),
            selected: _isThisYear,
            onSelected: (v) {
              if (!v) return;
              final now = DateTime.now();
              setState(() {
                _start = DateTime(now.year, 1, 1);
                _end = DateTime(now.year, 12, 31);
              });
            },
          ),
          const SizedBox(width: 8),
          InputChip(
            avatar: const Icon(Icons.date_range_outlined, size: 18),
            label: Text(_isThisYear ? 'Custom range' : '${_shortDate(_start)} – ${_shortDate(_end)}'),
            onPressed: () => _pickCustomRange(context),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

  Category? _categoryById(List<Category> categories, int? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (picked != null && mounted) {
      setState(() {
        _start = picked.start;
        _end = picked.end;
      });
    }
  }

  Future<void> _openCategorySheet(BuildContext context) async {
    final categories = ref.read(categoriesControllerProvider).value ?? [];
    final expenseCategories = categories.where((c) => c.type == 'EXPENSE').toList();

    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final defaultId = ref.watch(authControllerProvider).user?.defaultVehicleCategoryId;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Fuel category', style: Theme.of(ctx).textTheme.titleMedium),
                  ),
                ),
                for (final c in expenseCategories)
                  ListTile(
                    title: Text(c.fullName ?? c.name),
                    onTap: () => Navigator.pop(ctx, c.id),
                    trailing: IconButton(
                      icon: Icon(
                        defaultId == c.id ? Icons.star : Icons.star_border,
                        color: defaultId == c.id ? Theme.of(ctx).colorScheme.primary : null,
                      ),
                      tooltip: 'Set as default',
                      onPressed: () async {
                        await _setDefaultCategory(context, c.id!);
                        // Also select the starred category for the current
                        // view: close the sheet returning its id so
                        // _categoryId updates and the EmptyState doesn't
                        // linger after setting a default.
                        if (ctx.mounted) Navigator.pop(ctx, c.id);
                      },
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
    if (selected != null && mounted) {
      setState(() => _categoryId = selected);
    }
  }

  Future<void> _setDefaultCategory(BuildContext context, int id) async {
    await ref.read(userRepositoryProvider).updatePreferences({
      'defaultVehicleCategoryId': id,
    });
    await ref.read(authControllerProvider.notifier).refreshProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default saved')),
    );
  }
}

class _StatCardsRow extends StatelessWidget {
  final VehicleReport report;
  const _StatCardsRow({required this.report});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
          label: 'Total cost',
          valueWidget: AmountText(
            report.totalCost,
            currency: report.currency,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        _StatCard(
          label: 'Liters',
          valueWidget: Text(
            '${formatNumber(report.totalLiters, decimals: 1)} L',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        _StatCard(
          label: 'Distance',
          valueWidget: Text(
            '${formatNumber(report.totalDistance, decimals: 0)} km',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        _StatCard(
          label: '⌀ Consumption',
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
        _StatCard(
          label: '⌀ Price/L',
          valueWidget: Text(
            report.avgPricePerLiter != null
                ? '${report.avgPricePerLiter!.toStringAsFixed(3)} ${report.currency}'
                : '—',
            style: const TextStyle(
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

class _StatCard extends StatelessWidget {
  final String label;
  final Widget valueWidget;
  const _StatCard({required this.label, required this.valueWidget});

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

class _ConsumptionChart extends StatelessWidget {
  final List<FuelEntry> entries;
  const _ConsumptionChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final points = entries.where((e) => e.consumption != null).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (points.length < 2) {
      return const SizedBox(
        height: 200,
        child: EmptyState(icon: Icons.show_chart, message: 'Not enough data for a chart'),
      );
    }

    final cuenti = context.cuentiColors;
    final colorScheme = Theme.of(context).colorScheme;
    final lineColor = cuenti.chartPalette[0];
    final gridColor = colorScheme.outlineVariant.withValues(alpha: 0.5);
    final dateFmt = DateFormat('d MMM');

    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].consumption!),
    ];

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < points.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(dateFmt.format(points[idx].date), style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            getTouchedSpotIndicator: (barData, indexes) => indexes.map((i) {
              return TouchedSpotIndicatorData(
                FlLine(color: lineColor, strokeWidth: 2),
                FlDotData(
                  getDotPainter: (spot, percent, bar, idx) => FlDotCirclePainter(
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
              getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                '${formatNumber(s.y, decimals: 1)} l/100km',
                TextStyle(color: lineColor, fontWeight: FontWeight.bold),
              )).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
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
      ),
    );
  }
}

class _EntriesList extends StatelessWidget {
  final List<FuelEntry> entries;
  final String currency;
  const _EntriesList({required this.entries, required this.currency});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(icon: Icons.local_gas_station, message: 'No fuel entries in this period');
    }

    final dateFmt = DateFormat('d MMM yyyy');

    return Column(
      children: entries.map((e) {
        final subtitleParts = <String>[
          if (e.odometer != null) '${formatNumber(e.odometer!, decimals: 0)} km',
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
                    Text('${formatNumber(e.consumption!, decimals: 1)} l/100km'),
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
                    const Chip(
                      label: Text('Full', style: TextStyle(fontSize: 10)),
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
