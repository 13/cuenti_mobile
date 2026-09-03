import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Confirms that something the user asked for actually happened.
///
/// Saving used to be silent: the sheet closed, the row appeared or vanished,
/// and the user was left to infer success from the absence of an error. That
/// reads the same as a request that quietly did nothing -- particularly over
/// a slow connection, and particularly for money.
///
/// Takes a [ScaffoldMessengerState] rather than a BuildContext because the
/// usual caller pops its own sheet first, leaving its context defunct; the
/// messenger belongs to the Scaffold above and outlives it.
/// Deliberately does not hide whatever is already showing: a save can raise
/// a warning of its own first (an incomplete fuel entry, say), and replacing
/// that with "saved" would drop the more useful of the two messages. Flutter
/// queues them, so both are read.
void showSuccessSnack(ScaffoldMessengerState messenger, String message) {
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// The failure counterpart, so success and failure look like two sides of
/// one thing rather than two unrelated conventions.
void showErrorSnack(
  ScaffoldMessengerState messenger,
  ColorScheme colors,
  String message,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, size: 20, color: colors.onError),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: colors.onError)),
            ),
          ],
        ),
        backgroundColor: colors.error,
      ),
    );
}

/// Runs [action], reporting a failure on a snack bar in the user's language.
/// Returns whether it got through.
///
/// Every screen that deletes or reorders something had written this out by
/// hand -- a try, an `on ApiException`, and eight lines of SnackBar -- which
/// is fourteen copies of one decision. Two things went wrong in the copies:
/// the message styling drifted from [showErrorSnack], and almost none of
/// them caught anything but [ApiException], so a connection dropping mid
/// delete threw out of an async callback with nothing shown at all.
///
/// The context is read before the await, since the caller's widget may be
/// gone by the time the action finishes.
Future<bool> reportingFailure(
  BuildContext context,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final colors = Theme.of(context).colorScheme;
  final l = L.of(context);
  try {
    await action();
    return true;
  } on ApiException catch (e) {
    showErrorSnack(messenger, colors, e.localizedMessage(l));
    // Anything else is a platform or programming failure, whose toString()
    // is developer text rather than something to show anyone.
  } on Exception catch (_) {
    showErrorSnack(messenger, colors, l.errorUnknown);
  }
  return false;
}
