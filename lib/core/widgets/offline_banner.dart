import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A strip saying the figures on screen came from the last successful fetch
/// rather than from the server just now.
///
/// Shown rather than swapped in silently: in an app about money, stale
/// numbers that look live are worse than no numbers.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.stale, required this.since, super.key});

  /// Driven by the API layer, true while responses are being replayed from
  /// cache.
  final ValueNotifier<bool> stale;

  /// When the replayed figures were originally fetched. Saying "offline"
  /// without saying how old is the difference between a number a user can
  /// act on and one they cannot.
  final ValueNotifier<DateTime?> since;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: stale,
      builder: (context, isStale, _) {
        if (!isStale) return const SizedBox.shrink();
        return ValueListenableBuilder<DateTime?>(
          valueListenable: since,
          builder: (context, fetchedAt, _) => _bar(context, fetchedAt),
        );
      },
    );
  }

  Widget _bar(BuildContext context, DateTime? fetchedAt) {
    final colors = Theme.of(context).colorScheme;
    final l = L.of(context);
    final message = fetchedAt == null
        ? l.offlineBanner
        : l.offlineBannerSince(_formatWhen(fetchedAt));
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
                  message,
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
  }

  /// Today's figures need only the time; older ones need the date, and both
  /// follow the user's locale.
  String _formatWhen(DateTime when) {
    final now = DateTime.now();
    final sameDay =
        when.year == now.year && when.month == now.month && when.day == now.day;
    return sameDay
        ? DateFormat.Hm().format(when)
        : DateFormat.yMMMd().add_Hm().format(when);
  }
}
