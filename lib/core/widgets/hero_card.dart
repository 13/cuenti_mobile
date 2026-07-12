import 'package:flutter/material.dart';
import '../theme/cuenti_colors.dart';

/// Brand gradient card used for headline metrics (dashboard hero, etc.).
/// Forces white-ish foreground for its [child] via [DefaultTextStyle] /
/// [IconTheme] so callers don't need to set colors explicitly.
class HeroCard extends StatelessWidget {
  const HeroCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: context.cuentiColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: IconTheme(
          data: const IconThemeData(color: Colors.white),
          child: child,
        ),
      ),
    );
  }
}
