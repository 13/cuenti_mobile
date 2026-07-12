import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/asset.dart';

final assetsRepositoryProvider = Provider<AssetsRepository>(
    (ref) => AssetsRepository(ref.watch(dioProvider)));

class AssetsRepository {
  AssetsRepository(this._dio);
  final Dio _dio;

  Future<List<Asset>> getAll({String? search}) => _guard(() async {
        final res = await _dio.get<List<dynamic>>(
          '/assets',
          queryParameters: search != null ? {'search': search} : null,
        );
        return (res.data ?? [])
            .map((e) => Asset.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Asset> save(Asset asset) => _guard(() async {
        // Explicit writable fields only (matches old Asset.toJson body);
        // derived fields like currentPrice/lastUpdate must not be sent.
        final json = {
          'symbol': asset.symbol,
          'name': asset.name,
          'type': asset.type,
          'currency': asset.currency,
        };
        final res = asset.id != null
            ? await _dio.put<Map<String, dynamic>>(
                '/assets/${asset.id}', data: json)
            : await _dio.post<Map<String, dynamic>>('/assets', data: json);
        return Asset.fromJson(res.data!);
      });

  Future<void> delete(int id) =>
      _guard(() => _dio.delete<void>('/assets/$id'));

  Future<Asset> refreshPrice(int id) => _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>('/assets/$id/refresh-price');
        return Asset.fromJson(res.data!);
      });
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
