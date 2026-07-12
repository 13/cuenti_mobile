import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/currencies/data/currencies_repository.dart';
import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late CurrenciesRepository repo;

  setUp(() {
    dio = MockDio();
    repo = CurrenciesRepository(dio);
  });

  test('getAll parses list of currencies', () async {
    when(() => dio.get<List<dynamic>>('/currencies')).thenAnswer((_) async => ok([
          {
            'id': 1,
            'code': 'USD',
            'name': 'US Dollar',
            'symbol': '\$',
            'decimalChar': '.',
            'fracDigits': 2,
            'groupingChar': ',',
          },
          {
            'id': 2,
            'code': 'EUR',
            'name': 'Euro',
            'symbol': '€',
            'decimalChar': ',',
            'fracDigits': 2,
            'groupingChar': '.',
          },
        ]));

    final currencies = await repo.getAll();

    expect(currencies, hasLength(2));
    expect(currencies[0].id, 1);
    expect(currencies[0].code, 'USD');
    expect(currencies[1].code, 'EUR');
  });

  test('save posts new currency when id is null', () async {
    const currency = Currency(
        code: 'GBP',
        name: 'British Pound',
        symbol: '£',
        decimalChar: '.',
        fracDigits: 2,
        groupingChar: ',');
    when(() => dio.post<Map<String, dynamic>>('/currencies', data: any(named: 'data')))
        .thenAnswer((_) async => ok({
          'id': 3,
          'code': 'GBP',
          'name': 'British Pound',
          'symbol': '£',
          'decimalChar': '.',
          'fracDigits': 2,
          'groupingChar': ',',
        }));

    final saved = await repo.save(currency);

    expect(saved.id, 3);
    expect(saved.code, 'GBP');
    final captured = verify(() =>
            dio.post<Map<String, dynamic>>('/currencies', data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured, containsPair('code', 'GBP'));
    expect(captured, containsPair('name', 'British Pound'));
    expect(captured, containsPair('symbol', '£'));
    expect(captured, containsPair('decimalChar', '.'));
    expect(captured, containsPair('fracDigits', 2));
    expect(captured, containsPair('groupingChar', ','));
    expect(captured.keys, isNot(contains('id')));
  });

  test('save puts existing currency when id is set', () async {
    const currency = Currency(id: 1, code: 'USD', name: 'US Dollar', symbol: '\$');
    when(() => dio.put<Map<String, dynamic>>('/currencies/1', data: any(named: 'data')))
        .thenAnswer((_) async =>
            ok({'id': 1, 'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'}));

    final saved = await repo.save(currency);

    expect(saved.id, 1);
    verify(() => dio.put<Map<String, dynamic>>('/currencies/1', data: any(named: 'data')))
        .called(1);
  });

  test('delete calls DELETE /currencies/{id}', () async {
    when(() => dio.delete<void>('/currencies/1')).thenAnswer((_) async => ok(null));

    await repo.delete(1);

    verify(() => dio.delete<void>('/currencies/1')).called(1);
  });

  test('getAll maps DioException to ApiException', () async {
    when(() => dio.get<List<dynamic>>('/currencies')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/currencies'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getAll(), throwsA(isA<NetworkException>()));
  });
}
