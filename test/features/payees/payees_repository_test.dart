import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/payees/data/payees_repository.dart';
import 'package:cuentimobile/features/payees/domain/payee.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late PayeesRepository repo;

  setUp(() {
    dio = MockDio();
    repo = PayeesRepository(dio);
  });

  test('getAll parses list of payees', () async {
    when(() => dio.get<List<dynamic>>('/payees')).thenAnswer((_) async => ok([
          {'id': 1, 'name': 'Supermarket', 'notes': 'Local shop'},
          {'id': 2, 'name': 'Gas Station', 'notes': null},
        ]));

    final payees = await repo.getAll();

    expect(payees, hasLength(2));
    expect(payees[0].id, 1);
    expect(payees[0].name, 'Supermarket');
    expect(payees[1].name, 'Gas Station');
  });

  test('getAll passes search query param when non-null', () async {
    when(() => dio.get<List<dynamic>>('/payees',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => ok([
          {'id': 1, 'name': 'Supermarket'}
        ]));

    await repo.getAll(search: 'super');

    verify(() => dio.get<List<dynamic>>('/payees',
        queryParameters: {'search': 'super'})).called(1);
  });

  test('save posts new payee when id is null', () async {
    const payee = Payee(name: 'New Payee');
    when(() => dio.post<Map<String, dynamic>>('/payees',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({'id': 5, 'name': 'New Payee'}));

    final saved = await repo.save(payee);

    expect(saved.id, 5);
    final captured = verify(() => dio.post<Map<String, dynamic>>('/payees',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured.containsKey('id'), isFalse);
    expect(captured['name'], 'New Payee');
    expect(captured['defaultPaymentMethod'], 'NONE');
  });

  test('save puts existing payee when id is set', () async {
    const payee = Payee(id: 7, name: 'Existing');
    when(() => dio.put<Map<String, dynamic>>('/payees/7',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({'id': 7, 'name': 'Existing'}));

    final saved = await repo.save(payee);

    expect(saved.id, 7);
    verify(() => dio.put<Map<String, dynamic>>('/payees/7',
        data: any(named: 'data'))).called(1);
  });

  test('delete calls DELETE /payees/{id}', () async {
    when(() => dio.delete<void>('/payees/3')).thenAnswer((_) async => ok(null));

    await repo.delete(3);

    verify(() => dio.delete<void>('/payees/3')).called(1);
  });

  test('getAll maps DioException to ApiException', () async {
    when(() => dio.get<List<dynamic>>('/payees')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/payees'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getAll(), throwsA(isA<NetworkException>()));
  });
}
