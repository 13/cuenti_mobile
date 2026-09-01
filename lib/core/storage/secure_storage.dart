import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single wrapper around FlutterSecureStorage so tests can fake it, and the
/// one place per-platform options would go if they were ever needed.
///
/// None are set today, and that is deliberate: as of flutter_secure_storage
/// 10 the Android default is already AES-GCM with RSA-OAEP key wrapping, and
/// the EncryptedSharedPreferences option that used to be worth setting is
/// deprecated upstream. Setting options here now would be a downgrade.
class SecureStorage {
  const SecureStorage([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);
}
