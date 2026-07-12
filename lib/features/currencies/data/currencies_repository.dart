import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/currency.dart';

final currenciesRepositoryProvider = Provider<CurrenciesRepository>(
    (ref) => CurrenciesRepository(ref.watch(dioProvider)));

class CurrenciesRepository {
  CurrenciesRepository(this._dio);
  final Dio _dio;

  Future<List<Currency>> getAll() => _guard(() async {
        final res = await _dio.get<List<dynamic>>('/currencies');
        return (res.data ?? [])
            .map((e) => Currency.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Currency> save(Currency currency) => _guard(() async {
        // Explicit writable fields only (matches old Currency.toJson body);
        // id must not be sent.
        final json = {
          'code': currency.code,
          'name': currency.name,
          'symbol': currency.symbol,
          'decimalChar': currency.decimalChar,
          'fracDigits': currency.fracDigits,
          'groupingChar': currency.groupingChar,
        };
        final res = currency.id != null
            ? await _dio.put<Map<String, dynamic>>(
                '/currencies/${currency.id}', data: json)
            : await _dio.post<Map<String, dynamic>>('/currencies', data: json);
        return Currency.fromJson(res.data!);
      });

  Future<void> delete(int id) =>
      _guard(() => _dio.delete<void>('/currencies/$id'));
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
