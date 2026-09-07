import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/offline_cache_interceptor.dart';
import 'package:cuentimobile/core/api/response_cache.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late TransactionsRepository repo;

  setUp(() {
    dio = MockDio();
    repo = TransactionsRepository(dio);
  });

  test('getPage parses envelope with query params', () async {
    when(
      () => dio.get<dynamic>(
        '/transactions',
        queryParameters: {'accountId': 3, 'page': 0, 'size': 50},
      ),
    ).thenAnswer(
      (_) async => ok({
        'content': [
          {
            'id': 1,
            'type': 'EXPENSE',
            'amount': 12.5,
            'transactionDate': '2026-01-01T00:00:00.000',
          },
        ],
        'page': 0,
        'size': 50,
        'totalElements': 1,
        'totalPages': 1,
      }),
    );

    final page = await repo.getPage(
      filter: const TransactionFilter(accountId: 3),
    );

    expect(page.content, hasLength(1));
    expect(page.content[0].id, 1);
    expect(page.totalPages, 1);
    expect(page.totalElements, 1);
  });

  test(
    'getPage tolerates a legacy plain-array response (pre-pagination server)',
    () async {
      when(
        () => dio.get<dynamic>(
          '/transactions',
          queryParameters: {'page': 0, 'size': 50},
        ),
      ).thenAnswer(
        (_) async => ok<dynamic>([
          {
            'id': 1,
            'type': 'EXPENSE',
            'amount': 12.5,
            'transactionDate': '2026-01-01T00:00:00.000',
          },
          {
            'id': 2,
            'type': 'INCOME',
            'amount': 5.0,
            'transactionDate': '2026-01-02T00:00:00.000',
          },
        ]),
      );

      final page = await repo.getPage();

      expect(page.content, hasLength(2));
      expect(page.content[0].id, 1);
      expect(page.content[1].id, 2);
      expect(page.page, 0);
      expect(page.size, 50);
      expect(page.totalElements, 2);
      expect(page.totalPages, 1);
    },
  );

  test(
    'getPage throws ServerException for a garbage (non-list, non-map) response',
    () async {
      when(
        () => dio.get<dynamic>(
          '/transactions',
          queryParameters: {'page': 0, 'size': 50},
        ),
      ).thenAnswer((_) async => ok<dynamic>('not json'));

      expect(
        () => repo.getPage(),
        throwsA(isA<ServerException>()),
      );
    },
  );

  test('getPage omits all filter query params when null', () async {
    when(
      () => dio.get<dynamic>(
        '/transactions',
        queryParameters: {'page': 0, 'size': 50},
      ),
    ).thenAnswer(
      (_) async => ok({
        'content': <Map<String, dynamic>>[],
        'page': 0,
        'size': 50,
        'totalElements': 0,
        'totalPages': 0,
      }),
    );

    final page = await repo.getPage();

    expect(page.content, isEmpty);
    verify(
      () => dio.get<dynamic>(
        '/transactions',
        queryParameters: {'page': 0, 'size': 50},
      ),
    ).called(1);
  });

  test('getPage serializes every filter field when set', () async {
    when(
      () => dio.get<dynamic>(
        '/transactions',
        queryParameters: {
          'accountId': 3,
          'type': 'EXPENSE',
          'categoryId': 7,
          'start': '2026-02-01',
          'end': '2026-02-28',
          'search': 'coffee',
          'page': 0,
          'size': 50,
        },
      ),
    ).thenAnswer(
      (_) async => ok({
        'content': <Map<String, dynamic>>[],
        'page': 0,
        'size': 50,
        'totalElements': 0,
        'totalPages': 0,
      }),
    );

    final page = await repo.getPage(
      filter: TransactionFilter(
        accountId: 3,
        type: 'EXPENSE',
        categoryId: 7,
        start: DateTime(2026, 2),
        end: DateTime(2026, 2, 28),
        search: 'coffee',
      ),
    );

    expect(page.content, isEmpty);
    verify(
      () => dio.get<dynamic>(
        '/transactions',
        queryParameters: {
          'accountId': 3,
          'type': 'EXPENSE',
          'categoryId': 7,
          'start': '2026-02-01',
          'end': '2026-02-28',
          'search': 'coffee',
          'page': 0,
          'size': 50,
        },
      ),
    ).called(1);
  });

  test('getPage omits search when empty string', () async {
    when(
      () => dio.get<dynamic>(
        '/transactions',
        queryParameters: {'page': 0, 'size': 50},
      ),
    ).thenAnswer(
      (_) async => ok({
        'content': <Map<String, dynamic>>[],
        'page': 0,
        'size': 50,
        'totalElements': 0,
        'totalPages': 0,
      }),
    );

    await repo.getPage(filter: const TransactionFilter(search: ''));

    verify(
      () => dio.get<dynamic>(
        '/transactions',
        queryParameters: {'page': 0, 'size': 50},
      ),
    ).called(1);
  });

  test(
    'save strips id/derived fields, defaults paymentMethod, drops empty splits',
    () async {
      final tx = Transaction(
        fromAccountId: 1,
        fromAccountName: 'Giro',
        categoryName: 'Food',
        assetName: 'BTC',
        status: 'CLEARED',
        amount: 10,
        transactionDate: DateTime(2026),
      );

      when(
        () => dio.post<Map<String, dynamic>>(
          '/transactions',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => ok({
          'id': 9,
          'type': 'EXPENSE',
          'amount': 10,
          'transactionDate': '2026-01-01T00:00:00.000',
        }),
      );

      final saved = await repo.save(tx);

      expect(saved.id, 9);
      final captured =
          verify(
                () => dio.post<Map<String, dynamic>>(
                  '/transactions',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured.containsKey('id'), isFalse);
      expect(captured.containsKey('fromAccountName'), isFalse);
      expect(captured.containsKey('toAccountName'), isFalse);
      expect(captured.containsKey('categoryName'), isFalse);
      expect(captured.containsKey('assetName'), isFalse);
      expect(captured.containsKey('status'), isFalse);
      expect(captured.containsKey('splits'), isFalse);
      expect(captured['paymentMethod'], 'NONE');
    },
  );

  test('save PUTs when id set and preserves explicit paymentMethod', () async {
    final tx = Transaction(
      id: 7,
      fromAccountId: 1,
      amount: 10,
      paymentMethod: 'CASH',
      transactionDate: DateTime(2026),
    );

    when(
      () => dio.put<Map<String, dynamic>>(
        '/transactions/7',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => ok({
        'id': 7,
        'type': 'EXPENSE',
        'amount': 10,
        'transactionDate': '2026-01-01T00:00:00.000',
      }),
    );

    final saved = await repo.save(tx);

    expect(saved.id, 7);
    final captured =
        verify(
              () => dio.put<Map<String, dynamic>>(
                '/transactions/7',
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(captured['paymentMethod'], 'CASH');
    expect(captured.containsKey('id'), isFalse);
  });

  test('delete calls DELETE /transactions/{id}', () async {
    when(
      () => dio.delete<void>('/transactions/5'),
    ).thenAnswer((_) async => ok(null));

    await repo.delete(5);

    verify(() => dio.delete<void>('/transactions/5')).called(1);
  });

  test('getPage maps DioException to ApiException', () async {
    when(
      () => dio.get<dynamic>(
        '/transactions',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/transactions'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getPage(), throwsA(isA<NetworkException>()));
  });

  group('reading transfers with no server to ask', _offlineFallbackTests);
}

/// Serves one canned body per query string, and throws a connection failure
/// for everything once [offline] is set. A real adapter rather than a
/// [MockDio], because the fallback under test only fires after the cache
/// interceptor has had its turn -- which needs a real interceptor chain.
class _CorpusAdapter implements HttpClientAdapter {
  final Map<String, Object> bodies = {};
  bool offline = false;

  static String keyOf(Map<String, dynamic> query) {
    final pairs = query.entries.map((e) => '${e.key}=${e.value}').toList()
      ..sort();
    return pairs.join('&');
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: const SocketException('no route to host'),
      );
    }
    final body = bodies[keyOf(options.queryParameters)];
    if (body == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object>(
          requestOptions: options,
          statusCode: 404,
          data: const {'error': 'no fixture'},
        ),
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

void _offlineFallbackTests() {
  late Directory dir;
  late OfflineCacheInterceptor interceptor;
  late _CorpusAdapter adapter;
  late TransactionsRepository repo;

  /// One row. [day] drives both the id and the date, so date ordering and
  /// identity can be asserted with the same number.
  Map<String, dynamic> row(int day, String type, {int? accountId}) => {
    'id': day,
    'type': type,
    'amount': day * 1.0,
    'fromAccountId': ?accountId,
    'transactionDate': '2026-01-${day.toString().padLeft(2, '0')}T00:00:00.000',
  };

  Map<String, Object> envelope(
    List<Map<String, dynamic>> content, {
    required int page,
    required int totalPages,
    int size = 50,
  }) => {
    'content': content,
    'page': page,
    'size': size,
    'totalElements': totalPages * size,
    'totalPages': totalPages,
  };

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cuenti-tx-offline-test');
    interceptor = OfflineCacheInterceptor(ResponseCache(dir));
    adapter = _CorpusAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://cuenti.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(interceptor);
    repo = TransactionsRepository(dio, offlineCache: () => interceptor);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  /// Fetches [filter]/[page] while online, so it lands in the cache.
  Future<void> warm({
    TransactionFilter filter = const TransactionFilter(),
    int page = 0,
  }) => repo.getPage(filter: filter, page: page);

  void serve(
    Map<String, dynamic> query,
    List<Map<String, dynamic>> content, {
    required int totalPages,
  }) {
    adapter.bodies[_CorpusAdapter.keyOf(query)] = envelope(
      content,
      page: query['page'] as int,
      totalPages: totalPages,
    );
  }

  test('a filtered list is cut out of the cached unfiltered one', () async {
    serve(
      {'page': 0, 'size': 50},
      [
        row(3, 'EXPENSE'),
        row(1, 'TRANSFER'),
        row(2, 'INCOME'),
        row(4, 'TRANSFER'),
      ],
      totalPages: 1,
    );
    await warm();
    adapter.offline = true;

    final page = await repo.getPage(
      filter: const TransactionFilter(type: 'TRANSFER'),
    );

    // Only the transfers, newest first -- a query the server was never asked
    // for and which has no cache entry of its own.
    expect(page.content.map((t) => t.id), [4, 1]);
    expect(page.totalElements, 2);
    expect(page.totalPages, 1);
  });

  test(
    'answering the failure ourselves still raises the offline banner',
    () async {
      serve({'page': 0, 'size': 50}, [row(1, 'TRANSFER')], totalPages: 1);
      await warm();
      adapter.offline = true;
      expect(interceptor.servingStaleData, isFalse);

      await repo.getPage(filter: const TransactionFilter(type: 'TRANSFER'));

      // The interceptor sets `stale` only where it does the replaying, so
      // without markStale the figures would be old with nothing saying so.
      expect(interceptor.servingStaleData, isTrue);
      expect(interceptor.staleSince.value, isNotNull);
    },
  );

  test('a complete corpus with no transfers is an empty list, not an '
      'error', () async {
    serve(
      {'page': 0, 'size': 50},
      [
        row(1, 'EXPENSE'),
        row(2, 'INCOME'),
      ],
      totalPages: 1,
    );
    await warm();
    adapter.offline = true;

    final page = await repo.getPage(
      filter: const TransactionFilter(type: 'TRANSFER'),
    );

    expect(page.content, isEmpty);
    expect(page.totalElements, 0);
  });

  test('a truncated corpus with no transfers refuses to claim zero', () async {
    // Page 0 of three, so what is cached is only a prefix.
    serve({'page': 0, 'size': 50}, [row(1, 'EXPENSE')], totalPages: 3);
    await warm();
    adapter.offline = true;

    // "You have no transfers" is the one claim a prefix cannot support.
    await expectLater(
      repo.getPage(filter: const TransactionFilter(type: 'TRANSFER')),
      throwsA(isA<NetworkException>()),
    );
  });

  test('nothing cached at all still fails', () async {
    adapter.offline = true;

    await expectLater(
      repo.getPage(filter: const TransactionFilter(type: 'TRANSFER')),
      throwsA(isA<NetworkException>()),
    );
  });

  test('load-more works off the pages that were scrolled online', () async {
    final first = [for (var i = 60; i > 10; i--) row(i, 'TRANSFER')];
    final second = [for (var i = 10; i > 0; i--) row(i, 'TRANSFER')];
    serve({'page': 0, 'size': 50}, first, totalPages: 2);
    serve({'page': 1, 'size': 50}, second, totalPages: 2);
    await warm();
    await warm(page: 1);
    adapter.offline = true;

    final page = await repo.getPage(
      filter: const TransactionFilter(type: 'TRANSFER'),
      page: 1,
    );

    // Page 1 of the *filtered* list is a key that was never fetched; it is
    // the 51st row onward of the corpus.
    expect(page.content.map((t) => t.id), [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
    expect(page.totalElements, 60);
    expect(page.totalPages, 2);
  });

  test('a hole in the cached pages ends the walk rather than being '
      'assembled across', () async {
    serve({'page': 0, 'size': 50}, [row(9, 'TRANSFER')], totalPages: 3);
    serve({'page': 2, 'size': 50}, [row(1, 'TRANSFER')], totalPages: 3);
    await warm();
    await warm(page: 2);
    adapter.offline = true;

    final page = await repo.getPage(
      filter: const TransactionFilter(type: 'TRANSFER'),
    );

    // Page 1 is missing. A list with a gap in the middle reads as data loss
    // with nothing to say so, so page 2's row is not reached.
    expect(page.content.map((t) => t.id), [9]);
  });

  test('the narrower cached superset is preferred over the unfiltered '
      'one', () async {
    serve({'page': 0, 'size': 50}, [row(1, 'TRANSFER')], totalPages: 1);
    serve(
      {'accountId': 3, 'page': 0, 'size': 50},
      [row(7, 'TRANSFER', accountId: 3)],
      totalPages: 1,
    );
    await warm();
    await warm(filter: const TransactionFilter(accountId: 3));
    adapter.offline = true;

    final page = await repo.getPage(
      filter: const TransactionFilter(accountId: 3, type: 'TRANSFER'),
    );

    // The account-scoped list holds less of the corpus but more of the
    // answer, so it truncates later.
    expect(page.content.map((t) => t.id), [7]);
  });

  test('a cached body that will not parse is a miss, not a crash', () async {
    serve({'page': 0, 'size': 50}, [row(1, 'TRANSFER')], totalPages: 1);
    await warm();
    adapter.offline = true;
    for (final f in dir.listSync().whereType<File>()) {
      f.writeAsStringSync(
        jsonEncode({
          'body': {'content': 'not a list'},
          'storedAt': DateTime.now().toIso8601String(),
        }),
      );
    }

    await expectLater(
      repo.getPage(filter: const TransactionFilter(type: 'TRANSFER')),
      throwsA(isA<NetworkException>()),
    );
  });

  test('a 500 is never answered from cache -- the server did reply', () async {
    serve({'page': 0, 'size': 50}, [row(1, 'TRANSFER')], totalPages: 1);
    await warm();
    adapter.bodies.clear(); // now answers 404/500-shaped, not offline

    await expectLater(
      repo.getPage(filter: const TransactionFilter(type: 'TRANSFER')),
      throwsA(
        isA<ApiException>().having(
          (e) => e,
          'not network',
          isNot(isA<NetworkException>()),
        ),
      ),
    );
  });

  test('with no cache wired in, offline behaves exactly as before', () async {
    final plain = TransactionsRepository(
      Dio(BaseOptions(baseUrl: 'https://cuenti.test'))
        ..httpClientAdapter = (adapter..offline = true),
    );

    await expectLater(
      plain.getPage(filter: const TransactionFilter(type: 'TRANSFER')),
      throwsA(isA<NetworkException>()),
    );
  });
}
