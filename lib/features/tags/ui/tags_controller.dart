import 'package:cuentimobile/features/tags/data/tags_repository.dart';
import 'package:cuentimobile/features/tags/domain/tag.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tags_controller.g.dart';

@riverpod
class TagsController extends _$TagsController {
  @override
  Future<List<Tag>> build() => ref.watch(tagsRepositoryProvider).getAll();

  Future<void> save(Tag tag) async {
    await ref.read(tagsRepositoryProvider).save(tag);
    ref.invalidateSelf();
    await future;
  }

  /// Optimistic delete with revert on failure.
  Future<void> delete(int id) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((t) => t.id != id).toList());
    try {
      await ref.read(tagsRepositoryProvider).delete(id);
      ref.invalidateSelf();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}
