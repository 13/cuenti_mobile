import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../privacy/privacy_mode.dart';
import 'privacy_blur.dart';

/// Small icon + label + value chip used for compact stats within cards.
/// When [maskable] is true, the value is blurred via [PrivacyBlur] (and
/// excluded from semantics) while privacy mode is on.
///
/// [direction] controls the layout: [Axis.horizontal] (default) keeps
/// icon + label + value on one line; [Axis.vertical] stacks icon+label on
/// top and renders the value on its own line underneath at full chip
/// width — used where the value needs more room (e.g. the dashboard hero).
class StatChip extends ConsumerWidget {
  const StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.maskable = false,
    this.direction = Axis.horizontal,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool maskable;
  final Axis direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = DefaultTextStyle.of(context).style;
    final hidden = maskable && ref.watch(privacyModeProvider);

    Widget valueContent = Text(
      value,
      style: textTheme.copyWith(
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    if (hidden) {
      valueContent = ExcludeSemantics(
        child: PrivacyBlur(child: valueContent),
      );
    }
    // Vertical chips left-align the full-width value under the label;
    // horizontal chips keep FittedBox's default center alignment (the
    // original single-line contract).
    final valueText = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: direction == Axis.vertical
          ? Alignment.centerLeft
          : Alignment.center,
      child: valueContent,
    );

    final labelText = Flexible(
      child: Text(
        label,
        style: textTheme.copyWith(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (direction == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              labelText,
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(width: double.infinity, child: valueText),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        labelText,
        const SizedBox(width: 4),
        Flexible(child: valueText),
      ],
    );
  }
}
