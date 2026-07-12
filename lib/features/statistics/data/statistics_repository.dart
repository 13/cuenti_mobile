import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/statistics_data.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>(
    (ref) => StatisticsRepository(ref.watch(dioProvider)));

class StatisticsRepository {
  StatisticsRepository(this._dio);
  final Dio _dio;

  Future<StatisticsData> load({String? start, String? end, int? accountId}) =>
      _guard(() async {
        final params = <String, dynamic>{
          if (start != null) 'start': start,
          if (end != null) 'end': end,
          if (accountId != null) 'accountId': accountId,
        };
        final res = await _dio.get<Map<String, dynamic>>('/statistics',
            queryParameters: params);
        return StatisticsData.fromJson(res.data!);
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
