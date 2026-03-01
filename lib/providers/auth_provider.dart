import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/api_services.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _client;
  late final AuthApi _authApi;

  UserProfile? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._client) {
    _authApi = AuthApi(_client);
  }

  UserProfile? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  Future<void> init() async {
    await _client.init();
    if (await _client.hasToken()) {
      try {
        final userApi = UserApi(_client);
        final data = await userApi.getProfile();
        _user = UserProfile.fromJson(data);
        notifyListeners();
      } catch (e) {
        await _client.clearToken();
      }
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authApi.login(username, password);
      await _client.saveToken(data['token']);
      _user = UserProfile(
        username: data['username'] ?? '',
        email: data['email'] ?? '',
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        defaultCurrency: data['defaultCurrency'] ?? 'EUR',
        darkMode: data['darkMode'] ?? true,
        locale: data['locale'] ?? 'de-DE',
        apiEnabled: data['apiEnabled'] ?? false,
        roles: (data['roles'] as List?)?.map((e) => e.toString()).toSet() ?? {},
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authApi.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      await _client.saveToken(data['token']);
      _user = UserProfile(
        username: data['username'] ?? '',
        email: data['email'] ?? '',
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        defaultCurrency: data['defaultCurrency'] ?? 'EUR',
        darkMode: data['darkMode'] ?? true,
        locale: data['locale'] ?? 'de-DE',
        apiEnabled: data['apiEnabled'] ?? false,
        roles: (data['roles'] as List?)?.map((e) => e.toString()).toSet() ?? {},
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _client.clearToken();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final userApi = UserApi(_client);
      final data = await userApi.getProfile();
      _user = UserProfile.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }

  String get serverUrl => _client.baseUrl;

  Future<void> setServerUrl(String url) async {
    await _client.setServerUrl(url);
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      if (e.type == DioExceptionType.connectionError ||
          e.message?.contains('ECONNREFUSED') == true) {
        return 'Cannot connect to server';
      }
      if (e.type == DioExceptionType.unknown &&
          e.error.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        return 'SSL certificate error. Install the server certificate on your device.';
      }
      if (statusCode == 401) return 'Invalid username or password';
      if (statusCode == 403) {
        final body = e.response?.data;
        return body is String ? body : 'API access is not enabled';
      }
      // Show actual error for debugging
      final body = e.response?.data;
      if (body is String && body.isNotEmpty) return body;
      return e.message ?? 'Network error';
    }
    if (e is Exception) {
      return e.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred';
  }
}
