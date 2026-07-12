import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/category.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
    (ref) => CategoriesRepository(ref.watch(dioProvider)));

class CategoriesRepository {
  CategoriesRepository(this._dio);
  final Dio _dio;

  Future<List<Category>> getAll({String? type}) => _guard(() async {
        final res = await _dio.get<List<dynamic>>(
          '/categories',
          queryParameters: type != null ? {'type': type} : null,
        );
        return (res.data ?? [])
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Category> save(Category category) => _guard(() async {
        final json = category.toJson()..remove('id');
        final res = category.id != null
            ? await _dio.put<Map<String, dynamic>>(
                '/categories/${category.id}', data: json)
            : await _dio.post<Map<String, dynamic>>('/categories', data: json);
        return Category.fromJson(res.data!);
      });

  Future<void> delete(int id) =>
      _guard(() => _dio.delete<void>('/categories/$id'));
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
