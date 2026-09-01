import 'package:cuentimobile/core/api/api_guard.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepository(ref.watch(dioProvider)),
);

class AccountsRepository {
  AccountsRepository(this._dio);
  final Dio _dio;

  Future<List<Account>> getAll() => guardApi(() async {
    final res = await _dio.get<List<dynamic>>('/accounts');
    return (res.data ?? [])
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  Future<Account> save(Account account) => guardApi(() async {
    final json = account.toJson()..remove('id');
    final res = account.id != null
        ? await _dio.put<Map<String, dynamic>>(
            '/accounts/${account.id}',
            data: json,
          )
        : await _dio.post<Map<String, dynamic>>('/accounts', data: json);
    return Account.fromJson(res.data!);
  });

  Future<void> delete(int id) =>
      guardApi(() => _dio.delete<void>('/accounts/$id'));

  Future<void> updateSortOrder(List<int> ids) =>
      guardApi(() => _dio.put<void>('/accounts/sort-order', data: ids));
}
