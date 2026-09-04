import 'dart:convert';
import 'dart:io';

import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Transaction writes the server has not accepted yet, kept on disk.
///
/// One JSON file per entry in the app-support directory -- the same store
/// ResponseCache uses, and for the same reason: the OS does not purge it
/// behind the app's back the way it may purge temp. Unlike that cache, what
/// is in here is work the user did and nothing else has a copy of.
class TransactionOutbox {
  TransactionOutbox(this._directory);

  static Future<TransactionOutbox> open() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/transaction_outbox');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return TransactionOutbox(dir);
  }

  final Directory _directory;

  File _fileFor(String localId) => File('${_directory.path}/$localId.json');

  Future<void> add(PendingTransaction entry) async =>
      _fileFor(entry.localId).writeAsString(jsonEncode(entry.toJson()));

  /// Oldest first, so entries send in the order they were made.
  Future<List<PendingTransaction>> all() async {
    if (!_directory.existsSync()) return [];
    final entries = <PendingTransaction>[];
    for (final file in _directory.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      try {
        entries.add(
          PendingTransaction.fromJson(
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
          ),
        );
        // One unreadable file must not cost the user every other entry
        // behind it, so it is skipped rather than thrown.
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {
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
}

/// Overridden at app start with [TransactionOutbox.open], the way the API
/// client is: opening it needs an await that a provider cannot do inline.
final transactionOutboxProvider = Provider<TransactionOutbox>(
  (ref) => throw UnimplementedError('transactionOutboxProvider not overridden'),
);
