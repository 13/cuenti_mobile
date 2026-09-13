import 'dart:async';
import 'dart:convert';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/core/widgets/entity_list_filter.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.freezed.dart';
part 'auth_controller.g.dart';

const _biometricKey = 'biometric_enabled';
const _savedUsernameKey = 'saved_username';
const _savedPasswordKey = 'saved_password';

/// The profile the server last handed us, so a launch with no network can
/// still say who is signed in.
const _savedProfileKey = 'saved_profile';

/// How long that snapshot is allowed to stand in for the server.
///
/// Past this it is not "who signed in here", it is a guess about a device
/// that has been out of touch for a fortnight. The same bound
/// `ResponseCache.defaultMaxAge` puts on stale figures, and for the same
/// reason.
const offlineProfileMaxAge = Duration(days: 14);

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    UserProfile? user,
    @Default(true) bool registrationEnabled,
    @Default(false) bool biometricEnabled,
    @Default(false) bool initialized,
    String? savedUsername,
    @Default(false) bool hasSavedPassword,

    /// The signed-in user came from restoring a session -- a stored token,
    /// or offline the profile snapshot -- rather than from a password or a
    /// biometric prompt the user just passed. The app lock keys off this.
    @Default(false) bool restoredSession,
  }) = _AuthState;

  const AuthState._();

  bool get isLoggedIn => user != null;
}

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    // A throw here used to vanish into an unhandled async error. `init()`
    // sets `initialized`, which gates the app-start outbox drain, so a
    // silent failure here is a startup that quietly never syncs.
    unawaited(
      Future.microtask(init).catchError((Object e, StackTrace s) {
        debugPrint('AuthController: init failed: $e\n$s');
      }),
    );
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

  Future<void> init() async {
    final pending = _initFuture;
    if (pending != null) return pending;
    final run = _init();
    _initFuture = run;
    try {
      await run;
    } on Object {
      // A rejected future must not be the answer for the life of the
      // process. The launch that fails here is typically the offline one,
      // and `LoginScreen` calls init() again every time it is built -- that
      // retry has to be able to reach the network half once there is a
      // network to reach.
      //
      // Cleared only after the failed run has settled, so a retry is
      // sequential with it. The guard this replaces was protecting against
      // two *concurrent* runs, and it still does.
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> _init() async {
    final client = ref.read(apiClientProvider)
      ..onSessionExpired = _handleSessionExpired;
    await client.init();

    // Published before anything touches the network, and separately from
    // the rest. All of this used to land in one copyWith at the very end,
    // so a launch whose network half failed left the sign-in screen with no
    // saved username, no biometric offer, and `initialized` false -- the
    // flag that gates main.dart's startup outbox drain and AppLockObserver's
    // cold-start decision. Offline, that was the whole difference between
    // signing in once and signing in twice.
    final savedPassword = await _storage.read(_savedPasswordKey);
    state = state.copyWith(
      biometricEnabled: await _storage.read(_biometricKey) == 'true',
      savedUsername: await _storage.read(_savedUsernameKey),
      hasSavedPassword: savedPassword != null && savedPassword.isNotEmpty,
    );

    // The profile GET below races `ApiClient`'s unawaited cache attach and
    // can lose, arriving with no interceptor to replay it. That used to
    // decide the launch: unreplayable meant "offline", which meant logout,
    // which deleted the token and cleared the whole cache. Nothing waits on
    // that race now -- the NetworkException branch below restores from
    // [_readSavedProfile], which reads SecureStorage rather than the cache
    // and so cannot lose it.
    UserProfile? user;
    var registrationEnabled = state.registrationEnabled;
    try {
      if (await _repo.hasToken()) {
        try {
          user = await _repo.getProfile();
          await _persistProfile(user);
        } on UnauthorizedException catch (_) {
          // The server answered, and refused this token. The only failure
          // that is evidence the credential is dead, and so the only one
          // entitled to call logout() -- which deletes the token *and*
          // clears the whole offline cache.
          await _repo.logout();
        } on NetworkException catch (e) {
          // Never reached the server, so the server never refused anything.
          // Keep the token, keep the cache, and carry on with what the last
          // successful sign-in left on the device. A certificate refusal is
          // not this case: that server did answer, and the sign-in screen is
          // about to offer to trust it.
          if (!e.isCertificateRefusal) user = await _readSavedProfile();
        } on Exception catch (e) {
          // A 500, a 4xx that is not 401/403, a body that would not parse.
          // The server answered, but not with a profile -- that is the
          // server's problem, not a revoked credential, and throwing the
          // token away would punish the user for it and wipe the cache on
          // the way out. The token is kept and the user is left signed out:
          // they get a real error and can retry. If the token really is
          // dead, the next request takes a 401 and `_handleSessionExpired`
          // does the job properly.
          debugPrint('AuthController: profile fetch failed, token kept: $e');
        }
      }
      registrationEnabled = await _repo.fetchRegistrationEnabled();
    } finally {
      state = state.copyWith(
        // Never removes a user this run did not put there: `_init` can be
        // retried now, and the only things entitled to sign someone out are
        // [logout] and [_handleSessionExpired].
        user: user ?? state.user,
        // Only a user this run restored counts as restored. Someone who
        // signed in while it was running keeps what their sign-in set.
        restoredSession: user != null || state.restoredSession,
        registrationEnabled: registrationEnabled,
        initialized: true,
      );
    }
  }

  /// Keeps a copy of the profile the server last handed us, so a launch with
  /// no network can say who is signed in.
  ///
  /// `savedAt` is written only here, and only from a profile the *server*
  /// answered with. Refreshing it from a snapshot restore would make the
  /// snapshot immortal, and [offlineProfileMaxAge] exists precisely so a
  /// phone left in a drawer does not come back "signed in" over an empty
  /// cache.
  ///
  /// Best effort, like [_persistSuccessfulLogin]: a storage failure must not
  /// turn a successful fetch into a failed one.
  Future<void> _persistProfile(UserProfile user) async {
    try {
      await _storage.write(
        _savedProfileKey,
        jsonEncode({
          'savedAt': DateTime.now().toIso8601String(),
          'profile': user.toJson(),
        }),
      );
    } on Exception catch (_) {}
  }

  /// The stored snapshot, or null if there is none, it will not parse, or it
  /// is older than [offlineProfileMaxAge].
  Future<UserProfile?> _readSavedProfile() async {
    try {
      final raw = await _storage.read(_savedProfileKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(decoded['savedAt'] as String? ?? '');
      if (savedAt == null ||
          DateTime.now().difference(savedAt) > offlineProfileMaxAge) {
        return null;
      }
      return UserProfile.fromJson(decoded['profile'] as Map<String, dynamic>);
      // A snapshot we cannot read is a snapshot we do not have -- never a
      // reason to fail a sign-in that was already failing. `fromJson` throws
      // TypeError, not Exception, on a shape that has moved on.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  /// Signs in against what the last successful sign-in left on this device,
  /// for the one case where the server cannot be reached at all.
  ///
  /// Reached only from a [NetworkException] that is not a certificate
  /// refusal. A password the server actively *rejected* must never fall
  /// through to a local check, or this becomes a way to keep using a
  /// credential the server has revoked.
  ///
  /// The comparison is a plain `==`. It is not constant-time and does not
  /// need to be: both operands are already inside the same trust boundary,
  /// and anyone who can time this call is running in a process where the
  /// plaintext can simply be read out of [SecureStorage]. A timing channel
  /// that leaks a secret you can also just read is not one.
  ///
  /// A live token is required. Without one the app would be signed in to
  /// nothing: cached GETs still replay (the cache interceptor sits ahead of
  /// the auth one, so a replay needs no token), so it would *look* like it
  /// worked -- until the network returned, the first live request took a
  /// 401, `_handleSessionExpired` fired, and the user was dropped back here
  /// with the cache wiped. It also bounds what this can resurrect:
  /// `clearToken` is what a real sign-out and a real session expiry both
  /// call, so neither can be undone here.
  Future<bool> _signInOffline(String username, String password) async {
    if (!await _repo.hasToken()) return false;
    final savedUsername = await _storage.read(_savedUsernameKey);
    final savedPassword = await _storage.read(_savedPasswordKey);
    if (savedUsername == null ||
        savedPassword == null ||
        savedPassword.isEmpty) {
      return false;
    }
    if (username != savedUsername || password != savedPassword) return false;
    final profile = await _readSavedProfile();
    if (profile == null) return false;
    state = state.copyWith(
      user: profile,
      savedUsername: savedUsername,
      hasSavedPassword: true,
      restoredSession: false,
    );
    return true;
  }

  Future<String?> login(L l, String username, String password) async {
    final UserProfile user;
    try {
      user = await _repo.login(username, password);
    } on NetworkException catch (e) {
      // The server could not be reached, so nothing rejected these
      // credentials -- see [_signInOffline] for why that is the only failure
      // allowed to fall through to a local check.
      if (!e.isCertificateRefusal && await _signInOffline(username, password)) {
        return null;
      }
      return _errorMessage(l, e);
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

  /// The token stopped being accepted mid-session. Drop it and the user, so
  /// the router's redirect takes them to the login screen rather than
  /// leaving every screen erroring around a credential that cannot work.
  ///
  /// Unlike [logout] this keeps the saved username and password: the
  /// session expired, the user did not ask to be forgotten, and making them
  /// retype everything would be a worse answer than the one they get by
  /// signing in again.
  ///
  /// It keeps the outbox too, deliberately. The sign-out flow clears it
  /// (having asked first) because a different account may sign in next; an
  /// expired session is the same person and the same account, and the
  /// queued writes are still theirs to send once they are back in.
  ///
  /// The profile snapshot is kept for the same reason, and cannot be used to
  /// undo this: `_repo.logout` deletes the token, and [_signInOffline]
  /// requires one. An expired session stays expired.
  Future<void> _handleSessionExpired() async {
    // Several requests can fail at once, and a signed-out state must not be
    // re-cleared while the login screen is already up.
    if (state.user == null) return;
    state = state.copyWith(user: null, restoredSession: false);
    await _repo.logout();
  }

  Future<void> logout() async {
    state = state.copyWith(user: null, restoredSession: false);
    // The list screens' searches outlive a screen on purpose, so they have
    // to be dropped here: the data providers dispose themselves, but this
    // one is kept alive and would otherwise greet the next person with the
    // last one's filters.
    ref.invalidate(entityListFilterProvider);
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
      state = state.copyWith(user: user, restoredSession: false);
      return null;
    } on UnauthorizedException catch (e) {
      if (e.message != invalidCredentialsMessage) return _errorMessage(l, e);
      await _storage.delete(_savedPasswordKey);
      state = state.copyWith(hasSavedPassword: false);
      return l.errorSavedPasswordInvalid;
    } on NetworkException catch (e) {
      // Ordered after [UnauthorizedException] deliberately -- Dart matches
      // catch clauses in order, and a refused password must reach the clause
      // above rather than this one. This is what makes the fingerprint work
      // on a train: biometric sign-in replays these same credentials.
      if (!e.isCertificateRefusal && await _signInOffline(username, password)) {
        return null;
      }
      return _errorMessage(l, e);
    } on Exception catch (e) {
      return _errorMessage(l, e);
    }
  }

  Future<void> forgetSavedCredentials() async {
    await _storage.delete(_savedUsernameKey);
    await _storage.delete(_savedPasswordKey);
    // "Not you?" and sign-out both land here, and the snapshot names a
    // person and their email. It goes with the credentials it belongs to.
    await _storage.delete(_savedProfileKey);
    state = state.copyWith(savedUsername: null, hasSavedPassword: false);
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _repo.getProfile();
      await _persistProfile(user);
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
    // Alongside them, so a later launch with no network has a profile to
    // restore and [_signInOffline] has something to sign in as. Separate
    // from the block above because it swallows its own failures.
    await _persistProfile(user);
    state = persisted
        ? state.copyWith(
            user: user,
            savedUsername: username,
            hasSavedPassword: true,
            restoredSession: false,
          )
        : state.copyWith(user: user, restoredSession: false);
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
