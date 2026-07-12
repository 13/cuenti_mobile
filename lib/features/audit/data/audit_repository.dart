import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/audit_page.dart';

final auditRepositoryProvider = Provider<AuditRepository>(
    (ref) => AuditRepository(ref.watch(dioProvider)));

class AuditRepository {
  AuditRepository(this._dio);
  final Dio _dio;

  /// Paged fetch using the Phase 1 envelope.
  Future<AuditPage> getPage({
    int page = 0,
    int size = 50,
    String? filter,
  }) =>
      _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/audit-log',
            queryParameters: {
              if (filter != null && filter.isNotEmpty) 'filter': filter,
              'page': page,
              'size': size,
            });
        return AuditPage.fromJson(res.data!);
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
