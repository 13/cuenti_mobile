import 'package:cuentimobile/core/api/api_guard.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/features/forecasts/domain/forecast_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final forecastsRepositoryProvider = Provider<ForecastsRepository>(
  (ref) => ForecastsRepository(ref.watch(dioProvider)),
);

class ForecastsRepository {
  ForecastsRepository(this._dio);
  final Dio _dio;

  Future<ForecastData> getForecast(int year) => guardApi(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/forecasts',
      queryParameters: {'year': year},
    );
    return ForecastData.fromJson(res.data ?? {});
  });
}
