import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/forecast_data.dart';

final forecastsRepositoryProvider = Provider<ForecastsRepository>(
    (ref) => ForecastsRepository(ref.watch(dioProvider)));

class ForecastsRepository {
  ForecastsRepository(this._dio);
  final Dio _dio;

  Future<ForecastData> getForecast(int year) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/forecasts',
            queryParameters: {'year': year});
        return ForecastData.fromJson(res.data ?? {});
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
