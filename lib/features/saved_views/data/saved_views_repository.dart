import 'package:cuentimobile/core/api/api_guard.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/features/saved_views/domain/saved_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final savedViewsRepositoryProvider = Provider<SavedViewsRepository>(
  (ref) => SavedViewsRepository(ref.watch(dioProvider)),
);

class SavedViewsRepository {
  SavedViewsRepository(this._dio);
  final Dio _dio;

  Future<List<SavedView>> getAll() => guardApi(() async {
    final res = await _dio.get<List<dynamic>>('/saved-views');
    return (res.data ?? [])
        .map((e) => SavedView.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  /// Upserts by name server-side.
  Future<SavedView> save(String name, String params) => guardApi(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/saved-views',
      data: {'name': name, 'params': params},
    );
    return SavedView.fromJson(res.data!);
  });

  Future<void> delete(int id) =>
      guardApi(() => _dio.delete<void>('/saved-views/$id'));
}
