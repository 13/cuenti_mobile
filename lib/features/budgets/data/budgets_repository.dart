import 'package:cuentimobile/core/api/api_guard.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/features/budgets/domain/budget.dart';
import 'package:cuentimobile/features/budgets/domain/budget_progress.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetsRepositoryProvider = Provider<BudgetsRepository>(
  (ref) => BudgetsRepository(ref.watch(dioProvider)),
);

class BudgetsRepository {
  BudgetsRepository(this._dio);
  final Dio _dio;

  Future<List<BudgetProgress>> getProgress() => guardApi(() async {
    final res = await _dio.get<List<dynamic>>('/budgets/progress');
    return (res.data ?? [])
        .map((e) => BudgetProgress.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  Future<Budget> save(Budget b) => guardApi(() async {
    final json = {
      'categoryId': b.categoryId,
      'monthlyLimit': b.monthlyLimit,
      'active': b.active,
    };
    final res = b.id != null
        ? await _dio.put<Map<String, dynamic>>('/budgets/${b.id}', data: json)
        : await _dio.post<Map<String, dynamic>>('/budgets', data: json);
    return Budget.fromJson(res.data!);
  });

  Future<void> delete(int id) =>
      guardApi(() => _dio.delete<void>('/budgets/$id'));
}
