import 'package:cuentimobile/features/currencies/data/currencies_repository.dart';
import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'currencies_controller.g.dart';

@riverpod
class CurrenciesController extends _$CurrenciesController {
  @override
  Future<List<Currency>> build() =>
      ref.watch(currenciesRepositoryProvider).getAll();

  Future<void> save(Currency currency) async {
    await ref.read(currenciesRepositoryProvider).save(currency);
    ref.invalidateSelf();
    await future;
  }

  /// Optimistic delete with revert on failure.
  Future<void> delete(int id) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((c) => c.id != id).toList());
    try {
      await ref.read(currenciesRepositoryProvider).delete(id);
      ref.invalidateSelf();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}
