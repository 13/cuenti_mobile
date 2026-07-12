import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/budgets_repository.dart';
import '../domain/budget.dart';
import '../domain/budget_progress.dart';

part 'budgets_controller.g.dart';

@riverpod
class BudgetsController extends _$BudgetsController {
  @override
  Future<List<BudgetProgress>> build() =>
      ref.watch(budgetsRepositoryProvider).getProgress();

  Future<void> save(Budget budget) async {
    await ref.read(budgetsRepositoryProvider).save(budget);
    ref.invalidateSelf();
    await future;
  }

  /// Unlike the optimistic delete-with-revert used by other CRUD
  /// controllers (accounts/categories), [BudgetProgress] rows are derived
  /// server-side from the linked transactions (spent/remaining), not a
  /// plain list entry we could locally drop and restore. A simple
  /// invalidate-and-refetch is correct and simpler here.
  Future<void> delete(int id) async {
    await ref.read(budgetsRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}
