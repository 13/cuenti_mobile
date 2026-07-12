import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/forecasts/data/forecasts_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late ForecastsRepository repo;

  setUp(() {
    dio = MockDio();
    repo = ForecastsRepository(dio);
  });

  test('getForecast parses full forecast envelope with 12 months', () async {
    when(() => dio.get<Map<String, dynamic>>('/forecasts',
            queryParameters: {'year': 2026}))
        .thenAnswer((_) async => ok({
          'year': 2026,
          'months': [
            {'month': '2026-01', 'income': 5000.0, 'expense': 2000.0, 'net': 3000.0},
            {'month': '2026-02', 'income': 5200.0, 'expense': 2100.0, 'net': 3100.0},
            {'month': '2026-03', 'income': 5100.0, 'expense': 2050.0, 'net': 3050.0},
            {'month': '2026-04', 'income': 5300.0, 'expense': 2150.0, 'net': 3150.0},
            {'month': '2026-05', 'income': 5400.0, 'expense': 2200.0, 'net': 3200.0},
            {'month': '2026-06', 'income': 5250.0, 'expense': 2120.0, 'net': 3130.0},
            {'month': '2026-07', 'income': 5350.0, 'expense': 2170.0, 'net': 3180.0},
            {'month': '2026-08', 'income': 5450.0, 'expense': 2220.0, 'net': 3230.0},
            {'month': '2026-09', 'income': 5200.0, 'expense': 2100.0, 'net': 3100.0},
            {'month': '2026-10', 'income': 5300.0, 'expense': 2150.0, 'net': 3150.0},
            {'month': '2026-11', 'income': 5400.0, 'expense': 2200.0, 'net': 3200.0},
            {'month': '2026-12', 'income': 5600.0, 'expense': 2300.0, 'net': 3300.0},
          ],
          'totalIncome': 63150.0,
          'totalExpense': 25660.0,
          'netForecast': 37490.0,
          'currency': 'EUR',
        }));

    final forecast = await repo.getForecast(2026);

    expect(forecast.year, 2026);
    expect(forecast.months, hasLength(12));
    expect(forecast.months[0].month, '2026-01');
    expect(forecast.months[0].income, 5000.0);
    expect(forecast.months[0].expense, 2000.0);
    expect(forecast.months[0].net, 3000.0);
    expect(forecast.totalIncome, 63150.0);
    expect(forecast.totalExpense, 25660.0);
    expect(forecast.netForecast, 37490.0);
    expect(forecast.currency, 'EUR');
  });

  test('getForecast converts int to double for numeric fields', () async {
    when(() => dio.get<Map<String, dynamic>>('/forecasts',
            queryParameters: {'year': 2026}))
        .thenAnswer((_) async => ok({
          'year': 2026,
          'months': [
            {'month': '2026-01', 'income': 5000, 'expense': 2000, 'net': 3000},
          ],
          'totalIncome': 63150,
          'totalExpense': 25660,
          'netForecast': 37490,
          'currency': 'EUR',
        }));

    final forecast = await repo.getForecast(2026);

    expect(forecast.months[0].income, isA<double>());
    expect(forecast.totalIncome, isA<double>());
  });

  test('getForecast captures year parameter in request', () async {
    when(() => dio.get<Map<String, dynamic>>('/forecasts',
            queryParameters: {'year': 2025}))
        .thenAnswer((_) async => ok({
          'year': 2025,
          'months': <Map<String, dynamic>>[],
          'totalIncome': 0,
          'totalExpense': 0,
          'netForecast': 0,
          'currency': 'EUR',
        }));

    await repo.getForecast(2025);

    verify(() => dio.get<Map<String, dynamic>>('/forecasts',
        queryParameters: {'year': 2025})).called(1);
  });

  test('getForecast maps DioException to ApiException', () async {
    when(() => dio.get<Map<String, dynamic>>('/forecasts',
            queryParameters: {'year': 2026}))
        .thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/forecasts'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getForecast(2026), throwsA(isA<NetworkException>()));
  });
}
