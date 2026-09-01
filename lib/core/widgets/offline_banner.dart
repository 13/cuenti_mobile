import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// A strip saying the figures on screen came from the last successful fetch
/// rather than from the server just now.
///
/// Shown rather than swapped in silently: in an app about money, stale
/// numbers that look live are worse than no numbers.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.stale, super.key});

  /// Driven by the API layer, true while responses are being replayed from
  /// cache.
  final ValueNotifier<bool> stale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: stale,
      builder: (context, isStale, _) {
        if (!isStale) return const SizedBox.shrink();
        return Material(
          color: colors.tertiaryContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 18,
                    color: colors.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      L.of(context).offlineBanner,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
