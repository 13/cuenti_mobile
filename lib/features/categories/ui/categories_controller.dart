import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'categories_controller.g.dart';

@riverpod
class CategoriesController extends _$CategoriesController {
  @override
  Future<List<Category>> build() =>
      ref.watch(categoriesRepositoryProvider).getAll();

  Future<void> save(Category category) async {
    await ref.read(categoriesRepositoryProvider).save(category);
    ref.invalidateSelf();
    await future;
  }

  /// Optimistic delete with revert on failure.
  Future<void> delete(int id) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((c) => c.id != id).toList());
    try {
      await ref.read(categoriesRepositoryProvider).delete(id);
      ref.invalidateSelf();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}
