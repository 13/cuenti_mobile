import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/budget.dart';
import '../domain/budget_progress.dart';

final budgetsRepositoryProvider = Provider<BudgetsRepository>(
    (ref) => BudgetsRepository(ref.watch(dioProvider)));

class BudgetsRepository {
  BudgetsRepository(this._dio);
  final Dio _dio;

  Future<List<BudgetProgress>> getProgress() => _guard(() async {
        final res = await _dio.get<List<dynamic>>('/budgets/progress');
        return (res.data ?? [])
            .map((e) => BudgetProgress.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Budget> save(Budget b) => _guard(() async {
        final json = {
          'categoryId': b.categoryId,
          'monthlyLimit': b.monthlyLimit,
          'active': b.active,
        };
        final res = b.id != null
            ? await _dio.put<Map<String, dynamic>>('/budgets/${b.id}',
                data: json)
            : await _dio.post<Map<String, dynamic>>('/budgets', data: json);
        return Budget.fromJson(res.data!);
      });

  Future<void> delete(int id) =>
      _guard(() => _dio.delete<void>('/budgets/$id'));
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
