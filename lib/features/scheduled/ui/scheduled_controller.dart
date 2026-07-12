import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import '../data/scheduled_repository.dart';
import '../domain/scheduled_transaction.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_controller.dart';

part 'scheduled_controller.g.dart';

@riverpod
class ScheduledController extends _$ScheduledController {
  @override
  Future<List<ScheduledTransaction>> build() =>
      ref.watch(scheduledRepositoryProvider).getAll();

  Future<void> save(ScheduledTransaction transaction) async {
    await ref.read(scheduledRepositoryProvider).save(transaction);
    ref.invalidateSelf();
    await future;
  }

  /// Optimistic delete with revert on failure (matches old DataProvider).
  Future<void> delete(int id) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((t) => t.id != id).toList());
    try {
      await ref.read(scheduledRepositoryProvider).delete(id);
      ref.invalidateSelf();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Post scheduled transaction, invalidating self, accounts, and transactions
  /// since posting creates a transaction.
  Future<void> post(int id) async {
    await ref.read(scheduledRepositoryProvider).post(id);
    ref.invalidateSelf();
    ref.invalidate(accountsControllerProvider);
    // Invalidate the family target (all instances) of transactionsControllerProvider
    ref.invalidate(transactionsControllerProvider);
    await future;
  }

  /// Skip scheduled transaction, invalidating self only.
  Future<void> skip(int id) async {
    await ref.read(scheduledRepositoryProvider).skip(id);
    ref.invalidateSelf();
    await future;
  }
}
