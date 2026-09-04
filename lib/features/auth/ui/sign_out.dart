import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one sign-out flow, shared by the two surfaces that offer it: the
/// drawer and the settings screen.
///
/// It is here rather than in either screen because it was in only one of
/// them. The drawer signed out without asking and without clearing the
/// outbox, so the queue survived into the next account's session and the
/// next person's drain posted the previous one's transactions into their
/// books.
///
/// Two calls rather than one so a caller can close whatever it is showing
/// -- a drawer -- between the question and the wipe, while its own context
/// is still mounted.

/// Asks before anything is lost. False means the user said no.
///
/// The outbox holds writes the server has never seen -- unlike the response
/// cache, which is only a copy of something the server already has.
/// Discarding it silently would lose data the user entered, so ask first,
/// naming how much would be lost.
Future<bool> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final outbox = ref.read(transactionOutboxProvider);
  final pending = await outbox.all();
  if (!context.mounted) return false;
  // An empty fallback store means the real one could not be opened, not
  // that nothing is waiting -- so it is exactly the case that must ask.
  if (pending.isEmpty && !outbox.isFallback) return true;
  return showConfirmSheet(
    context,
    title: L.of(context).logoutPendingTitle,
    // The "they will stay on this device" wording is only true when there
    // is nothing here to discard. A fallback store that DOES hold entries
    // is one signOut will clear, so it gets the honest count instead.
    message: outbox.isFallback && pending.isEmpty
        ? L.of(context).logoutPendingUnknown
        : L.of(context).logoutPendingBody(pending.length),
    confirmLabel: L.of(context).actionLogout,
  );
}

/// Drops the account's unsent work and signs out. Only ever after
/// [confirmSignOut] has said yes.
///
/// Callers land on the login screen once this resolves, not before: a fresh
/// sign-in must not race the token clear and the saved-credential wipe.
Future<void> signOut(WidgetRef ref) async {
  final outbox = ref.read(transactionOutboxProvider);
  // Only when there is something to drop: clear() rebuilds the directory,
  // which is real work to do for nothing on the ordinary sign-out.
  if ((await outbox.all()).isNotEmpty) await outbox.clear();
  await ref.read(authControllerProvider.notifier).logout();
}
