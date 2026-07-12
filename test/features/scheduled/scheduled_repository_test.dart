import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/scheduled/data/scheduled_repository.dart';
import 'package:cuentimobile/features/scheduled/domain/scheduled_transaction.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late ScheduledRepository repo;

  setUp(() {
    dio = MockDio();
    repo = ScheduledRepository(dio);
  });

  test('getAll parses list of scheduled transactions', () async {
    when(() => dio.get<List<dynamic>>('/scheduled-transactions')).thenAnswer(
        (_) async => ok([
          {
            'id': 1,
            'type': 'EXPENSE',
            'fromAccountId': 1,
            'toAccountId': null,
            'amount': 100.0,
            'payee': 'Grocery Store',
            'categoryId': 2,
            'memo': 'Weekly groceries',
            'tags': 'food',
            'number': null,
            'assetId': null,
            'units': null,
            'recurrencePattern': 'WEEKLY',
            'recurrenceValue': 1,
            'nextOccurrence': '2026-07-19T00:00:00Z',
            'enabled': true,
          },
        ]));

    final transactions = await repo.getAll();

    expect(transactions, hasLength(1));
    expect(transactions[0].id, 1);
    expect(transactions[0].type, 'EXPENSE');
    expect(transactions[0].amount, 100.0);
  });

  test('save posts new scheduled transaction when id is null', () async {
    final scheduled = ScheduledTransaction(
      type: 'EXPENSE',
      fromAccountId: 1,
      amount: 50.0,
      payee: 'Test',
      nextOccurrence: DateTime.parse('2026-07-19T00:00:00Z'),
    );
    when(() => dio.post<Map<String, dynamic>>('/scheduled-transactions',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({
          'id': 5,
          'type': 'EXPENSE',
          'fromAccountId': 1,
          'amount': 50.0,
          'payee': 'Test',
          'nextOccurrence': '2026-07-19T00:00:00.000Z',
          'enabled': true,
        }));

    final saved = await repo.save(scheduled);

    expect(saved.id, 5);
    final captured = verify(() => dio.post<Map<String, dynamic>>('/scheduled-transactions',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured, containsPair('type', 'EXPENSE'));
    expect(captured, containsPair('fromAccountId', 1));
    expect(captured, containsPair('amount', 50.0));
    expect(captured, containsPair('payee', 'Test'));
    expect(captured['nextOccurrence'], isA<String>()
        .having((s) => s.startsWith('2026-07-19T00:00:00'), 'ISO date', true));
    expect(captured.keys, isNot(contains('id')));
    expect(captured.keys, isNot(contains('fromAccountName')));
    expect(captured.keys, isNot(contains('toAccountName')));
    expect(captured.keys, isNot(contains('categoryName')));
    expect(captured.keys, isNot(contains('assetName')));
  });

  test('save puts existing scheduled transaction when id is set', () async {
    final scheduled = ScheduledTransaction(
      id: 1,
      type: 'EXPENSE',
      fromAccountId: 1,
      amount: 50.0,
      nextOccurrence: DateTime.parse('2026-07-19T00:00:00Z'),
    );
    when(() => dio.put<Map<String, dynamic>>('/scheduled-transactions/1',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({
          'id': 1,
          'type': 'EXPENSE',
          'fromAccountId': 1,
          'amount': 50.0,
          'nextOccurrence': '2026-07-19T00:00:00Z',
        }));

    final saved = await repo.save(scheduled);

    expect(saved.id, 1);
    verify(() => dio.put<Map<String, dynamic>>('/scheduled-transactions/1',
        data: any(named: 'data'))).called(1);
  });

  test('delete calls DELETE /scheduled-transactions/{id}', () async {
    when(() => dio.delete<void>('/scheduled-transactions/1'))
        .thenAnswer((_) async => ok(null));

    await repo.delete(1);

    verify(() => dio.delete<void>('/scheduled-transactions/1')).called(1);
  });

  test('post calls POST /scheduled-transactions/{id}/post and returns result', () async {
    when(() => dio.post<Map<String, dynamic>>('/scheduled-transactions/1/post'))
        .thenAnswer((_) async => ok({'id': 1, 'type': 'EXPENSE'}));

    await repo.post(1);

    verify(() => dio.post<Map<String, dynamic>>('/scheduled-transactions/1/post'))
        .called(1);
  });

  test('skip calls POST /scheduled-transactions/{id}/skip and returns result', () async {
    when(() => dio.post<Map<String, dynamic>>('/scheduled-transactions/1/skip'))
        .thenAnswer((_) async => ok({'id': 1, 'type': 'EXPENSE'}));

    await repo.skip(1);

    verify(() => dio.post<Map<String, dynamic>>('/scheduled-transactions/1/skip'))
        .called(1);
  });

  test('getAll maps DioException to ApiException', () async {
    when(() => dio.get<List<dynamic>>('/scheduled-transactions')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/scheduled-transactions'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getAll(), throwsA(isA<NetworkException>()));
  });
}
