import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';

/// Text read back from disk, and whether it predates encryption.
class OpenedText {
  const OpenedText(this.text, {required this.legacy});

  final String text;

  /// True for plaintext written before encryption existed. The caller should
  /// rewrite it sealed, or drop it if it is only a cache.
  final bool legacy;
}

/// Sealed data that cannot be opened: tampered with, truncated, or written
/// under a key this install no longer has.
class AtRestDecryptionException implements Exception {
  const AtRestDecryptionException(this.detail);

  final String detail;

  @override
  String toString() => 'AtRestDecryptionException: $detail';
}

/// Encrypts what offline mode keeps on disk: the response cache (dashboard,
/// transactions, balances, profile) and the outbox of unsent writes.
///
/// Those files sit in app-private storage and are excluded from backup, but
/// on a rooted phone, in a forensic image or to malware with file access
/// they were plain JSON -- the account's financial history in the clear,
/// next to a token that is itself kept in the Keystore. The key for this
/// data now lives in the same Keystore-backed storage, so the files are no
/// easier to read than the token that fetched them.
abstract class AtRestCipher {
  const AtRestCipher();

  /// Leaves text as it is. For tests and for stores constructed directly
  /// over a directory; production opens its stores with
  /// [AesGcmAtRestCipher].
  static const AtRestCipher none = _PlaintextCipher();

  /// Seals [plaintext] into text that is safe to write to a file.
  Future<String> seal(String plaintext);

  /// Opens what [seal] wrote. Plaintext from before encryption comes back
  /// as-is with [OpenedText.legacy] set. Throws [AtRestDecryptionException]
  /// for sealed data that cannot be opened, and whatever the key store threw
  /// if the key could not be read.
  Future<OpenedText> open(String stored);
}

class _PlaintextCipher extends AtRestCipher {
  const _PlaintextCipher();

  @override
  Future<String> seal(String plaintext) async => plaintext;

  @override
  Future<OpenedText> open(String stored) async =>
      OpenedText(stored, legacy: false);
}

/// AES-256-GCM with a random key created on first use and kept in
/// [SecureStorage] (Keystore-backed on Android).
///
/// Every sealed value carries its own random nonce and an authentication
/// tag, so identical plaintexts do not produce identical files and any
/// change to a file is detected rather than decrypted into garbage.
class AesGcmAtRestCipher extends AtRestCipher {
  AesGcmAtRestCipher(this._storage);

  /// Marks sealed text, and the format version, so plaintext from before
  /// encryption can be told apart and a future format can be introduced.
  static const prefix = 'cuenti-at-rest:v1:';

  static const _keyName = 'at_rest_key_v1';

  final SecureStorage _storage;
  final _algorithm = AesGcm.with256bits();

  /// The key being loaded or created, shared by every cipher over the same
  /// storage. The cache and the outbox each hold a cipher; on a first launch
  /// both can reach for a key that does not exist yet, and two independent
  /// creations would each write their own -- whichever lost would have
  /// sealed data under a key nobody keeps.
  static final _keys = Expando<Future<SecretKey>>();

  Future<SecretKey> _secretKey() async {
    final cached = _keys[_storage];
    if (cached != null) return cached;
    final loading = _readOrCreateKey();
    _keys[_storage] = loading;
    try {
      return await loading;
    } on Object {
      // A failed read must be retried next time, not remembered forever.
      _keys[_storage] = null;
      rethrow;
    }
  }

  Future<SecretKey> _readOrCreateKey() async {
    final stored = await _storage.read(_keyName);
    if (stored != null && stored.isNotEmpty) {
      return SecretKey(base64Decode(stored));
    }
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    await _storage.write(_keyName, base64Encode(bytes));
    return SecretKey(bytes);
  }

  @override
  Future<String> seal(String plaintext) async {
    final box = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: await _secretKey(),
    );
    return '$prefix${base64Encode(box.concatenation())}';
  }

  @override
  Future<OpenedText> open(String stored) async {
    if (!stored.startsWith(prefix)) return OpenedText(stored, legacy: true);
    final key = await _secretKey();
    try {
      final box = SecretBox.fromConcatenation(
        base64Decode(stored.substring(prefix.length)),
        nonceLength: _algorithm.nonceLength,
        macLength: _algorithm.macAlgorithm.macLength,
      );
      final clear = await _algorithm.decrypt(box, secretKey: key);
      return OpenedText(utf8.decode(clear), legacy: false);
    } on SecretBoxAuthenticationError {
      throw const AtRestDecryptionException('authentication failed');
    } on FormatException catch (e) {
      throw AtRestDecryptionException('malformed: ${e.message}');
      // SecretBox.fromConcatenation reports a body too short to hold a nonce
      // and tag as an ArgumentError. Here that is a damaged file, not a
      // programming mistake, and must be answered like one.
      // ignore: avoid_catching_errors
    } on ArgumentError catch (e) {
      throw AtRestDecryptionException('malformed: ${e.message}');
    }
  }
}
