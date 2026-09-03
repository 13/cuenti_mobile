import 'dart:math' as math;

/// Roughly what one date label occupies, including the gap to its neighbour.
const _labelWidth = 48.0;

/// How many points to step between axis labels so they do not overlap.
///
/// A chart of fill-ups has as many points as the reader has refuelled, which
/// is fine at six and unreadable at thirty. Rather than dropping to a fixed
/// number of ticks -- which puts labels between points, where nothing is
/// plotted -- the axis keeps labelling real points and simply skips some.
///
/// Always at least 1: a stride of zero would label nothing and divide by
/// itself on the way there.
int labelStride({required int pointCount, required double width}) {
  if (pointCount <= 1) return 1;
  final fits = (width / _labelWidth).floor();
  // Two is the fewest worth drawing: the first point and the last.
  if (fits <= 2) return pointCount;
  return math.max(1, (pointCount / fits).ceil());
}

/// Whether the point at [index] carries a label.
///
/// The ends always do -- they say what range the chart covers -- and the
/// points between fall on [stride]. One that lands too close to the final
/// point is dropped, since the last label is drawn regardless and the two
/// would sit on top of each other.
bool showsLabel(int index, int pointCount, int stride) {
  if (index <= 0 || index >= pointCount - 1) return true;
  if (index % stride != 0) return false;
  return pointCount - 1 - index >= stride;
}
