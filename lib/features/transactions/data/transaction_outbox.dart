import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Transaction writes the server has not accepted yet, kept on disk.
///
/// One JSON file per entry in the app-support directory -- the same store
/// ResponseCache uses, and for the same reason: the OS does not purge it
/// behind the app's back the way it may purge temp. Unlike that cache, what
/// is in here is work the user did and nothing else has a copy of.
class TransactionOutbox {
  TransactionOutbox(this._directory, {this.isFallback = false});

  /// True when this store is the temp-directory fallback rather than the
  /// real one, which means an empty queue is "could not be read", not
  /// "nothing is waiting". The sign-out flow must not treat the two alike.
  final bool isFallback;

  static Future<TransactionOutbox> open() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/transaction_outbox');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return TransactionOutbox(dir);
  }

  /// [open], or a store that still works when it cannot be had.
  ///
  /// Every consumer of the transactions list needs an outbox, so it has to
  /// exist before the provider tree is handed one -- but [open] needs a
  /// platform channel, and ApiClient refuses to await ResponseCache.open()
  /// at startup for exactly that reason: an unusual host or a test binding
  /// can leave a channel that never answers. Unguarded, a
  /// getApplicationSupportDirectory() failure meant a crash before the
  /// first frame and a hung channel meant a permanently blank screen.
  ///
  /// The fallback is the same store over a directory in the system temp
  /// area, which dart:io can give us with no channel at all. The OS may
  /// purge it between runs, so a queue kept there is less durable than the
  /// real one -- but the queue still works for this session, and the app
  /// starts.
  static Future<TransactionOutbox> openOrFallback() async {
    try {
      return await open().timeout(const Duration(seconds: 5));
    } on Exception catch (e) {
      debugPrint('TransactionOutbox: no app-support store ($e), using temp');
      final dir = Directory('${Directory.systemTemp.path}/cuenti_outbox')
        ..createSync(recursive: true);
      return TransactionOutbox(dir, isFallback: true);
    }
  }

  final Directory _directory;

  String _encodeFileName(String localId) =>
      base64Url.encode(utf8.encode(localId)).replaceAll('=', '');

  File _fileFor(String localId) =>
      File('${_directory.path}/${_encodeFileName(localId)}.json');

  /// Which account's queue this is.
  ///
  /// Named with a leading dot so [all] skips it as bookkeeping rather than
  /// parsing it as a `PendingTransaction` and logging a skip line on every
  /// read.
  File get _ownerFile => File('${_directory.path}/.owner.json');

  /// The account key this queue belongs to, or null when nothing has
  /// claimed it -- a fresh queue, or one written before ownership existed.
  ///
  /// An unreadable file reads as unowned rather than throwing. Unowned is
  /// the cautious answer: it makes the queue something to ask about, not
  /// something to send.
  Future<String?> owner() async {
    if (!_ownerFile.existsSync()) return null;
    try {
      final decoded = jsonDecode(_ownerFile.readAsStringSync());
      final account = decoded is Map<String, dynamic>
          ? decoded['account']
          : null;
      return account is String && account.isNotEmpty ? account : null;
      // A malformed owner file must read as unowned rather than crash the
      // caller, so any failure here -- bad JSON, wrong shape -- is caught
      // broadly rather than matched to one exception type.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      debugPrint('TransactionOutbox: unreadable owner file: $e');
      return null;
    }
  }

  /// Distinguishes concurrent [setOwner] calls' temp files from one
  /// another. `_enqueue` claims the queue on every write, so two saves
  /// fired together (`Future.wait`) can both find the queue unclaimed and
  /// both race to claim it; a shared temp filename would let the second
  /// call's write stomp the first's before its rename runs. Incremented
  /// synchronously, before either call's first `await`, so Dart's
  /// single-threaded event loop can never interleave two calls onto the
  /// same value.
  static int _setOwnerSeq = 0;

  /// Claims this queue for [account]. Written the way entries are, so a
  /// torn write cannot leave a half-file that reads as a different owner.
  Future<void> setOwner(String account) async {
    if (!_directory.existsSync()) await _directory.create(recursive: true);
    final tempFile = File('${_ownerFile.path}.${_setOwnerSeq++}.tmp');
    await tempFile.writeAsString(jsonEncode({'account': account}));
    await tempFile.rename(_ownerFile.path);
  }

  Future<void> add(PendingTransaction entry) async {
    final file = _fileFor(entry.localId);
    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(jsonEncode(entry.toJson()));
    await tempFile.rename(file.path);
  }

  /// Oldest first, so entries send in the order they were made.
  Future<List<PendingTransaction>> all() async {
    if (!_directory.existsSync()) return [];
    final entries = <PendingTransaction>[];
    for (final file in _directory.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      // Dot-files are the store's own bookkeeping, not entries.
      if (name.startsWith('.') || !name.endsWith('.json')) continue;
      try {
        entries.add(
          PendingTransaction.fromJson(
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
          ),
        );
        // One unreadable file must not cost the user every other entry
        // behind it, so it is skipped rather than thrown -- but not in
        // silence: this is work the user typed and nothing else has a copy
        // of, and it disappearing with no trace anywhere is the softest
        // version of the failure this whole feature exists to prevent.
        // ignore: avoid_catches_without_on_clauses
      } catch (e) {
        debugPrint('TransactionOutbox: skipping ${file.path}: $e');
        continue;
      }
    }
    entries.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    return entries;
  }

  Future<void> remove(String localId) async {
    final file = _fileFor(localId);
    if (file.existsSync()) await file.delete();
  }

  Future<void> replace(PendingTransaction entry) => add(entry);

  Future<void> markRejected(String localId, String reason) async {
    final entry = (await all()).where((e) => e.localId == localId).firstOrNull;
    if (entry == null) return;
    await replace(entry.copyWith(rejection: reason));
  }

  Future<void> clear() async {
    if (!_directory.existsSync()) return;
    await _directory.delete(recursive: true);
    await _directory.create(recursive: true);
  }

  /// Distinguishes concurrent [sideline] calls' subdirectories from one
  /// another, the same way [_setOwnerSeq] does for [setOwner]. Incremented
  /// synchronously so two calls in the same microsecond still land in
  /// different subdirectories.
  static int _sidelineSeq = 0;

  /// Moves every current entry, and the owner file, into a fresh
  /// subdirectory instead of deleting them.
  ///
  /// `claimForWriting` (outbox_ownership.dart) calls this on a queue it
  /// cannot attribute to the account making the write, before claiming the
  /// queue for that account. The entries are not worthless just because
  /// they cannot be attributed right now -- the account they belong to may
  /// sign back in, or a mistyped server URL may get corrected -- so they
  /// are set aside rather than destroyed.
  ///
  /// [all] lists files and skips directories, and [owner] only reads
  /// `.owner.json` in this directory, so a sidelined queue reads as empty
  /// and unowned for free -- the subdirectory is invisible to every normal
  /// read without any extra guard in either method.
  ///
  /// The subdirectory name starts with a dot, so it cannot collide with an
  /// entry (entry filenames are base64url, an alphabet outside the dot)
  /// or with the owner file (`.owner.json` is a fixed, different name),
  /// and it carries the moment of the sideline plus a counter, so repeated
  /// takeovers each land in their own subdirectory instead of overwriting
  /// the last one.
  Future<void> sideline() async {
    if (!_directory.existsSync()) return;
    final files = _directory.listSync().whereType<File>().toList();
    if (files.isEmpty) return;
    final target = Directory(
      '${_directory.path}/.sidelined-'
      '${DateTime.now().microsecondsSinceEpoch}-${_sidelineSeq++}',
    );
    await target.create(recursive: true);
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      await file.rename('${target.path}/$name');
    }
  }
}

/// Overridden at app start with [TransactionOutbox.open], the way the API
/// client is: opening it needs an await that a provider cannot do inline.
final transactionOutboxProvider = Provider<TransactionOutbox>(
  (ref) => throw UnimplementedError('transactionOutboxProvider not overridden'),
);
