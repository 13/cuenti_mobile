import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/dashboard/data/dashboard_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late DashboardRepository repo;

  setUp(() {
    dio = MockDio();
    repo = DashboardRepository(dio);
  });

  test('load parses envelope with nested accounts and assetPerformance',
      () async {
    when(() => dio.get<Map<String, dynamic>>('/dashboard'))
        .thenAnswer((_) async => ok({
              'availableCash': 100.0,
              'portfolioValue': 250.5,
              'netWorth': 350.5,
              'defaultCurrency': 'EUR',
              'accounts': [
                {'id': 1, 'accountName': 'Giro', 'currency': 'EUR'},
                {'id': 2, 'accountName': 'Savings', 'currency': 'EUR'},
              ],
              'assetPerformance': [
                {
                  'assetName': 'Bitcoin',
                  'assetSymbol': 'BTC',
                  'totalUnits': 0.5,
                  'totalCost': 10000.0,
                  'currentValue': 12000.0,
                  'currentPrice': 24000.0,
                  'gainLoss': 2000.0,
                  'gainLossPercent': 20.0,
                },
              ],
            }));

    final dashboard = await repo.load();

    expect(dashboard.availableCash, 100.0);
    expect(dashboard.netWorth, 350.5);
    expect(dashboard.defaultCurrency, 'EUR');
    expect(dashboard.accounts, hasLength(2));
    expect(dashboard.accounts[0].accountName, 'Giro');
    expect(dashboard.assetPerformance, hasLength(1));
    expect(dashboard.assetPerformance[0].assetName, 'Bitcoin');
    expect(dashboard.assetPerformance[0].gainLossPercent, 20.0);
  });

  test('load maps DioException to ApiException', () async {
    when(() => dio.get<Map<String, dynamic>>('/dashboard')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/dashboard'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.load(), throwsA(isA<NetworkException>()));
  });
}
