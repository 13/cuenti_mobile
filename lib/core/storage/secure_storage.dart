import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single wrapper around FlutterSecureStorage so tests can fake it and the
/// AndroidOptions live in exactly one place.
class SecureStorage {
  const SecureStorage([this._storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  )]);

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);
}
