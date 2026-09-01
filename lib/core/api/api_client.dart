import 'dart:io';

import 'package:cuentimobile/core/api/certificate_pins.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ApiClient {
  ApiClient(this._storage, {Dio? dioOverride, CertificatePins? pins})
    : pins = pins ?? CertificatePins(_storage) {
    if (dioOverride != null) {
      dio = dioOverride;
    } else {
      dio = Dio(
        BaseOptions(
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
  late Dio dio;
  String _baseUrl = defaultServerUrl;

  Future<void> init() async {
    // Before any request: the bad-certificate callback is synchronous and
    // can only consult pins already in memory.
    await pins.load();
    final url = await _storage.read(_serverUrlKey);
    if (url != null && url.isNotEmpty) {
      _baseUrl = url;
    }
    dio.options.baseUrl = '$_baseUrl/api';
  }

  String get baseUrl => _baseUrl;

  Future<void> setServerUrl(String url) async {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    await _storage.write(_serverUrlKey, _baseUrl);
    dio.options.baseUrl = '$_baseUrl/api';
  }

  Future<void> saveToken(String token) async {
    await _storage.write(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _storage.read(_tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(_tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
