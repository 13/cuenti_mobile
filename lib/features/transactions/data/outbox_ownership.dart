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
/// Every read of the outbox should go through here.
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
