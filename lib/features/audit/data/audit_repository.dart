import 'package:cuentimobile/core/api/api_guard.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/features/audit/domain/audit_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final auditRepositoryProvider = Provider<AuditRepository>(
  (ref) => AuditRepository(ref.watch(dioProvider)),
);

class AuditRepository {
  AuditRepository(this._dio);
  final Dio _dio;

  /// Paged fetch using the Phase 1 envelope.
  Future<AuditPage> getPage({
    int page = 0,
    int size = 50,
    String? filter,
  }) => guardApi(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/audit-log',
      queryParameters: {
        if (filter != null && filter.isNotEmpty) 'filter': filter,
        'page': page,
        'size': size,
      },
    );
    return AuditPage.fromJson(res.data!);
  });
}
