import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/vehicle_report.dart';

final vehiclesRepositoryProvider = Provider<VehiclesRepository>(
    (ref) => VehiclesRepository(ref.watch(dioProvider)));

final _dateFmt = DateFormat('yyyy-MM-dd');

class VehiclesRepository {
  VehiclesRepository(this._dio);
  final Dio _dio;

  /// [categoryId] is always sent explicitly — the backend falls back to the
  /// profile default when omitted, but the client is the source of truth for
  /// which category the screen is currently showing.
  Future<VehicleReport> getReport({
    required int categoryId,
    DateTime? start,
    DateTime? end,
  }) =>
      _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/vehicles/report',
            queryParameters: {
              'categoryId': categoryId,
              if (start != null) 'start': _dateFmt.format(start),
              if (end != null) 'end': _dateFmt.format(end),
            });
        return VehicleReport.fromJson(res.data ?? {});
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
