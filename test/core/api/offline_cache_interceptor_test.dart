import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cuentimobile/core/api/offline_cache_interceptor.dart';
import 'package:cuentimobile/core/api/response_cache.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers with [body], or throws a connection failure once [offline] is set.
class _StubAdapter implements HttpClientAdapter {
  Object body = {'total': 1};
  bool offline = false;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: const SocketException('no route to host'),
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory dir;
  late ResponseCache cache;
  late _StubAdapter adapter;
  late Dio dio;
  late OfflineCacheInterceptor interceptor;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cuenti-interceptor-test');
    cache = ResponseCache(dir);
    adapter = _StubAdapter();
    interceptor = OfflineCacheInterceptor(cache);
    dio = Dio(BaseOptions(baseUrl: 'https://cuenti.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(interceptor);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test(
    'a live request is answered by the server and not marked stale',
    () async {
      final res = await dio.get<Object>('/transactions');

      expect(res.data, {'total': 1});
      expect(isStale(res), isFalse);
      expect(interceptor.servingStaleData, isFalse);
    },
  );

  test(
    'an unreachable server is answered from the last successful response',
    () async {
      await dio.get<Object>('/transactions');
      adapter.offline = true;

      final res = await dio.get<Object>('/transactions');

      expect(res.data, {'total': 1});
      expect(isStale(res), isTrue);
      expect(interceptor.servingStaleData, isTrue);
    },
  );

  test(
    'an endpoint never seen still fails, rather than inventing data',
    () async {
      adapter.offline = true;

      expect(
        () => dio.get<Object>('/never-fetched'),
        throwsA(isA<DioException>()),
      );
    },
  );

  test(
    'a different query is a different answer and is not substituted',
    () async {
      await dio.get<Object>('/transactions', queryParameters: {'page': 0});
      adapter.offline = true;

      expect(
        () => dio.get<Object>('/transactions', queryParameters: {'page': 1}),
        throwsA(isA<DioException>()),
      );
    },
  );

  test(
    'a server error is passed through, since the server did answer',
    () async {
      await dio.get<Object>('/transactions');
      adapter
        ..offline = false
        ..body = {'total': 2};
      // A 500 is not an offline condition; serving stale data would hide it.
      final failing = Dio(BaseOptions(baseUrl: 'https://cuenti.test'))
        ..httpClientAdapter = _ErrorAdapter()
        ..interceptors.add(OfflineCacheInterceptor(cache));

      expect(
        () => failing.get<Object>('/transactions'),
        throwsA(isA<DioException>()),
      );
    },
  );

  test('writes are never cached or served', () async {
    await dio.post<Object>('/transactions', data: {'amount': 1});
    adapter.offline = true;

    expect(
      () => dio.post<Object>('/transactions', data: {'amount': 1}),
      throwsA(isA<DioException>()),
    );
  });

  test('coming back online clears the stale flag', () async {
    await dio.get<Object>('/transactions');
    adapter.offline = true;
    await dio.get<Object>('/transactions');
    expect(interceptor.servingStaleData, isTrue);

    adapter.offline = false;
    await dio.get<Object>('/transactions');

    expect(interceptor.servingStaleData, isFalse);
  });

  test('a fresh response replaces what was cached', () async {
    await dio.get<Object>('/transactions');
    adapter.body = {'total': 99};
    await dio.get<Object>('/transactions');
    adapter.offline = true;

    expect((await dio.get<Object>('/transactions')).data, {'total': 99});
  });
}

class _ErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"error":"boom"}',
    500,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
