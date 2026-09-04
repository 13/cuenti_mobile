import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/outbox_ownership.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tells the user about a queue that is not theirs, once, after a sign-in.
///
/// Nothing here is load-bearing for safety: [ownedEntries] already refuses
/// to send or show a queue the current account does not own, whatever the
/// user answers here and whether or not they are ever asked. This exists so
/// that unsent work does not vanish from view with no explanation -- and so
/// that a queue left by an earlier version, which nobody has claimed, can
/// be adopted rather than stranded.
///
/// The two questions are deliberately not the same shape:
///
///  * A foreign queue is *not* discarded by default. It stays on disk,
///    sealed, and the wording says why it might come back: the account it
///    belongs to signing in again, or a mistyped server address being
///    corrected -- `ApiClient.setServerUrl` changes the base URL without
///    touching the outbox, so a typo in your own server address turns your
///    own queue foreign. Discarding is offered, and is the red button,
///    because it is the one that destroys work.
///  * An unowned queue can only have come from a version before ownership
///    existed, so adopting it is the safe answer and is styled as such;
///    the destructive answer, discarding, is the one you have to choose.
///
/// Declining either question changes nothing on disk. A kept foreign queue
/// is still set aside by the next save (`claimForWriting`), not deleted.
Future<void> promptForForeignOutbox(BuildContext context, WidgetRef ref) async {
  final outbox = ref.read(transactionOutboxProvider);
  final accountKey = accountKeyFor(
    ref.read(apiClientProvider).baseUrl,
    ref.read(authControllerProvider),
  );
  // Nobody to ask on behalf of, and nobody who could adopt the queue.
  if (accountKey == null) return;

  final claim = await claimStateOf(outbox, accountKey);
  if (claim == OutboxClaim.empty || claim == OutboxClaim.ours) return;
  if (!context.mounted) return;

  // entriesIgnoringOwner rather than ownedEntries: the whole point is to
  // count the entries this account may *not* see.
  final count = (await entriesIgnoringOwner(outbox)).length;
  if (!context.mounted) return;

  final l = L.of(context);
  switch (claim) {
    case OutboxClaim.foreign:
      final discard = await showConfirmSheet(
        context,
        title: l.outboxForeignTitle,
        message: l.outboxForeignBody(count),
        confirmLabel: l.txDiscardPending,
        cancelLabel: l.outboxKeep,
      );
      if (discard) await outbox.clear();
    case OutboxClaim.unowned:
      final adopt = await showConfirmSheet(
        context,
        title: l.outboxUnknownTitle,
        message: l.outboxUnknownBody(count, accountKey),
        confirmLabel: l.outboxSendAsThisAccount,
        cancelLabel: l.txDiscardPending,
        // Adopting is the safe answer here, so it must not wear the colour
        // the other four callers of this sheet use for deletion.
        isDestructive: false,
      );
      if (adopt) {
        await outbox.setOwner(accountKey);
      } else {
        await outbox.clear();
      }
    case OutboxClaim.empty:
    case OutboxClaim.ours:
      return;
  }
}
