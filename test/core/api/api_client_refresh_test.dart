import 'dart:convert';
import 'dart:typed_data';

import 'package:cuentimobile/core/api/api_client.dart';
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

/// Answers like the server: `/user/profile` wants the current access token,
/// `/auth/refresh` rotates the refresh token once per value.
class _FakeServer implements HttpClientAdapter {
  String validAccess = 'access-2';
  String validRefresh = 'refresh-1';
  bool refuseRefresh = false;
  int refreshCalls = 0;
  final List<String?> profileAuth = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/auth/refresh')) {
      refreshCalls++;
      final body = options.data as Map<String, dynamic>;
      if (refuseRefresh || body['refreshToken'] != validRefresh) {
        return _json({'error': 'invalid_refresh_token'}, 401);
      }
      validRefresh = 'refresh-${refreshCalls + 1}';
      return _json({
        'token': validAccess,
        'refreshToken': validRefresh,
        'expiresIn': 900,
      }, 200);
    }
    final auth = options.headers['Authorization'] as String?;
    profileAuth.add(auth);
    return auth == 'Bearer $validAccess'
        ? _json({'username': 'demo'}, 200)
        : _json({}, 401);
  }

  ResponseBody _json(Object body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  late _MemoryStorage storage;
  late _FakeServer server;
  late ApiClient client;
  late int expired;

  setUp(() async {
    storage = _MemoryStorage();
    server = _FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://cuenti.test/api'))
      ..httpClientAdapter = server;
    client = ApiClient(storage, dioOverride: dio);
    expired = 0;
    client.onSessionExpired = () => expired++;
    await client.saveToken('access-1', refreshToken: 'refresh-1');
  });

  test('an expired access token is renewed and the request retried', () async {
    final res = await client.dio.get<Map<String, dynamic>>('/user/profile');

    expect(res.statusCode, 200);
    expect(server.profileAuth, ['Bearer access-1', 'Bearer access-2']);
    expect(await client.getToken(), 'access-2');
    expect(storage.data['refresh_token'], 'refresh-2');
    expect(expired, 0);
  });

  test('requests failing together share one refresh', () async {
    await Future.wait([
      client.dio.get<Map<String, dynamic>>('/user/profile'),
      client.dio.get<Map<String, dynamic>>('/user/profile'),
      client.dio.get<Map<String, dynamic>>('/user/profile'),
    ]);

    expect(server.refreshCalls, 1);
    expect(expired, 0);
  });

  test(
    'a refused refresh ends the session and forgets the refresh token',
    () async {
      server.refuseRefresh = true;

      await expectLater(
        client.dio.get<Map<String, dynamic>>('/user/profile'),
        throwsA(isA<DioException>()),
      );
      expect(expired, 1);
      expect(storage.data.containsKey('refresh_token'), isFalse);
    },
  );

  test(
    'without a refresh token (older server) a 401 ends the session',
    () async {
      await client.clearToken();
      await client.saveToken('access-1');

      await expectLater(
        client.dio.get<Map<String, dynamic>>('/user/profile'),
        throwsA(isA<DioException>()),
      );
      expect(server.refreshCalls, 0);
      expect(expired, 1);
    },
  );

  test('signing out forgets the refresh token too', () async {
    await client.clearToken();
    expect(storage.data.containsKey('refresh_token'), isFalse);
  });
}
