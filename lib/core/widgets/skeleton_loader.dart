import 'package:flutter/material.dart';

enum _SkeletonKind { list, card, tiles }

/// Placeholder shimmer shown while data is loading. Built from simple
/// rounded rectangles pulsed via an [AnimationController] (no external
/// shimmer package). The pulse is skipped when the platform/test
/// environment requests reduced motion
/// (`MediaQuery.disableAnimationsOf`).
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader._(
    this._kind, {
    this.items = 1,
    this.height = 160,
    super.key,
  });

  factory SkeletonLoader.list({int items = 6, Key? key}) =>
      SkeletonLoader._(_SkeletonKind.list, items: items, key: key);

  factory SkeletonLoader.card({double height = 160, Key? key}) =>
      SkeletonLoader._(_SkeletonKind.card, height: height, key: key);

  factory SkeletonLoader.tiles({int items = 3, double height = 72, Key? key}) =>
      SkeletonLoader._(
        _SkeletonKind.tiles,
        items: items,
        height: height,
        key: key,
      );

  final _SkeletonKind _kind;
  final int items;
  final double height;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(double height, Color baseColor) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.5 + (_controller.value * 0.4);
        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// A stack of `widget.items` bars, trimmed to what the height can hold.
  ///
  /// A placeholder that overflows its box paints the debug stripes over the
  /// screen it is standing in for, so it draws only the bars that fit --
  /// which is all a skeleton needs to do. Height is unbounded when it sits
  /// inside a scroll view (the dashboard stacks it that way), and then every
  /// bar is drawn.
  Widget _bars(double barHeight, Color baseColor) {
    const gap = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxHeight.isFinite
            ? (constraints.maxHeight / (barHeight + gap)).floor().clamp(
                0,
                widget.items,
              )
            : widget.items;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: gap),
                child: _bar(barHeight, baseColor),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    switch (widget._kind) {
      case _SkeletonKind.list:
        return _bars(56, baseColor);
      case _SkeletonKind.card:
        return _bar(widget.height, baseColor);
      case _SkeletonKind.tiles:
        return _bars(widget.height, baseColor);
    }
  }
}
