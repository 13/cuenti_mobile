import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';

final exportImportRepositoryProvider = Provider<ExportImportRepository>(
    (ref) => ExportImportRepository(ref.watch(dioProvider)));

class ExportImportRepository {
  ExportImportRepository(this._dio);
  final Dio _dio;

  /// Raw JSON export string from the backend.
  Future<String> exportJson() => _guard(() async {
        final res = await _dio.get<String>('/json-export-import/export',
            options: Options(responseType: ResponseType.plain));
        return res.data ?? '';
      });

  Future<void> importJson(String json) =>
      _guard(() => _dio.post<void>('/json-export-import/import',
          data: json,
          options: Options(contentType: 'application/json')));
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
