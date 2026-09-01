import 'package:cuentimobile/core/api/api_guard.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final exportImportRepositoryProvider = Provider<ExportImportRepository>(
  (ref) => ExportImportRepository(ref.watch(dioProvider)),
);

class ExportImportRepository {
  ExportImportRepository(this._dio);
  final Dio _dio;

  /// Raw JSON export string from the backend.
  Future<String> exportJson() => guardApi(() async {
    final res = await _dio.get<String>(
      '/json-export-import/export',
      options: Options(responseType: ResponseType.plain),
    );
    return res.data ?? '';
  });

  Future<void> importJson(String json) => guardApi(() async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromString(
        json,
        filename: 'import.json',
        contentType: DioMediaType('application', 'json'),
      ),
    });
    await _dio.post<void>('/json-export-import/import', data: form);
  });
}
