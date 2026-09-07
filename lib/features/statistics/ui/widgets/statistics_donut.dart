import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// One slice of a [StatisticsDonut].
class DonutSlice {
  const DonutSlice({
    required this.value,
    required this.label,
    required this.color,
    this.title = '',
    this.badge,
  });

  final double value;

  /// The slice's name, shown in the legend beneath the chart. Not the same
  /// thing as [title]: one donut paints figures on its slices and the other
  /// percentages, and neither of those says what the slice is.
  final String label;

  final Color color;

  /// Painted into the slice itself. Empty for a slice too thin to carry a
  /// label without it sitting over its neighbours.
  final String title;

  /// Drawn outward of [title], for a slice that says something about
  /// itself beyond its size -- a chevron for one that opens, say.
  final Widget? badge;
}

/// The donut both statistics charts are drawn with: the same hole, gap,
/// slice size, swell on touch, and legend, so a tap feels the same
/// wherever it lands.
///
/// A tap means different things to the two of them -- the overview donut
/// *reads* a slice into the hole, the category donut *opens* it -- so the
/// meaning is the caller's ([onSliceTap], [centre]) and only the feel is
/// shared. What is genuinely common is the trap below, which both charts
/// had learned separately and written down twice.
class StatisticsDonut extends StatefulWidget {
  const StatisticsDonut({
    required this.slices,
    required this.semanticsLabel,
    required this.height,
    this.onSliceTap,
    this.centre,
    super.key,
  });

  final List<DonutSlice> slices;

  /// fl_chart paints its slice titles into a canvas and drops the chart's
  /// children from the semantics tree, so without this the chart is
  /// several hundred silent pixels to a screen reader.
  final String semanticsLabel;

  /// Page layout rather than a donut effect, so it stays the caller's: one
  /// of these carries a longer legend beneath it than the other.
  final double height;

  /// Called on every completed tap on a slice, whatever the swell does.
  final ValueChanged<int>? onSliceTap;

  /// Builds what sits in the hole for the slice showing, if the caller
  /// puts anything there. The hole is the one place a reading can sit
  /// without covering the thing it describes -- a pie has no tooltip
  /// layer in fl_chart.
  final Widget Function(BuildContext context, int index)? centre;

  @override
  State<StatisticsDonut> createState() => _StatisticsDonutState();
}

class _StatisticsDonutState extends State<StatisticsDonut> {
  static const _holeRadius = 45.0;
  static const _sliceSpace = 3.0;
  static const _sliceRadius = 46.0;
  static const _touchedRadius = 54.0;
  static const _titleStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// The slice drawn large, or null for none.
  int? _touched;

  @override
  void didUpdateWidget(StatisticsDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Opening a slice replaces every slice, and the swell belonged to the
    // one under the finger -- not to its index in whatever comes next.
    if (!_sameSlices(oldWidget.slices, widget.slices)) _touched = null;
  }

  /// By name, so that a rebuild which only restates the same slices --
  /// privacy mode masking the figures painted on them, say -- does not
  /// count as a new set and drop the swell.
  static bool _sameSlices(List<DonutSlice> a, List<DonutSlice> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].label != b[i].label) return false;
    }
    return true;
  }

  void _onTouch(FlTouchEvent event, PieTouchResponse? response) {
    // FlTapUpEvent, explicitly, is the completed tap.
    // isInterestedForInteractions looks like the right guard and is not:
    // it exists to drive hover highlighting, so it excludes the up events
    // and admits the down ones. Gating on it fired twice per tap and
    // reacted before a finger had lifted -- on the category donut that
    // meant a scroll which began on the chart opened a slice instead.
    if (event is! FlTapUpEvent) return;
    final index = response?.touchedSection?.touchedSectionIndex;
    if (index == null || index < 0 || index >= widget.slices.length) return;
    // Tapping the slice already showing puts it back, so a reading can be
    // dismissed without hunting for a gap.
    setState(() => _touched = _touched == index ? null : index);
    widget.onSliceTap?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final touched = _touched;
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: Semantics(
            label: widget.semanticsLabel,
            container: true,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: _sliceSpace,
                    centerSpaceRadius: _holeRadius,
                    pieTouchData: PieTouchData(touchCallback: _onTouch),
                    sections: [
                      for (var i = 0; i < widget.slices.length; i++)
                        _sectionFor(i),
                    ],
                  ),
                ),
                if (touched != null && widget.centre != null)
                  widget.centre!(context, touched),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final slice in widget.slices) _legendChip(slice),
          ],
        ),
      ],
    );
  }

  PieChartSectionData _sectionFor(int index) {
    final slice = widget.slices[index];
    return PieChartSectionData(
      value: slice.value,
      title: slice.title,
      color: slice.color,
      radius: _touched == index ? _touchedRadius : _sliceRadius,
      badgeWidget: slice.badge,
      // Outward of the title, which sits at the default 0.5, so the two do
      // not overlap.
      badgePositionPercentageOffset: 0.85,
      titleStyle: _titleStyle,
    );
  }

  Widget _legendChip(DonutSlice slice) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: slice.color, radius: 6),
      label: Text(slice.label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
