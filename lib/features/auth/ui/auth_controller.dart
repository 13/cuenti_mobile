import 'dart:async';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
    unawaited(Future.microtask(init));
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
      } on Exception catch (_) {
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

  Future<String?> login(L l, String username, String password) async {
    final UserProfile user;
    try {
      user = await _repo.login(username, password);
    } on Exception catch (e) {
      return _errorMessage(l, e);
    }
    await _persistSuccessfulLogin(user, username, password);
    return null;
  }

  Future<String?> register({
    required L l,
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final UserProfile user;
    try {
      user = await _repo.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
    } on Exception catch (e) {
      return _errorMessage(l, e);
    }
    await _persistSuccessfulLogin(user, username, password);
    return null;
  }

  Future<void> logout() async {
    state = state.copyWith(user: null);
    await _repo.logout();
    await forgetSavedCredentials();
  }

  /// Signs in with the credentials persisted by the last successful
  /// [login]/[register]. Returns null on success, else an error message.
  /// A 401 means the password changed server-side: the saved password is
  /// dropped (username kept) so the UI falls back to manual entry.
  Future<String?> loginWithSavedCredentials(L l) async {
    final username = state.savedUsername;
    final password = await _storage.read(_savedPasswordKey);
    if (username == null || password == null || password.isEmpty) {
      state = state.copyWith(hasSavedPassword: false);
      return l.errorNoSavedCredentials;
    }
    try {
      final user = await _repo.login(username, password);
      state = state.copyWith(user: user);
      return null;
    } on UnauthorizedException catch (e) {
      if (e.message != invalidCredentialsMessage) return _errorMessage(l, e);
      await _storage.delete(_savedPasswordKey);
      state = state.copyWith(hasSavedPassword: false);
      return l.errorSavedPasswordInvalid;
    } on Exception catch (e) {
      return _errorMessage(l, e);
    }
  }

  Future<void> forgetSavedCredentials() async {
    await _storage.delete(_savedUsernameKey);
    await _storage.delete(_savedPasswordKey);
    state = state.copyWith(savedUsername: null, hasSavedPassword: false);
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _repo.getProfile();
      state = state.copyWith(user: user);
    } on Exception catch (_) {}
  }

  /// Sets [user] on success and, best-effort, persists the credentials for
  /// [loginWithSavedCredentials]. A storage failure must not surface as a
  /// failed sign-in, so it is swallowed here and `savedUsername`/
  /// `hasSavedPassword` are simply left unchanged.
  ///
  /// What is stored is the password itself, not a token. That is a real
  /// cost -- it is a reusable credential the user has probably reused
  /// elsewhere, and unlike a token it cannot be revoked server-side -- and
  /// it is deliberate only because the API offers no refresh token to hold
  /// instead: `/auth/login` returns a JWT and nothing to renew it with, so
  /// biometric sign-in has to replay the credentials. It sits in
  /// [SecureStorage], which is Keystore-backed on Android. If the backend
  /// ever grows a refresh endpoint, this is the call site to change.
  Future<void> _persistSuccessfulLogin(
    UserProfile user,
    String username,
    String password,
  ) async {
    var persisted = false;
    try {
      await _storage.write(_savedUsernameKey, username);
      await _storage.write(_savedPasswordKey, password);
      persisted = true;
    } on Exception catch (_) {}
    state = persisted
        ? state.copyWith(
            user: user,
            savedUsername: username,
            hasSavedPassword: true,
          )
        : state.copyWith(user: user);
  }

  Future<void> setBiometricEnabled({required bool enabled}) async {
    state = state.copyWith(biometricEnabled: enabled);
    await _storage.write(_biometricKey, enabled.toString());
  }

  String get serverUrl => _repo.serverUrl;

  Future<void> setServerUrl(String url) => _repo.setServerUrl(url);

  /// What to put in front of the user.
  ///
  /// Every repository failure arrives as an [ApiException], which knows how
  /// to say itself in the user's language. Sign-in used to report
  /// `e.toString()` instead -- the English text [ApiException] keeps for
  /// logs -- so the first screen of the app was the one screen that never
  /// spoke German or Italian.
  String _errorMessage(L l, Exception e) => e is ApiException
      ? e.localizedMessage(l)
      : e.toString().replaceAll('Exception: ', '');
}
