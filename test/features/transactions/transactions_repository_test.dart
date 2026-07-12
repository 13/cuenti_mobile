import 'package:cuentimobile/core/api/api_exception.dart';
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
    when(() => dio.get<Map<String, dynamic>>('/transactions',
            queryParameters: {'accountId': 3, 'page': 0, 'size': 50}))
        .thenAnswer((_) async => ok({
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
            }));

    final page = await repo.getPage(
        filter: const TransactionFilter(accountId: 3), page: 0, size: 50);

    expect(page.content, hasLength(1));
    expect(page.content[0].id, 1);
    expect(page.totalPages, 1);
    expect(page.totalElements, 1);
  });

  test('getPage omits all filter query params when null', () async {
    when(() => dio.get<Map<String, dynamic>>('/transactions',
            queryParameters: {'page': 0, 'size': 50})).thenAnswer((_) async => ok({
          'content': <Map<String, dynamic>>[],
          'page': 0,
          'size': 50,
          'totalElements': 0,
          'totalPages': 0,
        }));

    final page = await repo.getPage(page: 0, size: 50);

    expect(page.content, isEmpty);
    verify(() => dio.get<Map<String, dynamic>>('/transactions',
        queryParameters: {'page': 0, 'size': 50})).called(1);
  });

  test('getPage serializes every filter field when set', () async {
    when(() => dio.get<Map<String, dynamic>>('/transactions', queryParameters: {
          'accountId': 3,
          'type': 'EXPENSE',
          'categoryId': 7,
          'start': '2026-02-01',
          'end': '2026-02-28',
          'search': 'coffee',
          'page': 0,
          'size': 50,
        })).thenAnswer((_) async => ok({
          'content': <Map<String, dynamic>>[],
          'page': 0,
          'size': 50,
          'totalElements': 0,
          'totalPages': 0,
        }));

    final page = await repo.getPage(
        filter: TransactionFilter(
          accountId: 3,
          type: 'EXPENSE',
          categoryId: 7,
          start: DateTime(2026, 2, 1),
          end: DateTime(2026, 2, 28),
          search: 'coffee',
        ),
        page: 0,
        size: 50);

    expect(page.content, isEmpty);
    verify(() => dio.get<Map<String, dynamic>>('/transactions', queryParameters: {
          'accountId': 3,
          'type': 'EXPENSE',
          'categoryId': 7,
          'start': '2026-02-01',
          'end': '2026-02-28',
          'search': 'coffee',
          'page': 0,
          'size': 50,
        })).called(1);
  });

  test('getPage omits search when empty string', () async {
    when(() => dio.get<Map<String, dynamic>>('/transactions',
            queryParameters: {'page': 0, 'size': 50})).thenAnswer((_) async => ok({
          'content': <Map<String, dynamic>>[],
          'page': 0,
          'size': 50,
          'totalElements': 0,
          'totalPages': 0,
        }));

    await repo.getPage(
        filter: const TransactionFilter(search: ''), page: 0, size: 50);

    verify(() => dio.get<Map<String, dynamic>>('/transactions',
        queryParameters: {'page': 0, 'size': 50})).called(1);
  });

  test('save strips id/derived fields, defaults paymentMethod, drops empty splits',
      () async {
    final tx = Transaction(
      fromAccountId: 1,
      fromAccountName: 'Giro',
      categoryName: 'Food',
      assetName: 'BTC',
      status: 'CLEARED',
      amount: 10,
      transactionDate: DateTime(2026, 1, 1),
    );

    when(() => dio.post<Map<String, dynamic>>('/transactions',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({
              'id': 9,
              'type': 'EXPENSE',
              'amount': 10,
              'transactionDate': '2026-01-01T00:00:00.000',
            }));

    final saved = await repo.save(tx);

    expect(saved.id, 9);
    final captured = verify(() => dio.post<Map<String, dynamic>>('/transactions',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured.containsKey('id'), isFalse);
    expect(captured.containsKey('fromAccountName'), isFalse);
    expect(captured.containsKey('toAccountName'), isFalse);
    expect(captured.containsKey('categoryName'), isFalse);
    expect(captured.containsKey('assetName'), isFalse);
    expect(captured.containsKey('status'), isFalse);
    expect(captured.containsKey('splits'), isFalse);
    expect(captured['paymentMethod'], 'NONE');
  });

  test('save PUTs when id set and preserves explicit paymentMethod', () async {
    final tx = Transaction(
      id: 7,
      fromAccountId: 1,
      amount: 10,
      paymentMethod: 'CASH',
      transactionDate: DateTime(2026, 1, 1),
    );

    when(() => dio.put<Map<String, dynamic>>('/transactions/7',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({
              'id': 7,
              'type': 'EXPENSE',
              'amount': 10,
              'transactionDate': '2026-01-01T00:00:00.000',
            }));

    final saved = await repo.save(tx);

    expect(saved.id, 7);
    final captured = verify(() => dio.put<Map<String, dynamic>>('/transactions/7',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured['paymentMethod'], 'CASH');
    expect(captured.containsKey('id'), isFalse);
  });

  test('delete calls DELETE /transactions/{id}', () async {
    when(() => dio.delete<void>('/transactions/5')).thenAnswer((_) async => ok(null));

    await repo.delete(5);

    verify(() => dio.delete<void>('/transactions/5')).called(1);
  });

  test('getPage maps DioException to ApiException', () async {
    when(() => dio.get<Map<String, dynamic>>('/transactions',
            queryParameters: any(named: 'queryParameters'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/transactions'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getPage(), throwsA(isA<NetworkException>()));
  });
}
