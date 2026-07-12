import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/saved_view.dart';

final savedViewsRepositoryProvider = Provider<SavedViewsRepository>(
    (ref) => SavedViewsRepository(ref.watch(dioProvider)));

class SavedViewsRepository {
  SavedViewsRepository(this._dio);
  final Dio _dio;

  Future<List<SavedView>> getAll() => _guard(() async {
        final res = await _dio.get<List<dynamic>>('/saved-views');
        return (res.data ?? [])
            .map((e) => SavedView.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  /// Upserts by name server-side.
  Future<SavedView> save(String name, String params) => _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/saved-views',
          data: {'name': name, 'params': params},
        );
        return SavedView.fromJson(res.data!);
      });

  Future<void> delete(int id) =>
      _guard(() => _dio.delete<void>('/saved-views/$id'));
}

/// Shared guard: rethrows DioException as ApiException. Copy this exact
/// helper into each repository file (3 lines; a shared base class would
/// couple repositories for no gain).
Future<T> _guard<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}
