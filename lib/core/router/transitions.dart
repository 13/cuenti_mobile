import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Fade + slight scale transition used for top-level page navigation.
/// Respects reduced-motion settings by returning a [NoTransitionPage]
/// when `MediaQuery.disableAnimationsOf` is true for the given context.
Page<void> fadeThroughPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      );
      final scale = Tween<double>(begin: 0.98, end: 1).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}
