import 'package:flutter/material.dart';

/// Small icon + label + value chip used for compact stats within cards.
class StatChip extends StatelessWidget {
  const StatChip({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = DefaultTextStyle.of(context).style;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label, style: textTheme.copyWith(fontSize: 12)),
        const SizedBox(width: 4),
        Text(value, style: textTheme.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
