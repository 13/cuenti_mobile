import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/user_profile.dart';

final userRepositoryProvider = Provider<UserRepository>(
    (ref) => UserRepository(ref.watch(dioProvider)));

/// Shape of `GET`/`PUT /user/admin/settings`.
typedef AdminSettings = ({bool registrationEnabled, bool apiEnabled});

class UserRepository {
  UserRepository(this._dio);
  final Dio _dio;

  Future<UserProfile> getProfile() => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/user/profile');
        return UserProfile.fromJson(res.data!);
      });

  Future<UserProfile> updateProfile({
    required String email,
    required String firstName,
    required String lastName,
  }) =>
      _guard(() async {
        final res = await _dio.put<Map<String, dynamic>>('/user/profile', data: {
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
        });
        return UserProfile.fromJson(res.data!);
      });

  Future<void> updatePassword(String oldPassword, String newPassword) =>
      _guard(() => _dio.put<void>('/user/password', data: {
            'oldPassword': oldPassword,
            'newPassword': newPassword,
          }));

  /// The ONE sanctioned `Map`-typed request boundary in the app. User
  /// preferences (`darkMode`/`defaultCurrency`/`locale`/`apiEnabled`) are a
  /// sparse patch by design — callers send only the keys they're changing,
  /// and the server merges them into the stored profile. A typed request
  /// model would force every caller to know the full set of preference
  /// fields even when patching a single one, so the raw map is passed
  /// straight through to `PUT /user/preferences`. Every other repository in
  /// this app uses typed request bodies; do not add another map-typed
  /// boundary elsewhere — this is the exception, not the pattern.
  Future<UserProfile> updatePreferences(Map<String, Object?> prefs) =>
      _guard(() async {
        final res = await _dio.put<Map<String, dynamic>>('/user/preferences',
            data: prefs);
        return UserProfile.fromJson(res.data!);
      });

  // Admin
  Future<List<UserProfile>> getAllUsers() => _guard(() async {
        final res = await _dio.get<List<dynamic>>('/user/admin/users');
        return (res.data ?? [])
            .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<void> setUserEnabled(int id, bool enabled) => _guard(() => _dio
      .put<void>('/user/admin/users/$id/enabled', data: {'enabled': enabled}));

  Future<void> deleteUser(int id) =>
      _guard(() => _dio.delete<void>('/user/admin/users/$id'));

  Future<AdminSettings> getAdminSettings() => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/user/admin/settings');
        final data = res.data ?? const <String, dynamic>{};
        return (
          registrationEnabled: data['registrationEnabled'] as bool? ?? true,
          apiEnabled: data['apiEnabled'] as bool? ?? false,
        );
      });

  Future<void> updateAdminSettings(
          {bool? registrationEnabled, bool? apiEnabled}) =>
      _guard(() {
        final data = <String, bool>{
          if (registrationEnabled != null)
            'registrationEnabled': registrationEnabled,
          if (apiEnabled != null) 'apiEnabled': apiEnabled,
        };
        return _dio.put<void>('/user/admin/settings', data: data);
      });
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
