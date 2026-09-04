import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Shows a bottom sheet asking the user to confirm a (typically
/// destructive) action. Returns `true` when the user confirms, `false`
/// (or `null`, treated as `false`) otherwise.
///
/// [isDestructive] defaults to true because almost every caller is a
/// deletion, and it paints the confirm button in the error colour. A sheet
/// whose confirm button is the *safe* answer -- the outbox claim prompt's
/// "Send as this account", where cancelling is what discards work -- passes
/// false, so the red is not sitting on the button nobody should hesitate
/// over.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = true,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelLabel ?? L.of(context).commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: isDestructive
                        ? FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                          )
                        : null,
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(confirmLabel ?? L.of(context).commonDelete),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}
