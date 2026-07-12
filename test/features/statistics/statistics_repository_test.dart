import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/statistics/data/statistics_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late StatisticsRepository repo;

  setUp(() {
    dio = MockDio();
    repo = StatisticsRepository(dio);
  });

  test('load passes start/end/accountId as query params and parses maps',
      () async {
    when(() => dio.get<Map<String, dynamic>>('/statistics',
            queryParameters: {
              'start': '2026-01-01',
              'end': '2026-07-12',
              'accountId': 3,
            }))
        .thenAnswer((_) async => ok({
              'totalIncome': 500.0,
              'totalExpense': 300.0,
              'balance': 200.0,
              'currency': 'EUR',
              'incomeByCategory': {'Salary': 500.0},
              'expenseByCategory': {'Groceries': 200.0, 'Rent': 100.0},
              'monthlyIncome': {'2026-01': 500.0},
              'monthlyExpense': {'2026-01': 300.0},
              'transactionCount': 5,
            }));

    final stats = await repo.load(
        start: '2026-01-01', end: '2026-07-12', accountId: 3);

    expect(stats.totalIncome, 500.0);
    expect(stats.balance, 200.0);
    expect(stats.incomeByCategory, {'Salary': 500.0});
    expect(stats.expenseByCategory, {'Groceries': 200.0, 'Rent': 100.0});
    expect(stats.transactionCount, 5);
    verify(() => dio.get<Map<String, dynamic>>('/statistics',
        queryParameters: {
          'start': '2026-01-01',
          'end': '2026-07-12',
          'accountId': 3,
        })).called(1);
  });

  test('load omits null query params', () async {
    when(() => dio.get<Map<String, dynamic>>('/statistics',
            queryParameters: <String, dynamic>{}))
        .thenAnswer((_) async => ok({
              'totalIncome': 0.0,
              'totalExpense': 0.0,
              'balance': 0.0,
              'currency': 'EUR',
              'incomeByCategory': <String, dynamic>{},
              'expenseByCategory': <String, dynamic>{},
              'monthlyIncome': <String, dynamic>{},
              'monthlyExpense': <String, dynamic>{},
              'transactionCount': 0,
            }));

    final stats = await repo.load();

    expect(stats.transactionCount, 0);
    verify(() => dio.get<Map<String, dynamic>>('/statistics',
        queryParameters: <String, dynamic>{})).called(1);
  });

  test('load maps DioException to ApiException', () async {
    when(() => dio.get<Map<String, dynamic>>('/statistics',
            queryParameters: any(named: 'queryParameters'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/statistics'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.load(), throwsA(isA<NetworkException>()));
  });
}
