import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../privacy/privacy_mode.dart';

/// Blurs its child when privacy mode is on. Layout keeps the child's size,
/// so callers can wrap the real (unmasked) content instead of substituting
/// a placeholder string like '•••••' — the actual value stays in the
/// widget tree (and in semantics, unless the caller also excludes it), just
/// visually obscured.
class PrivacyBlur extends ConsumerWidget {
  const PrivacyBlur({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(privacyModeProvider);
    if (!hidden) return child;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 7,
        sigmaY: 7,
        tileMode: TileMode.decal,
      ),
      child: child,
    );
  }
}
