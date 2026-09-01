import 'package:cuentimobile/core/api/api_guard.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/features/assets/domain/asset.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final assetsRepositoryProvider = Provider<AssetsRepository>(
  (ref) => AssetsRepository(ref.watch(dioProvider)),
);

class AssetsRepository {
  AssetsRepository(this._dio);
  final Dio _dio;

  Future<List<Asset>> getAll({String? search}) => guardApi(() async {
    final res = await _dio.get<List<dynamic>>(
      '/assets',
      queryParameters: search != null ? {'search': search} : null,
    );
    return (res.data ?? [])
        .map((e) => Asset.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  Future<Asset> save(Asset asset) => guardApi(() async {
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
            '/assets/${asset.id}',
            data: json,
          )
        : await _dio.post<Map<String, dynamic>>('/assets', data: json);
    return Asset.fromJson(res.data!);
  });

  Future<void> delete(int id) =>
      guardApi(() => _dio.delete<void>('/assets/$id'));

  Future<Asset> refreshPrice(int id) => guardApi(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/assets/$id/refresh-price',
    );
    return Asset.fromJson(res.data!);
  });
}
