import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _tokenKey = 'jwt_token';
  static const String _serverUrlKey = 'server_url';
  static const String defaultServerUrl = 'https://cuenti.muh';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
  );
  late Dio dio;
  String _baseUrl = defaultServerUrl;

  ApiClient() {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Bypass certificate verification for self-signed certs
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // transitional: legacy client mirrors server_url per-request; removed in Task 10
        // The new core ApiClient (Riverpod auth stack) may change server_url
        // at any time (server-setup flow); re-read it here so this legacy
        // client never serves requests against a stale baseUrl.
        final url = await _storage.read(key: _serverUrlKey);
        if (url != null && url.isNotEmpty) {
          final normalized =
              url.endsWith('/') ? url.substring(0, url.length - 1) : url;
          options.baseUrl = '$normalized/api';
        }
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  Future<void> init() async {
    final url = await _storage.read(key: _serverUrlKey);
    if (url != null && url.isNotEmpty) {
      _baseUrl = url;
    }
    dio.options.baseUrl = '$_baseUrl/api';
  }

  String get baseUrl => _baseUrl;

  Future<void> setServerUrl(String url) async {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    await _storage.write(key: _serverUrlKey, value: _baseUrl);
    dio.options.baseUrl = '$_baseUrl/api';
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
