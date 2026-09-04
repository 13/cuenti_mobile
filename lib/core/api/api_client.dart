import 'dart:async';
import 'dart:io';

import 'package:cuentimobile/core/api/certificate_pins.dart';
import 'package:cuentimobile/core/api/offline_cache_interceptor.dart';
import 'package:cuentimobile/core/api/response_cache.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ApiClient {
  ApiClient(
    this._storage, {
    Dio? dioOverride,
    CertificatePins? pins,
    OfflineCacheInterceptor? offlineCache,
  }) : pins = pins ?? CertificatePins(_storage),
       offlineCache = offlineCache {
    if (dioOverride != null) {
      dio = dioOverride;
    } else {
      dio = Dio(
        BaseOptions(
          // Set here and not only in [init]: RequestOptions captures the
          // base URL when a request is composed, so anything that fires
          // before init() has finished its platform-channel awaits would
          // otherwise go out against an empty base -- which fails as
          // "unknown", not as "offline", and reads as the server refusing
          // rather than never having been asked. init() refines this to
          // whatever server the user has configured.
          //
          // A non-empty default so a request composed before init() cannot
          // go nowhere. Nothing composes one today -- main.dart gates the
          // startup drain on auth being initialised -- and if that gate is
          // ever loosened, this default is what such a request would reach.
          baseUrl: '$defaultServerUrl/api',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      // Self-hosted Cuenti servers usually present a certificate no public
      // CA has signed. Rather than waving every certificate through -- which
      // would wave an interceptor's through too, on a connection carrying a
      // bearer token and the user's whole financial history -- accept only
      // the one fingerprint the user has explicitly trusted for that host.
      // Certificates that chain to a real CA never reach this callback.
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient()
            ..badCertificateCallback = (cert, host, port) =>
                this.pins.evaluate(host, certificateFingerprint(cert.der));
          return client;
        },
      );
    }

    // Ahead of the auth interceptor so a replayed response does not need a
    // token attached to it.
    final cache = offlineCache;
    if (cache != null) dio.interceptors.add(cache);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // A 401 anywhere but the sign-in endpoint means the token this
          // client has been sending is no longer accepted. Without this the
          // app stayed "signed in" around a dead token: every screen showed
          // "Not authenticated", none recovered, and the only way out was
          // finding Logout in the drawer. On /auth/login a 401 means the
          // password was wrong, which is not an expired session.
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/login')) {
            onSessionExpired?.call();
          }
          handler.next(error);
        },
      ),
    );
  }
  static const String _tokenKey = 'jwt_token';
  static const String _serverUrlKey = 'server_url';
  static const String defaultServerUrl = 'https://cuenti.muh';

  final SecureStorage _storage;

  /// Self-signed certificates this install has been told to trust.
  final CertificatePins pins;

  /// Replays the last successful GET per endpoint when the server cannot be
  /// reached. Null until [init] has opened the on-disk cache.
  OfflineCacheInterceptor? offlineCache;

  /// Called when the server rejects this client's token. Set by the auth
  /// layer, which owns what "signed out" means; this class only knows that
  /// the credential it has been presenting has stopped working.
  void Function()? onSessionExpired;
  late Dio dio;
  String _baseUrl = defaultServerUrl;

  Future<void> init() async {
    // Before any request: the bad-certificate callback is synchronous and
    // can only consult pins already in memory.
    await pins.load();
    // Deliberately not awaited: opening the cache needs a platform channel,
    // and a channel that never answers -- an unusual host, a test binding --
    // would otherwise hang startup behind a convenience. Requests made
    // before it attaches simply are not cached.
    if (offlineCache == null) unawaited(_attachOfflineCache());
    final url = await _storage.read(_serverUrlKey);
    if (url != null && url.isNotEmpty) {
      _baseUrl = url;
    }
    dio.options.baseUrl = '$_baseUrl/api';
  }

  Future<void> _attachOfflineCache() async {
    try {
      final interceptor = OfflineCacheInterceptor(await ResponseCache.open());
      offlineCache = interceptor;
      dio.interceptors.insert(0, interceptor);
    } on Exception catch (_) {
      // No writable support directory, or no platform channels at all. The
      // app works without a cache; it just cannot show the last known
      // figures while the server is unreachable.
    }
  }

  String get baseUrl => _baseUrl;

  Future<void> setServerUrl(String url) async {
    final normalized = url.endsWith('/')
        ? url.substring(0, url.length - 1)
        : url;
    final movedServer = normalized != _baseUrl;
    _baseUrl = normalized;
    await _storage.write(_serverUrlKey, _baseUrl);
    dio.options.baseUrl = '$_baseUrl/api';
    // Cached responses are keyed by endpoint, not by server, so figures
    // fetched from the old one would replay as this one's the moment it
    // could not be reached -- one instance's balances shown under
    // another's address, labelled only as offline. Dropping them on a move
    // is the same reasoning as dropping them on sign-out.
    if (movedServer) await offlineCache?.cache.clear();
  }

  Future<void> saveToken(String token) async {
    await _storage.write(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _storage.read(_tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(_tokenKey);
    // Signing out must not leave the previous account's figures on disk for
    // the next one to be shown offline.
    await offlineCache?.cache.clear();
    // The outbox is cleared by the sign-out flow, which asks first: unlike
    // the cache, it holds work the server has never seen.
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
