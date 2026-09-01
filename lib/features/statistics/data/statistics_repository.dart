import 'package:cuentimobile/core/api/api_guard.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/features/statistics/domain/statistics_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>(
  (ref) => StatisticsRepository(ref.watch(dioProvider)),
);

class StatisticsRepository {
  StatisticsRepository(this._dio);
  final Dio _dio;

  Future<StatisticsData> load({String? start, String? end, int? accountId}) =>
      guardApi(() async {
        final params = <String, dynamic>{
          'start': ?start,
          'end': ?end,
          'accountId': ?accountId,
        };
        final res = await _dio.get<Map<String, dynamic>>(
          '/statistics',
          queryParameters: params,
        );
        return StatisticsData.fromJson(res.data!);
      });
}
