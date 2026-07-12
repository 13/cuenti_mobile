import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late AccountsRepository repo;

  setUp(() {
    dio = MockDio();
    repo = AccountsRepository(dio);
  });

  test('getAll parses list of accounts', () async {
    when(() => dio.get<List<dynamic>>('/accounts')).thenAnswer((_) async => ok([
          {'id': 1, 'accountName': 'Giro', 'accountType': 'BANK'},
          {'id': 2, 'accountName': 'Cash', 'accountType': 'CASH'},
        ]));

    final accounts = await repo.getAll();

    expect(accounts, hasLength(2));
    expect(accounts[0].id, 1);
    expect(accounts[0].accountName, 'Giro');
    expect(accounts[1].accountType, 'CASH');
  });

  test('save posts new account when id is null', () async {
    const account = Account(accountName: 'New');
    when(() => dio.post<Map<String, dynamic>>('/accounts',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({'id': 5, 'accountName': 'New'}));

    final saved = await repo.save(account);

    expect(saved.id, 5);
    final captured = verify(() => dio.post<Map<String, dynamic>>('/accounts',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured.containsKey('id'), isFalse);
  });

  test('save puts existing account when id is set', () async {
    const account = Account(id: 7, accountName: 'Existing');
    when(() => dio.put<Map<String, dynamic>>('/accounts/7',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({'id': 7, 'accountName': 'Existing'}));

    final saved = await repo.save(account);

    expect(saved.id, 7);
    verify(() => dio.put<Map<String, dynamic>>('/accounts/7',
        data: any(named: 'data'))).called(1);
  });

  test('delete calls DELETE /accounts/{id}', () async {
    when(() => dio.delete<void>('/accounts/3')).thenAnswer((_) async => ok(null));

    await repo.delete(3);

    verify(() => dio.delete<void>('/accounts/3')).called(1);
  });

  test('updateSortOrder calls PUT /accounts/sort-order with ids', () async {
    when(() => dio.put<void>('/accounts/sort-order', data: [3, 1, 2]))
        .thenAnswer((_) async => ok(null));

    await repo.updateSortOrder([3, 1, 2]);

    verify(() => dio.put<void>('/accounts/sort-order', data: [3, 1, 2]))
        .called(1);
  });

  test('getAll maps DioException to ApiException', () async {
    when(() => dio.get<List<dynamic>>('/accounts')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/accounts'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getAll(), throwsA(isA<NetworkException>()));
  });
}
