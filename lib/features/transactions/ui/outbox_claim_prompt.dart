import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/outbox_ownership.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How to name the current account to the person who is using it.
///
/// Deliberately not [accountKeyFor]. That is a storage key -- a base URL
/// and an internal database id, `https://cuenti.muh#2` -- and putting it in
/// front of somebody asks them to accept an identity claim written in a
/// form they have never seen. `#2` reads like a stranger, and the button
/// beside it is the one that leaves their work unsent.
///
/// So: the username, plus the server's host only when it is not the
/// default one. An ordinary user sees `demo`; a self-hoster who moved
/// servers sees `demo (books.example)`, which is the only case where the
/// server is part of what distinguishes them. The host is parenthesised
/// rather than joined by a word, so the string needs no translation and no
/// grammar of its own in three languages.
///
/// Null on the same inputs [accountKeyFor] is null on, so the two agree
/// about when there is an account at all.
String? accountDisplayName(String baseUrl, AuthState auth) {
  final user = auth.user;
  if (user == null) return null;
  final name = user.username.isEmpty ? user.id?.toString() : user.username;
  if (name == null) return null;
  if (baseUrl == ApiClient.defaultServerUrl) return name;
  final host = Uri.tryParse(baseUrl)?.host ?? '';
  return host.isEmpty ? '$name ($baseUrl)' : '$name ($host)';
}

/// Tells the user about a queue that is not theirs, once, after a sign-in.
///
/// Nothing here is load-bearing for safety: [ownedEntries] already refuses
/// to send or show a queue the current account does not own, whatever the
/// user answers here and whether or not they are ever asked. This exists so
/// that unsent work does not vanish from view with no explanation -- and so
/// that a queue left by an earlier version, which nobody has claimed, can
/// be adopted rather than stranded.
///
/// **Neither answer destroys anything except the one the user has to reach
/// for by name.** A modal sheet can be dismissed by a scrim tap, a drag or
/// the back button, and [showConfirmSheet] reports all three as a cancel --
/// so whatever cancel does is what an accidental brush of the screen does.
/// On the upgrade branch that is `setOwner` or nothing at all: discarding
/// is not offered here, because an implicit discard of work the user has
/// never been shown is exactly the failure this sheet exists to prevent.
/// Nobody is stranded by that -- adopting the queue turns the entries into
/// ordinary unsent rows, which the transaction list already lets them
/// discard one by one.
///
/// The two questions are otherwise not the same shape:
///
///  * A foreign queue is *not* discarded by default. It stays on disk,
///    sealed, and the wording says why it might come back: the account it
///    belongs to signing in again, or a mistyped server address being
///    corrected -- `ApiClient.setServerUrl` changes the base URL without
///    touching the outbox, so a typo in your own server address turns your
///    own queue foreign. Discarding is offered, and is the red button,
///    because it is the one that destroys work and so must be deliberate.
///  * An unowned queue can only have come from a version before ownership
///    existed, so adopting it is the safe answer and is styled as such.
///
/// Declining either question changes nothing on disk. A kept foreign queue
/// is still set aside by the next save (`claimForWriting`), not deleted.
Future<void> promptForForeignOutbox(BuildContext context, WidgetRef ref) async {
  final outbox = ref.read(transactionOutboxProvider);
  final baseUrl = ref.read(apiClientProvider).baseUrl;
  final auth = ref.read(authControllerProvider);
  final accountKey = accountKeyFor(baseUrl, auth);
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
        // The name, not the key -- see [accountDisplayName].
        message: l.outboxUnknownBody(
          count,
          accountDisplayName(baseUrl, auth) ?? accountKey,
        ),
        confirmLabel: l.outboxSendAsThisAccount,
        // Not "discard": declining, however it happens, must write nothing.
        cancelLabel: l.outboxNotNow,
        // Adopting is the safe answer here, so it must not wear the colour
        // the other fourteen callers of this sheet use for deletion.
        isDestructive: false,
      );
      if (adopt) await outbox.setOwner(accountKey);
    case OutboxClaim.empty:
    case OutboxClaim.ours:
      return;
  }
}
