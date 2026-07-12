import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/assets/data/assets_repository.dart';
import 'package:cuentimobile/features/assets/domain/asset.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late AssetsRepository repo;

  setUp(() {
    dio = MockDio();
    repo = AssetsRepository(dio);
  });

  test('getAll parses list of assets', () async {
    when(() => dio.get<List<dynamic>>('/assets')).thenAnswer((_) async => ok([
          {
            'id': 1,
            'symbol': 'AAPL',
            'name': 'Apple Inc',
            'type': 'STOCK',
            'currentPrice': null,
            'currency': 'USD',
            'lastUpdate': null,
          },
          {
            'id': 2,
            'symbol': 'BTC',
            'name': 'Bitcoin',
            'type': 'CRYPTO',
            'currentPrice': null,
            'currency': 'USD',
            'lastUpdate': null,
          },
        ]));

    final assets = await repo.getAll();

    expect(assets, hasLength(2));
    expect(assets[0].id, 1);
    expect(assets[0].symbol, 'AAPL');
    expect(assets[1].type, 'CRYPTO');
  });

  test('getAll passes search query param when non-null', () async {
    when(() => dio.get<List<dynamic>>('/assets',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => ok([
          {
            'id': 1,
            'symbol': 'AAPL',
            'name': 'Apple Inc',
            'type': 'STOCK',
            'currency': 'USD',
          }
        ]));

    await repo.getAll(search: 'AAPL');

    verify(() => dio.get<List<dynamic>>('/assets',
        queryParameters: {'search': 'AAPL'})).called(1);
  });

  test('save posts new asset when id is null', () async {
    const asset = Asset(symbol: 'AAPL', name: 'Apple Inc', type: 'STOCK', currency: 'USD');
    when(() => dio.post<Map<String, dynamic>>('/assets', data: any(named: 'data')))
        .thenAnswer((_) async => ok({
          'id': 5,
          'symbol': 'AAPL',
          'name': 'Apple Inc',
          'type': 'STOCK',
          'currency': 'USD',
        }));

    final saved = await repo.save(asset);

    expect(saved.id, 5);
    final captured = verify(
            () => dio.post<Map<String, dynamic>>('/assets', data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured, containsPair('symbol', 'AAPL'));
    expect(captured, containsPair('name', 'Apple Inc'));
    expect(captured, containsPair('type', 'STOCK'));
    expect(captured, containsPair('currency', 'USD'));
    expect(captured.keys, isNot(contains('id')));
    expect(captured.keys, isNot(contains('currentPrice')));
    expect(captured.keys, isNot(contains('lastUpdate')));
  });

  test('save puts existing asset when id is set', () async {
    const asset = Asset(id: 1, symbol: 'AAPL', name: 'Apple Inc', type: 'STOCK');
    when(() => dio.put<Map<String, dynamic>>('/assets/1', data: any(named: 'data')))
        .thenAnswer((_) async =>
            ok({'id': 1, 'symbol': 'AAPL', 'name': 'Apple Inc', 'type': 'STOCK'}));

    final saved = await repo.save(asset);

    expect(saved.id, 1);
    verify(() => dio.put<Map<String, dynamic>>('/assets/1', data: any(named: 'data')))
        .called(1);
  });

  test('delete calls DELETE /assets/{id}', () async {
    when(() => dio.delete<void>('/assets/1')).thenAnswer((_) async => ok(null));

    await repo.delete(1);

    verify(() => dio.delete<void>('/assets/1')).called(1);
  });

  test('refreshPrice calls POST /assets/{id}/refresh-price and returns asset', () async {
    when(() => dio.post<Map<String, dynamic>>('/assets/1/refresh-price'))
        .thenAnswer((_) async => ok({
          'id': 1,
          'symbol': 'AAPL',
          'name': 'Apple Inc',
          'type': 'STOCK',
          'currentPrice': 150.25,
          'currency': 'USD',
          'lastUpdate': '2026-07-12T10:30:00Z',
        }));

    final asset = await repo.refreshPrice(1);

    expect(asset.id, 1);
    expect(asset.currentPrice, 150.25);
    verify(() => dio.post<Map<String, dynamic>>('/assets/1/refresh-price')).called(1);
  });

  test('getAll maps DioException to ApiException', () async {
    when(() => dio.get<List<dynamic>>('/assets')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/assets'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getAll(), throwsA(isA<NetworkException>()));
  });
}
