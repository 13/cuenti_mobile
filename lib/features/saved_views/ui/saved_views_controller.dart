import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/domain/transaction_filter_codec.dart';
import '../data/saved_views_repository.dart';
import '../domain/saved_view.dart';

part 'saved_views_controller.g.dart';

@riverpod
class SavedViewsController extends _$SavedViewsController {
  @override
  Future<List<SavedView>> build() =>
      ref.watch(savedViewsRepositoryProvider).getAll();

  Future<void> saveCurrent(String name, TransactionFilter filter) async {
    await ref
        .read(savedViewsRepositoryProvider)
        .save(name, TransactionFilterCodec.encode(filter));
    ref.invalidateSelf();
    await future;
  }

  /// Optimistic delete with revert on failure.
  Future<void> delete(int id) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((v) => v.id != id).toList());
    try {
      await ref.read(savedViewsRepositoryProvider).delete(id);
      ref.invalidateSelf();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}
