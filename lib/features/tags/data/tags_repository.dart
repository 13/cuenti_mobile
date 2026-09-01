import 'package:cuentimobile/core/api/api_guard.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/features/tags/domain/tag.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tagsRepositoryProvider = Provider<TagsRepository>(
  (ref) => TagsRepository(ref.watch(dioProvider)),
);

class TagsRepository {
  TagsRepository(this._dio);
  final Dio _dio;

  Future<List<Tag>> getAll({String? search}) => guardApi(() async {
    final res = await _dio.get<List<dynamic>>(
      '/tags',
      queryParameters: search != null ? {'search': search} : null,
    );
    return (res.data ?? [])
        .map((e) => Tag.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  Future<Tag> save(Tag tag) => guardApi(() async {
    final json = tag.toJson()..remove('id');
    final res = tag.id != null
        ? await _dio.put<Map<String, dynamic>>('/tags/${tag.id}', data: json)
        : await _dio.post<Map<String, dynamic>>('/tags', data: json);
    return Tag.fromJson(res.data!);
  });

  Future<void> delete(int id) => guardApi(() => _dio.delete<void>('/tags/$id'));
}
