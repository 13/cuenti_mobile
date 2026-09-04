import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';

/// What the outbox on disk is, relative to whoever is signed in now.
enum OutboxClaim {
  /// Nothing queued. Whose it would be does not arise.
  empty,

  /// Queued, and claimed by the current account.
  ours,

  /// Queued, and claimed by somebody else -- or by somebody, while nobody
  /// is signed in. Not to be sent, and not to be shown.
  foreign,

  /// Queued, and claimed by nobody: written before ownership existed.
  unowned,
}

/// Which account a queue belongs to.
///
/// The server is part of the identity because this app is self-hosted: the
/// same user id on two different servers is two different accounts, and a
/// key of the id alone would let one server's queue drain into the other.
///
/// Null means the current account is not knowable -- nobody signed in, or a
/// profile that identifies nobody. That is deliberately not the same as "a
/// key that does not match", but it seals the queue just as firmly: a queue
/// we cannot attribute is a queue we do not send.
String? accountKeyFor(String baseUrl, AuthState auth) {
  final user = auth.user;
  if (user == null) return null;
  final identity =
      user.id?.toString() ?? (user.username.isEmpty ? null : user.username);
  if (identity == null) return null;
  return '$baseUrl#$identity';
}

/// The entries the current account may see and send.
///
/// Every read of the outbox goes through here. Not a convention:
/// `test/features/transactions/outbox_reads_test.dart` bans a bare
/// `.all()` anywhere in `lib` outside this file and the store itself, so a
/// reader added later that skips this fails there. The rule is only worth
/// anything if the next reader obeys it too -- one unguarded read puts
/// somebody's amounts and payees in front of somebody else, and a guard
/// that most callers honour is not a guard.
///
/// A queue nobody has claimed reads as empty rather than as ours: it is
/// sealed, not adopted. It was written before ownership existed, so
/// nothing on disk says whose it is, and guessing "the account signed in
/// now" is exactly the wrong guess in the two cases this feature exists
/// for -- a stale store the fallback left behind, and a queue kept across
/// an expired session. Adopting is a decision for the person to make (the
/// sheet asks); until they answer, nothing goes out and nothing is shown.
Future<List<PendingTransaction>> ownedEntries(
  TransactionOutbox outbox,
  String? accountKey,
) async {
  if (accountKey == null) return const [];
  final owner = await outbox.owner();
  if (owner != accountKey) return const [];
  return outbox.all();
}

/// Every entry, whoever owns it.
///
/// One legitimate caller: the sheet that asks the user what to do about a
/// queue that is not theirs. It has to count what it is asking about.
Future<List<PendingTransaction>> entriesIgnoringOwner(
  TransactionOutbox outbox,
) => outbox.all();

/// Whether the queue on disk is ours, somebody else's, unclaimed, or empty.
Future<OutboxClaim> claimStateOf(
  TransactionOutbox outbox,
  String? accountKey,
) async {
  if ((await outbox.all()).isEmpty) return OutboxClaim.empty;
  final owner = await outbox.owner();
  if (owner == null) return OutboxClaim.unowned;
  if (owner == accountKey) return OutboxClaim.ours;
  return OutboxClaim.foreign;
}

/// Claims the queue for the current account when nothing has claimed it.
Future<void> claimIfUnowned(
  TransactionOutbox outbox,
  String? accountKey,
) async {
  if (accountKey == null) return;
  if (await outbox.owner() != null) return;
  await outbox.setOwner(accountKey);
}

/// Makes the queue this account's before anything is written into it.
///
/// [claimIfUnowned] is not enough on its own, because it runs after the
/// write and leaves two holes. A queue that is not ours must not be written
/// into at all -- the entry would be sealed by [ownedEntries] and its own
/// author would never see it again -- and the lookups that amend an
/// existing entry have to see the queue they are amending, which a sealed
/// read cannot.
///
/// A foreign queue is set aside rather than kept -- [TransactionOutbox.
/// sideline] moves it out of every normal read's way instead of deleting
/// it. Not because it is worthless: it cannot be attributed to the account
/// making this write, and that is the only thing wrong with it. Its real
/// owner may sign back in and match the same key again, or a mistyped
/// server URL may get corrected back to the one that queue belongs to --
/// both ordinary enough that destroying the entries outright, on the
/// strength of a guess about who could never come back for them, would be
/// the wrong trade. Setting them aside gets the same result a write into
/// them needs -- they stop being read, sent or shown -- without it.
///
/// With no current account key nothing is claimed and nothing is set
/// aside: a queue we cannot attribute is not one we may take.
///
/// Calls against the same [outbox] are serialized: two writes racing each
/// other (`_enqueue` resolves ownership on every one) could otherwise both
/// read the queue as foreign and both try to sideline it, and an
/// interleaved pair of sideline moves can throw or silently drop whichever
/// write landed in between -- the same shape of race [TransactionOutbox.
/// setOwner]'s own doc comment names for concurrent claims, just with a
/// directory move standing in for a file rename.
Future<void> claimForWriting(
  TransactionOutbox outbox,
  String? accountKey,
) {
  final previous = (_claimChains[outbox] ?? Future<void>.value())
      // A failed call must not wedge every call after it: only its own
      // caller needs to see its error, not the next unrelated write.
      .catchError((_) {});
  final resolved = previous.then((_) => _resolveOwnership(outbox, accountKey));
  _claimChains[outbox] = resolved.catchError((_) {});
  return resolved;
}

/// One chain per outbox instance, so two writes against different queues
/// (different accounts overridden in different tests, say) never wait on
/// each other. An [Expando] rather than a [Map] so it holds no reference
/// of its own -- a [TransactionOutbox] that is otherwise garbage can still
/// be collected.
final Expando<Future<void>> _claimChains = Expando<Future<void>>();

Future<void> _resolveOwnership(
  TransactionOutbox outbox,
  String? accountKey,
) async {
  if (accountKey == null) return;
  final owner = await outbox.owner();
  if (owner == accountKey) return;
  if (owner != null) await outbox.sideline();
  await outbox.setOwner(accountKey);
}
