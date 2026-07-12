import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/payees_repository.dart';
import '../domain/payee.dart';

part 'payees_controller.g.dart';

@riverpod
class PayeesController extends _$PayeesController {
  @override
  Future<List<Payee>> build() =>
      ref.watch(payeesRepositoryProvider).getAll();

  Future<void> save(Payee payee) async {
    await ref.read(payeesRepositoryProvider).save(payee);
    ref.invalidateSelf();
    await future;
  }

  /// Optimistic delete with revert on failure (matches old DataProvider).
  Future<void> delete(int id) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((p) => p.id != id).toList());
    try {
      await ref.read(payeesRepositoryProvider).delete(id);
      ref.invalidateSelf();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}
