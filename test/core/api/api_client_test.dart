import 'dart:async';
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

  test('a request composed before init() has run still goes to a server: '
      'RequestOptions captures the base URL as the request is made, and the '
      'app-start outbox drain composes one while init() is still awaiting '
      'platform channels', () {
    // No dioOverride: this is the client the app itself builds.
    final fresh = ApiClient(_MemoryStorage());

    expect(fresh.dio.options.baseUrl, '${ApiClient.defaultServerUrl}/api');
  });

  test('the new url is still what requests go to', () async {
    await client.setServerUrl('https://second.example/');

    expect(client.baseUrl, 'https://second.example');
    expect(client.dio.options.baseUrl, 'https://second.example/api');
  });

  group('token', () {
    late _CountingStorage storage;
    late ApiClient counted;

    setUp(() {
      storage = _CountingStorage();
      counted = ApiClient(storage, dioOverride: Dio());
    });

    test('is read from SecureStorage once, not on every request', () async {
      storage.data['jwt_token'] = 'abc';

      expect(await counted.getToken(), 'abc');
      expect(await counted.getToken(), 'abc');
      expect(await counted.hasToken(), isTrue);

      expect(storage.reads, 1);
    });

    test('a saved token is served without reading it back', () async {
      await counted.saveToken('fresh');

      expect(await counted.getToken(), 'fresh');
      expect(storage.reads, 0);
    });

    test('is gone the moment a sign-out starts, before the delete lands, so '
        'no request composed meanwhile carries it', () async {
      await counted.saveToken('old');
      storage.holdDeletes = Completer<void>();

      final signingOut = counted.clearToken();

      expect(await counted.getToken(), isNull);
      storage.holdDeletes!.complete();
      await signingOut;
      expect(storage.data.containsKey('jwt_token'), isFalse);
    });
  });
}

class _CountingStorage extends _MemoryStorage {
  int reads = 0;
  Completer<void>? holdDeletes;

  @override
  Future<String?> read(String key) {
    reads++;
    return super.read(key);
  }

  @override
  Future<void> delete(String key) async {
    await holdDeletes?.future;
    await super.delete(key);
  }
}
