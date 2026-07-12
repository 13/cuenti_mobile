import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../privacy/privacy_mode.dart';

/// Small icon + label + value chip used for compact stats within cards.
/// When [maskable] is true, the value is replaced with `•••••` while
/// privacy mode is on.
class StatChip extends ConsumerWidget {
  const StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.maskable = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool maskable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = DefaultTextStyle.of(context).style;
    final hidden = maskable && ref.watch(privacyModeProvider);
    final displayValue = hidden ? '•••••' : value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: textTheme.copyWith(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              displayValue,
              style: textTheme.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
