import 'package:cuentimobile/core/api/api_guard.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(ref.watch(dioProvider)),
);

class CategoriesRepository {
  CategoriesRepository(this._dio);
  final Dio _dio;

  Future<List<Category>> getAll({String? type}) => guardApi(() async {
    final res = await _dio.get<List<dynamic>>(
      '/categories',
      queryParameters: type != null ? {'type': type} : null,
    );
    return (res.data ?? [])
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  Future<Category> save(Category category) => guardApi(() async {
    // Explicit writable fields only (matches old Category.toJson body);
    // derived fields like fullName/parentName must not be sent.
    final json = {
      'name': category.name,
      'type': category.type,
      'parentId': category.parentId,
    };
    final res = category.id != null
        ? await _dio.put<Map<String, dynamic>>(
            '/categories/${category.id}',
            data: json,
          )
        : await _dio.post<Map<String, dynamic>>('/categories', data: json);
    return Category.fromJson(res.data!);
  });

  Future<void> delete(int id) =>
      guardApi(() => _dio.delete<void>('/categories/$id'));
}
