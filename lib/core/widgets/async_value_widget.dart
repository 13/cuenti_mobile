import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'skeleton_loader.dart';

/// Standard loading/error/data switcher for AsyncValue-backed screens.
///
/// Loading falls back to [skeleton] ?? [loading] ?? a default
/// [SkeletonLoader.list]. Error shows [error] when provided, otherwise a
/// generic message card with a "Retry" button when [onRetry] is set.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.skeleton,
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget Function(Object error)? error;
  final Widget? skeleton;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => skeleton ?? loading ?? SkeletonLoader.list(),
      error: (e, _) => error?.call(e) ?? _ErrorCard(error: e, onRetry: onRetry),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error.toString(), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
