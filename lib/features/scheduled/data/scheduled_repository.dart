import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/scheduled_transaction.dart';

final scheduledRepositoryProvider = Provider<ScheduledRepository>(
    (ref) => ScheduledRepository(ref.watch(dioProvider)));

class ScheduledRepository {
  ScheduledRepository(this._dio);
  final Dio _dio;

  Future<List<ScheduledTransaction>> getAll() => _guard(() async {
        final res = await _dio.get<List<dynamic>>('/scheduled-transactions');
        return (res.data ?? [])
            .map((e) => ScheduledTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<ScheduledTransaction> save(ScheduledTransaction transaction) => _guard(() async {
        // Explicit writable fields only; derived fields like fromAccountName,
        // toAccountName, categoryName, assetName must not be sent.
        final json = {
          'type': transaction.type,
          'fromAccountId': transaction.fromAccountId,
          'toAccountId': transaction.toAccountId,
          'amount': transaction.amount,
          'payee': transaction.payee,
          'categoryId': transaction.categoryId,
          'memo': transaction.memo,
          'tags': transaction.tags,
          'number': transaction.number,
          'assetId': transaction.assetId,
          'units': transaction.units,
          'recurrencePattern': transaction.recurrencePattern,
          'recurrenceValue': transaction.recurrenceValue,
          'nextOccurrence': transaction.nextOccurrence.toIso8601String(),
          'enabled': transaction.enabled,
        };
        final res = transaction.id != null
            ? await _dio.put<Map<String, dynamic>>(
                '/scheduled-transactions/${transaction.id}', data: json)
            : await _dio.post<Map<String, dynamic>>('/scheduled-transactions', data: json);
        return ScheduledTransaction.fromJson(res.data!);
      });

  Future<void> delete(int id) =>
      _guard(() => _dio.delete<void>('/scheduled-transactions/$id'));

  Future<void> post(int id) =>
      _guard(() => _dio.post<Map<String, dynamic>>('/scheduled-transactions/$id/post'));

  Future<void> skip(int id) =>
      _guard(() => _dio.post<Map<String, dynamic>>('/scheduled-transactions/$id/skip'));
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
