import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/payee.dart';

final payeesRepositoryProvider = Provider<PayeesRepository>(
    (ref) => PayeesRepository(ref.watch(dioProvider)));

class PayeesRepository {
  PayeesRepository(this._dio);
  final Dio _dio;

  Future<List<Payee>> getAll({String? search}) => _guard(() async {
        final res = await _dio.get<List<dynamic>>(
          '/payees',
          queryParameters: search != null ? {'search': search} : null,
        );
        return (res.data ?? [])
            .map((e) => Payee.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Payee> save(Payee payee) => _guard(() async {
        // Explicit writable fields only (matches old Payee.toJson body);
        // derived fields like defaultCategoryName must not be sent.
        final json = {
          'name': payee.name,
          'notes': payee.notes,
          'defaultCategoryId': payee.defaultCategoryId,
          'defaultPaymentMethod': payee.defaultPaymentMethod ?? 'NONE',
        };
        final res = payee.id != null
            ? await _dio.put<Map<String, dynamic>>(
                '/payees/${payee.id}', data: json)
            : await _dio.post<Map<String, dynamic>>('/payees', data: json);
        return Payee.fromJson(res.data!);
      });

  Future<void> delete(int id) =>
      _guard(() => _dio.delete<void>('/payees/$id'));
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
