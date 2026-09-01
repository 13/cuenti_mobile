import 'package:cuentimobile/core/api/response_cache.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Marks a response that came from [ResponseCache] rather than the server.
const staleResponseHeader = 'x-cuenti-stale';

/// When that response was originally fetched, ISO-8601.
const staleSinceHeader = 'x-cuenti-stale-since';

/// Whether [response] was served from cache because the server could not be
/// reached.
bool isStale(Response<Object?> response) =>
    response.headers.value(staleResponseHeader) == 'true';

/// When a cached response was originally fetched, or null if it is live.
DateTime? staleSince(Response<Object?> response) {
  final raw = response.headers.value(staleSinceHeader);
  return raw == null ? null : DateTime.tryParse(raw);
}

/// Keeps the last successful GET for each endpoint and replays it when the
/// server cannot be reached.
///
/// Only GETs, and only genuine connection failures: a 500 means the server
/// did answer, and replacing that with yesterday's figures would hide a real
/// problem behind plausible-looking data. An endpoint never fetched still
/// fails, because a wrong number is worse than a visible error in an app
/// about money.
class OfflineCacheInterceptor extends Interceptor {
  OfflineCacheInterceptor(this._cache);

  final ResponseCache _cache;

  /// The backing store, so a sign-out can drop the previous account's data.
  ResponseCache get cache => _cache;

  /// True while the most recent request had to fall back to cache, for the
  /// UI to say so. A [ValueNotifier] so a widget can listen without polling.
  final ValueNotifier<bool> stale = ValueNotifier(false);

  bool get servingStaleData => stale.value;

  static bool _isOffline(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => true,
    _ => false,
  };

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        (response.statusCode ?? 0) >= 200 &&
        (response.statusCode ?? 0) < 300) {
      await _cache.store(cacheKeyFor(response.requestOptions), response.data);
      stale.value = false;
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.requestOptions.method.toUpperCase() != 'GET' || !_isOffline(err)) {
      handler.next(err);
      return;
    }
    final cached = await _cache.read(cacheKeyFor(err.requestOptions));
    if (cached == null) {
      handler.next(err);
      return;
    }
    stale.value = true;
    handler.resolve(
      Response<dynamic>(
        requestOptions: err.requestOptions,
        data: cached.body,
        statusCode: 200,
        headers: Headers.fromMap({
          staleResponseHeader: ['true'],
          staleSinceHeader: [cached.storedAt.toIso8601String()],
        }),
      ),
    );
  }
}
