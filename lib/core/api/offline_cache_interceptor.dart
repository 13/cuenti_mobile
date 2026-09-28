import 'dart:async';

import 'package:cuentimobile/core/api/reachability.dart';
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
  OfflineCacheInterceptor(this._cache, {Reachability? reachability})
    : reachability = reachability ?? Reachability();

  final ResponseCache _cache;

  /// Whether the server was just found to be unreachable, so this request
  /// need not find out again the slow way.
  final Reachability reachability;

  /// The backing store, so a sign-out can drop the previous account's data.
  ResponseCache get cache => _cache;

  /// True while the most recent request had to fall back to cache, for the
  /// UI to say so. A [ValueNotifier] so a widget can listen without polling.
  final ValueNotifier<bool> stale = ValueNotifier(false);

  /// When the replayed figures were originally fetched, for the UI to say
  /// how old what it is showing is. Null while live.
  final ValueNotifier<DateTime?> staleSince = ValueNotifier(null);

  bool get servingStaleData => stale.value;

  /// What is cached for [options], or null.
  ///
  /// Offered because this interceptor replays only an exact key hit, and a
  /// filtered list is a different key from the unfiltered one it is a subset
  /// of. Reading is all that is offered: what a body *means* stays with
  /// whoever knows its shape.
  Future<CachedResponse?> peek(RequestOptions options) =>
      _cache.read(cacheKeyFor(options));

  /// Says the figures now on screen came from [storedAt], not from the
  /// server just now.
  ///
  /// For a caller that answered an offline failure itself: [stale] is set
  /// only where this interceptor does the replaying, so without this the
  /// banner would stay down over data that is not live -- which in an app
  /// about money is the one thing the banner exists to prevent. It also arms
  /// the reconnect drain, which watches [stale] for a true-to-false edge.
  void markStale(DateTime storedAt) {
    stale.value = true;
    staleSince.value = storedAt;
  }

  /// Whether [e] means the server was never reached, as opposed to
  /// answering with something we did not want.
  ///
  /// Public because a caller that resolves such a failure itself -- the
  /// transactions repository, cutting a filtered list out of a cached
  /// unfiltered one -- must apply exactly this test and no looser one. A 500
  /// is a server that answered, and so is a certificate this install has not
  /// trusted.
  static bool isOfflineFailure(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => true,
    _ => false,
  };

  /// Where a request records the cache generation it went out under.
  static const _generationKey = 'cuenti.cacheGeneration';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Noted now, not when the answer arrives: a sign-out that clears the
    // cache while this request is in flight must also stop its answer --
    // the previous account's figures -- from being written back afterwards.
    options.extra[_generationKey] = _cache.generation;
    if (reachability.admit()) {
      handler.next(options);
      return;
    }
    // The server could not be reached a moment ago. Answer now with what
    // asking again would, after a connection timeout, have ended in: the
    // cached copy for a GET that has one, the same offline failure for
    // anything else -- which is what sends a save to the outbox, and a
    // filtered list to the repository's own cache fallback.
    if (options.method.toUpperCase() == 'GET') {
      final cached = await _cache.read(cacheKeyFor(options));
      if (cached != null) {
        handler.resolve(_replay(options, cached));
        return;
      }
    }
    handler.reject(
      DioException.connectionError(
        requestOptions: options,
        reason: 'The server could not be reached a moment ago',
      ),
    );
  }

  /// [cached] dressed as the answer to [options], marked as not live.
  Response<dynamic> _replay(RequestOptions options, CachedResponse cached) {
    stale.value = true;
    staleSince.value = cached.storedAt;
    return Response<dynamic>(
      requestOptions: options,
      data: cached.body,
      statusCode: 200,
      headers: Headers.fromMap({
        staleResponseHeader: ['true'],
        staleSinceHeader: [cached.storedAt.toIso8601String()],
      }),
    );
  }

  /// Whether [e] means the connection itself could not be made -- the one
  /// failure that says the next request would fail the same way. Narrower
  /// than [isOfflineFailure]: a receive timeout is a server that took the
  /// request and was slow about it.
  static bool _unreachable(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout => true,
    _ => false,
  };

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    reachability.recordReachable();
    final options = response.requestOptions;
    if (options.method.toUpperCase() == 'GET' &&
        (response.statusCode ?? 0) >= 200 &&
        (response.statusCode ?? 0) < 300) {
      // Not awaited: encrypting and writing the copy is no reason to keep
      // the screen waiting for figures it already has. A read of this key
      // waits for the write, so the copy is never missed.
      unawaited(
        _cache
            .store(
              cacheKeyFor(options),
              response.data,
              generation: options.extra[_generationKey] as int?,
            )
            // A copy that could not be kept is only a future cache miss.
            .then<void>((_) {}, onError: (Object _) {}),
      );
      stale.value = false;
      staleSince.value = null;
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_unreachable(err)) {
      reachability.recordOffline();
    } else if (err.response != null ||
        err.type == DioExceptionType.receiveTimeout) {
      // An error status, or a slow answer: either way, somebody is there.
      reachability.recordReachable();
    } else {
      // Cancelled, a certificate refused, something unforeseen: no word on
      // the server either way.
      reachability.release();
    }
    if (err.requestOptions.method.toUpperCase() != 'GET' ||
        !isOfflineFailure(err)) {
      handler.next(err);
      return;
    }
    final cached = await _cache.read(cacheKeyFor(err.requestOptions));
    if (cached == null) {
      handler.next(err);
      return;
    }
    handler.resolve(_replay(err.requestOptions, cached));
  }
}
