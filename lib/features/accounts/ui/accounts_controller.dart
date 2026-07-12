import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/accounts_repository.dart';
import '../domain/account.dart';

part 'accounts_controller.g.dart';

@riverpod
class AccountsController extends _$AccountsController {
  @override
  Future<List<Account>> build() =>
      ref.watch(accountsRepositoryProvider).getAll();

  Future<void> save(Account account) async {
    await ref.read(accountsRepositoryProvider).save(account);
    ref.invalidateSelf();
    await future;
  }

  /// Optimistic delete with revert on failure.
  Future<void> delete(int id) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((a) => a.id != id).toList());
    try {
      await ref.read(accountsRepositoryProvider).delete(id);
      ref.invalidateSelf();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateSortOrder(List<int> ids) async {
    await ref.read(accountsRepositoryProvider).updateSortOrder(ids);
    ref.invalidateSelf();
  }
}
