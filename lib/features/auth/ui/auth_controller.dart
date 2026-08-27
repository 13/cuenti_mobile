import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/dio_provider.dart';
import '../../../core/storage/secure_storage.dart';
import '../../user/domain/user_profile.dart';
import '../data/auth_repository.dart';

part 'auth_controller.freezed.dart';
part 'auth_controller.g.dart';

const _biometricKey = 'biometric_enabled';
const _savedUsernameKey = 'saved_username';
const _savedPasswordKey = 'saved_password';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    UserProfile? user,
    @Default(true) bool registrationEnabled,
    @Default(false) bool biometricEnabled,
    @Default(false) bool initialized,
    String? savedUsername,
    @Default(false) bool hasSavedPassword,
  }) = _AuthState;

  const AuthState._();

  bool get isLoggedIn => user != null;
}

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    Future.microtask(init);
    return const AuthState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  SecureStorage get _storage => ref.read(secureStorageProvider);

  // Single-flight guard: `build()`'s microtask and `LoginScreen`'s
  // `didChangeDependencies` both call `init()`. Without memoizing the
  // in-flight future, two concurrent runs can race — a transient failure in
  // one clears the token and stomps the other's restored user. Memoizing
  // means both call sites share exactly one run.
  Future<void>? _initFuture;

  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    await ref.read(apiClientProvider).init();

    final bioStr = await _storage.read(_biometricKey);
    final biometricEnabled = bioStr == 'true';

    final savedUsername = await _storage.read(_savedUsernameKey);
    final savedPassword = await _storage.read(_savedPasswordKey);

    UserProfile? user;
    if (await _repo.hasToken()) {
      try {
        user = await _repo.getProfile();
      } catch (_) {
        await _repo.logout();
      }
    }

    final registrationEnabled = await _repo.fetchRegistrationEnabled();

    state = state.copyWith(
      user: user,
      biometricEnabled: biometricEnabled,
      registrationEnabled: registrationEnabled,
      initialized: true,
      savedUsername: savedUsername,
      hasSavedPassword: savedPassword != null && savedPassword.isNotEmpty,
    );
  }

  Future<String?> login(String username, String password) async {
    try {
      final user = await _repo.login(username, password);
      state = state.copyWith(user: user);
      await _saveCredentials(username, password);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final user = await _repo.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      state = state.copyWith(user: user);
      await _saveCredentials(username, password);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    await _storage.delete(_savedUsernameKey);
    await _storage.delete(_savedPasswordKey);
    state = state.copyWith(
      user: null,
      savedUsername: null,
      hasSavedPassword: false,
    );
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _repo.getProfile();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<void> _saveCredentials(String username, String password) async {
    await _storage.write(_savedUsernameKey, username);
    await _storage.write(_savedPasswordKey, password);
    state = state.copyWith(savedUsername: username, hasSavedPassword: true);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    state = state.copyWith(biometricEnabled: enabled);
    await _storage.write(_biometricKey, enabled.toString());
  }

  String get serverUrl => _repo.serverUrl;

  Future<void> setServerUrl(String url) => _repo.setServerUrl(url);

  String _extractError(Object e) {
    return e.toString().replaceAll('Exception: ', '');
  }
}
