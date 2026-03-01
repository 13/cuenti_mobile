import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _tokenKey = 'jwt_token';
  static const String _serverUrlKey = 'server_url';
  static const String defaultServerUrl = 'https://cuenti.muh';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
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
