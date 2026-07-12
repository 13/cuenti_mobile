import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/account.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>(
    (ref) => AccountsRepository(ref.watch(dioProvider)));

class AccountsRepository {
  AccountsRepository(this._dio);
  final Dio _dio;

  Future<List<Account>> getAll() => _guard(() async {
        final res = await _dio.get<List<dynamic>>('/accounts');
        return (res.data ?? [])
            .map((e) => Account.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Account> save(Account account) => _guard(() async {
        final json = account.toJson()..remove('id');
        final res = account.id != null
            ? await _dio.put<Map<String, dynamic>>(
                '/accounts/${account.id}', data: json)
            : await _dio.post<Map<String, dynamic>>('/accounts', data: json);
        return Account.fromJson(res.data!);
      });

  Future<void> delete(int id) =>
      _guard(() => _dio.delete<void>('/accounts/$id'));

  Future<void> updateSortOrder(List<int> ids) =>
      _guard(() => _dio.put<void>('/accounts/sort-order', data: ids));
}

/// Shared guard: rethrows DioException as ApiException. Copy this exact
/// helper into each repository file (3 lines; a shared base class would
/// couple repositories for no gain).
Future<T> _guard<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}
