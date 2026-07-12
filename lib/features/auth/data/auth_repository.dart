import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../../user/domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

/// Talks to the `/auth/*` endpoints and persists the JWT via [ApiClient].
class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<UserProfile> login(String username, String password) async {
    try {
      final response = await _client.dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      return _saveTokenAndBuildProfile(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final mapped = ApiException.fromDio(e);
      // Parity with the old AuthProvider: a 401 on the login endpoint means
      // bad credentials, not an expired session. Surface the specific message
      // here (NOT in ApiException.fromDio, where a generic 401 elsewhere
      // means the session expired). 403 keeps its own fromDio message.
      if (mapped is UnauthorizedException && e.response?.statusCode == 401) {
        throw const UnauthorizedException('Invalid username or password');
      }
      throw mapped;
    }
  }

  Future<UserProfile> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _client.dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      });
      return _saveTokenAndBuildProfile(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserProfile> getProfile() async {
    try {
      final response = await _client.dio.get('/user/profile');
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<bool> fetchRegistrationEnabled() async {
    try {
      final response = await _client.dio.get('/auth/settings');
      final data = response.data as Map<String, dynamic>?;
      return (data?['registrationEnabled'] as bool?) ?? true;
    } on DioException {
      return true;
    }
  }

  Future<void> logout() async {
    await _client.clearToken();
  }

  Future<bool> hasToken() => _client.hasToken();

  String get serverUrl => _client.baseUrl;

  Future<void> setServerUrl(String url) => _client.setServerUrl(url);

  Future<UserProfile> _saveTokenAndBuildProfile(
      Map<String, dynamic> data) async {
    await _client.saveToken(data['token'] as String);
    return UserProfile(
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      defaultCurrency: data['defaultCurrency'] as String? ?? 'EUR',
      darkMode: data['darkMode'] as bool? ?? true,
      locale: data['locale'] as String? ?? 'de-DE',
      apiEnabled: data['apiEnabled'] as bool? ?? false,
      roles: (data['roles'] as List?)?.map((e) => e.toString()).toSet() ?? {},
    );
  }
}
