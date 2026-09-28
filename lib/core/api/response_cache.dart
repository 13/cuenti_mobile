import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cuentimobile/core/storage/at_rest_cipher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// A response body kept from the last time an endpoint answered, with when
/// that was, so the UI can say how old what it is showing is.
class CachedResponse {
  const CachedResponse({required this.body, required this.storedAt});

  final Object? body;
  final DateTime storedAt;
}

/// Identifies an endpoint for caching: the method, the server, the path, and
/// the query parameters in a fixed order, hashed so the result is a safe
/// file name.
///
/// The server is part of it so two servers can never answer for each other,
/// even on a path where clearing the cache on a server change did not run.
///
/// Query parameters are part of the key because a filtered list and an
/// unfiltered one are different answers, and serving one for the other
/// offline would be worse than serving nothing.
String cacheKeyFor(RequestOptions options) {
  final query =
      options.queryParameters.entries.map((e) => '${e.key}=${e.value}').toList()
        ..sort();
  final signature =
      '${options.method} ${options.baseUrl}${options.path}?${query.join('&')}';
  return base64Url
      .encode(sha256.convert(utf8.encode(signature)).bytes)
      .replaceAll('=', '');
}

/// The last successful body per endpoint, so a screen can show what it last
/// knew when the server cannot be reached.
///
/// Deliberately a plain directory of JSON files: entries are independent, a
/// damaged one costs exactly one endpoint, and nothing here has to be
/// migrated when a response shape changes -- a body that no longer parses is
/// simply a miss.
class ResponseCache {
  ResponseCache(
    this._directory, {
    this.maxEntries = defaultMaxEntries,
    this.maxAge = defaultMaxAge,
    this.cipher = AtRestCipher.none,
  });

  /// Seals entries on disk. [open] always passes a real one; constructing a
  /// cache directly over a directory (tests) leaves entries in the clear.
  final AtRestCipher cipher;

  /// Every distinct query is its own entry, and the transactions list keys
  /// on the search box -- so each search anyone types would otherwise leave
  /// a file behind forever. Generous enough that ordinary use never evicts.
  static const defaultMaxEntries = 200;

  /// Past this, an entry is a miss rather than "the last figures fetched".
  /// Stale numbers are useful for a train journey, not for a quarter.
  static const defaultMaxAge = Duration(days: 14);

  /// How far ahead of the clock a write time may be before the clock is
  /// taken to have been moved back.
  static const clockSkewAllowance = Duration(minutes: 5);

  /// Opens the cache in the app's support directory, which the OS does not
  /// purge behind the app's back the way it may purge temp.
  static Future<ResponseCache> open({required AtRestCipher cipher}) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/response_cache');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return ResponseCache(dir, cipher: cipher);
  }

  final Directory _directory;
  final int maxEntries;
  final Duration maxAge;

  File _fileFor(String key) => File('${_directory.path}/$key.json');

  /// Bumped by [clear]. A write started under an earlier generation belongs
  /// to data that has since been wiped -- a signed-out account, a server
  /// moved away from -- and is dropped rather than written back.
  int get generation => _generation;
  int _generation = 0;

  /// Writes still in flight, for [clear] and [flush] to wait on.
  final Set<Future<void>> _pending = {};

  /// The latest write per key, so two writes to one endpoint land in the
  /// order they were made rather than whichever finished encrypting first.
  final Map<String, Future<void>> _lastWrite = {};

  /// What is on disk, so a write can tell whether the store has outgrown
  /// [maxEntries] without listing the directory every time. Filled on the
  /// first write.
  Set<String>? _keys;

  /// Keeps [body] as the last known answer for [key].
  ///
  /// [generation] is the [ResponseCache.generation] read when the request
  /// that produced [body] went out; a [clear] since then means the answer
  /// belongs to data that is gone, and it is not written. Omitted, it is the
  /// current one.
  Future<void> store(String key, Object? body, {int? generation}) {
    final from = generation ?? _generation;
    final previous = _lastWrite[key];
    late final Future<void> write;
    write =
        (previous == null
                ? _write(key, body, from)
                // A failed earlier write does not stop this one.
                : previous
                      .then<void>((_) {}, onError: (Object _) {})
                      .then(
                        (_) => _write(key, body, from),
                      ))
            .whenComplete(() {
              _pending.remove(write);
              if (identical(_lastWrite[key], write)) {
                // Dropping the map's reference, not a future to wait for.
                // ignore: discarded_futures
                _lastWrite.remove(key);
              }
            });
    _pending.add(write);
    _lastWrite[key] = write;
    return write;
  }

  Future<void> _write(String key, Object? body, int generation) async {
    if (generation != _generation) return;
    final sealed = await cipher.seal(
      jsonEncode({'storedAt': DateTime.now().toIso8601String(), 'body': body}),
    );
    if (generation != _generation) return;
    // Written aside and renamed into place, so a read never meets half a
    // file.
    final temp = File('${_directory.path}/$key.json.tmp');
    await temp.writeAsString(sealed);
    if (generation != _generation) {
      if (temp.existsSync()) await temp.delete();
      return;
    }
    await temp.rename(_fileFor(key).path);
    final keys = _keys ??= _scanKeys();
    if (keys.add(key) && keys.length > maxEntries) await _evictExcess();
  }

  /// Waits for every write started so far.
  Future<void> flush() => Future.wait(_pending.toList());

  Set<String> _scanKeys() {
    if (!_directory.existsSync()) return {};
    return {
      for (final f in _directory.listSync().whereType<File>())
        if (f.path.endsWith('.json'))
          f.uri.pathSegments.last.replaceFirst(RegExp(r'\.json$'), ''),
    };
  }

  /// Drops the least recently written entries once the store is over its
  /// cap, down to 90% of it so the next few writes need not do this again.
  /// Modification time is the ordering: it is what writing an entry already
  /// updates, so re-fetching an endpoint keeps it alive without any
  /// bookkeeping of our own.
  Future<void> _evictExcess() async {
    if (!_directory.existsSync()) return;
    final files = _directory
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();
    final target = (maxEntries * 0.9).floor().clamp(1, maxEntries);
    if (files.length > maxEntries) {
      files.sort(
        (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
      );
      for (final file in files.take(files.length - target)) {
        try {
          await file.delete();
          // A file that vanished under us is already evicted.
          // ignore: avoid_catches_without_on_clauses
        } catch (_) {}
      }
    }
    _keys = _scanKeys();
  }

  Future<CachedResponse?> read(String key) async {
    // A write still in flight for this key is the newest answer there is.
    final writing = _lastWrite[key];
    if (writing != null) {
      try {
        await writing;
        // A failed write leaves whatever was there before, which is read.
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {}
    }
    final file = _fileFor(key);
    if (!file.existsSync()) return null;
    final age = DateTime.now().difference(file.statSync().modified);
    // Written "in the future" means the clock was moved back since. The age
    // is then unknown, and calling it fresh is exactly what would let a
    // clock change keep figures alive past maxAge.
    if (age > maxAge || age < -clockSkewAllowance) return null;
    try {
      final opened = await cipher.open(await file.readAsString());
      if (opened.legacy) {
        // Plaintext from before encryption: the account's figures, readable
        // on disk. A cache can always be fetched again, so it goes.
        await file.delete();
        return null;
      }
      final decoded = jsonDecode(opened.text) as Map;
      return CachedResponse(
        body: decoded['body'],
        storedAt: DateTime.parse(decoded['storedAt'] as String),
      );
      // A cache is a convenience; an entry we cannot read is a miss, never a
      // reason to fail the request that was already failing.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      // Sealed under a key this install no longer has, or damaged: it can
      // never be read again, so it is removed rather than retried forever.
      try {
        if (file.existsSync()) await file.delete();
        // A file that vanished or cannot be deleted is simply not served.
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {}
      return null;
    }
  }

  Future<void> clear() async {
    // Bumped first, so nothing that has not reached the disk yet will.
    _generation++;
    // Then every write already past that check is let finish, so none can
    // land after the delete below and put the wiped figures back.
    try {
      await flush();
      // A failed write is nothing to wait on and nothing to report here.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
    _keys = {};
    if (!_directory.existsSync()) return;
    await _directory.delete(recursive: true);
    await _directory.create(recursive: true);
  }
}
