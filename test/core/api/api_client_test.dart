import 'dart:io';

import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/offline_cache_interceptor.dart';
import 'package:cuentimobile/core/api/response_cache.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage extends SecureStorage {
  _MemoryStorage() : super();
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  late Directory dir;
  late ResponseCache cache;
  late ApiClient client;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cuenti_api_client_test');
    cache = ResponseCache(dir);
    client = ApiClient(
      _MemoryStorage(),
      dioOverride: Dio(),
      offlineCache: OfflineCacheInterceptor(cache),
    );
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> cacheSomething() =>
      cache.store('some-endpoint', {'balance': 1234});

  Future<bool> hasCachedData() async =>
      await cache.read('some-endpoint') != null;

  test('pointing the app at a different server drops the figures cached '
      "from the old one, which are not this server's to show", () async {
    await client.setServerUrl('https://first.example');
    await cacheSomething();

    await client.setServerUrl('https://second.example');

    expect(
      await hasCachedData(),
      isFalse,
      reason:
          'offline, those figures would have replayed as the new '
          "server's -- one account's money under another's address",
    );
  });

  test(
    'saving the same server again keeps the cache: re-running setup '
    'without changing the address must not throw away what it knows',
    () async {
      await client.setServerUrl('https://first.example');
      await cacheSomething();

      await client.setServerUrl('https://first.example');

      expect(await hasCachedData(), isTrue);
    },
  );

  test('a trailing slash is the same server, not a different one', () async {
    await client.setServerUrl('https://first.example');
    await cacheSomething();

    await client.setServerUrl('https://first.example/');

    expect(await hasCachedData(), isTrue);
  });

  test('the new url is still what requests go to', () async {
    await client.setServerUrl('https://second.example/');

    expect(client.baseUrl, 'https://second.example');
    expect(client.dio.options.baseUrl, 'https://second.example/api');
  });
}
