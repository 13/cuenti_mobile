import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/assets_repository.dart';
import '../domain/asset.dart';

part 'assets_controller.g.dart';

@riverpod
class AssetsController extends _$AssetsController {
  @override
  Future<List<Asset>> build() => ref.watch(assetsRepositoryProvider).getAll();

  Future<void> save(Asset asset) async {
    await ref.read(assetsRepositoryProvider).save(asset);
    ref.invalidateSelf();
    await future;
  }

  /// Optimistic delete with revert on failure (matches old DataProvider).
  Future<void> delete(int id) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((a) => a.id != id).toList());
    try {
      await ref.read(assetsRepositoryProvider).delete(id);
      ref.invalidateSelf();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> refreshPrice(int id) async {
    await ref.read(assetsRepositoryProvider).refreshPrice(id);
    ref.invalidateSelf();
    await future;
  }
}
