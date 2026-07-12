import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/tag.dart';

final tagsRepositoryProvider = Provider<TagsRepository>(
    (ref) => TagsRepository(ref.watch(dioProvider)));

class TagsRepository {
  TagsRepository(this._dio);
  final Dio _dio;

  Future<List<Tag>> getAll({String? search}) => _guard(() async {
        final res = await _dio.get<List<dynamic>>(
          '/tags',
          queryParameters: search != null ? {'search': search} : null,
        );
        return (res.data ?? [])
            .map((e) => Tag.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Tag> save(Tag tag) => _guard(() async {
        final json = tag.toJson()..remove('id');
        final res = tag.id != null
            ? await _dio.put<Map<String, dynamic>>(
                '/tags/${tag.id}', data: json)
            : await _dio.post<Map<String, dynamic>>('/tags', data: json);
        return Tag.fromJson(res.data!);
      });

  Future<void> delete(int id) =>
      _guard(() => _dio.delete<void>('/tags/$id'));
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
