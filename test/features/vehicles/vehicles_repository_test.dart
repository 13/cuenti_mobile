import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/vehicles/data/vehicles_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late VehiclesRepository repo;

  setUp(() {
    dio = MockDio();
    repo = VehiclesRepository(dio);
  });

  test('getReport parses entries and totals, including nullable fields', () async {
    when(() => dio.get<Map<String, dynamic>>('/vehicles/report',
            queryParameters: {'categoryId': 7}))
        .thenAnswer((_) async => ok({
          'entries': [
            {
              'date': '2026-01-05',
              'odometer': 12000.0,
              'liters': 40.5,
              'amount': 65.3,
              'currency': 'EUR',
              'station': 'Shell',
              'memo': 'Full tank',
              'fullTank': true,
              'distance': 450.0,
              'pricePerLiter': 1.612,
              'consumption': 9.0,
            },
            {
              'date': '2026-01-20',
              'fullTank': false,
            },
          ],
          'totalCost': 65.3,
          'totalLiters': 40.5,
          'totalDistance': 450.0,
          'avgConsumption': 9.0,
          'avgPricePerLiter': 1.612,
          'currency': 'EUR',
        }));

    final report = await repo.getReport(categoryId: 7);

    expect(report.entries, hasLength(2));
    final first = report.entries[0];
    expect(first.date, DateTime.parse('2026-01-05'));
    expect(first.odometer, 12000.0);
    expect(first.liters, 40.5);
    expect(first.amount, 65.3);
    expect(first.currency, 'EUR');
    expect(first.station, 'Shell');
    expect(first.memo, 'Full tank');
    expect(first.fullTank, true);
    expect(first.distance, 450.0);
    expect(first.pricePerLiter, 1.612);
    expect(first.consumption, 9.0);

    final second = report.entries[1];
    expect(second.odometer, isNull);
    expect(second.liters, isNull);
    expect(second.amount, isNull);
    expect(second.distance, isNull);
    expect(second.pricePerLiter, isNull);
    expect(second.consumption, isNull);
    expect(second.fullTank, false);

    expect(report.totalCost, 65.3);
    expect(report.totalLiters, 40.5);
    expect(report.totalDistance, 450.0);
    expect(report.avgConsumption, 9.0);
    expect(report.avgPricePerLiter, 1.612);
    expect(report.currency, 'EUR');
  });

  test('getReport defaults totals and avg fields when report is empty', () async {
    when(() => dio.get<Map<String, dynamic>>('/vehicles/report',
            queryParameters: {'categoryId': 7}))
        .thenAnswer((_) async => ok({'entries': <Map<String, dynamic>>[]}));

    final report = await repo.getReport(categoryId: 7);

    expect(report.entries, isEmpty);
    expect(report.totalCost, 0);
    expect(report.totalLiters, 0);
    expect(report.totalDistance, 0);
    expect(report.avgConsumption, isNull);
    expect(report.avgPricePerLiter, isNull);
    expect(report.currency, 'EUR');
  });

  test('getReport always sends categoryId, even without a date range', () async {
    when(() => dio.get<Map<String, dynamic>>('/vehicles/report',
            queryParameters: {'categoryId': 7}))
        .thenAnswer((_) async => ok({'entries': <Map<String, dynamic>>[]}));

    await repo.getReport(categoryId: 7);

    verify(() => dio.get<Map<String, dynamic>>('/vehicles/report',
        queryParameters: {'categoryId': 7})).called(1);
  });

  test('getReport formats start/end as yyyy-MM-dd query params', () async {
    when(() => dio.get<Map<String, dynamic>>('/vehicles/report',
            queryParameters: {
              'categoryId': 7,
              'start': '2026-01-01',
              'end': '2026-12-31',
            })).thenAnswer((_) async => ok({'entries': <Map<String, dynamic>>[]}));

    await repo.getReport(
      categoryId: 7,
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 12, 31),
    );

    verify(() => dio.get<Map<String, dynamic>>('/vehicles/report',
        queryParameters: {
          'categoryId': 7,
          'start': '2026-01-01',
          'end': '2026-12-31',
        })).called(1);
  });

  test('getReport maps DioException to ApiException', () async {
    when(() => dio.get<Map<String, dynamic>>('/vehicles/report',
            queryParameters: {'categoryId': 7}))
        .thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/vehicles/report'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getReport(categoryId: 7), throwsA(isA<NetworkException>()));
  });
}
