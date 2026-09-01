import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// A response body kept from the last time an endpoint answered, with when
/// that was, so the UI can say how old what it is showing is.
class CachedResponse {
  const CachedResponse({required this.body, required this.storedAt});

  final Object? body;
  final DateTime storedAt;
}

/// Identifies an endpoint for caching: the method, the path, and the query
/// parameters in a fixed order, hashed so the result is a safe file name.
///
/// Query parameters are part of the key because a filtered list and an
/// unfiltered one are different answers, and serving one for the other
/// offline would be worse than serving nothing.
String cacheKeyFor(RequestOptions options) {
  final query =
      options.queryParameters.entries.map((e) => '${e.key}=${e.value}').toList()
        ..sort();
  final signature = '${options.method} ${options.path}?${query.join('&')}';
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
  ResponseCache(this._directory);

  /// Opens the cache in the app's support directory, which the OS does not
  /// purge behind the app's back the way it may purge temp.
  static Future<ResponseCache> open() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/response_cache');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return ResponseCache(dir);
  }

  final Directory _directory;

  File _fileFor(String key) => File('${_directory.path}/$key.json');

  Future<void> store(String key, Object? body) async {
    await _fileFor(key).writeAsString(
      jsonEncode({
        'storedAt': DateTime.now().toIso8601String(),
        'body': body,
      }),
    );
  }

  Future<CachedResponse?> read(String key) async {
    final file = _fileFor(key);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString()) as Map;
      return CachedResponse(
        body: decoded['body'],
        storedAt: DateTime.parse(decoded['storedAt'] as String),
      );
      // A cache is a convenience; an entry we cannot read is a miss, never a
      // reason to fail the request that was already failing.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    if (!_directory.existsSync()) return;
    await _directory.delete(recursive: true);
    await _directory.create(recursive: true);
  }
}
