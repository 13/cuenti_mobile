import 'dart:convert';

import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/core/widgets/entity_list_filter.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/l10n/app_localizations_de.dart';
import 'package:cuentimobile/l10n/app_localizations_en.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockApiClient extends Mock implements ApiClient {}

class MemoryStorage extends SecureStorage {
  MemoryStorage() : super();
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

/// [MemoryStorage] variant whose `write` throws for a chosen key, to
/// exercise persistence failures after a successful sign-in.
class ThrowingWriteStorage extends MemoryStorage {
  ThrowingWriteStorage(this.failingKey);
  final String failingKey;
  @override
  Future<void> write(String key, String value) async {
    if (key == failingKey) throw Exception('storage unavailable');
    return super.write(key, value);
  }
}

void main() {
  late MockAuthRepository repo;
  late MockApiClient apiClient;
  late MemoryStorage storage;
  late ProviderContainer container;

  const user = UserProfile(
    username: 'demo',
    email: 'd@x',
    firstName: 'D',
    lastName: 'M',
  );

  setUp(() {
    repo = MockAuthRepository();
    apiClient = MockApiClient();
    storage = MemoryStorage();
    when(() => apiClient.init()).thenAnswer((_) async {});
    when(() => repo.hasToken()).thenAnswer((_) async => true);
    when(() => repo.getProfile()).thenAnswer((_) async => user);
    when(() => repo.fetchRegistrationEnabled()).thenAnswer((_) async => true);
    when(() => repo.logout()).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        apiClientProvider.overrideWithValue(apiClient),
        secureStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'concurrent init() calls are single-flight: getProfile called once',
    () async {
      final notifier = container.read(authControllerProvider.notifier);

      // Two explicit concurrent calls, plus the microtask `build()` already
      // scheduled internally, all race for the same in-flight init.
      await Future.wait([notifier.init(), notifier.init()]);

      verify(() => repo.getProfile()).called(1);
      expect(container.read(authControllerProvider).user, user);
    },
  );

  group('saved credentials', () {
    test('login success persists username and password', () async {
      when(() => repo.login('demo', 'secret')).thenAnswer((_) async => user);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.login(LEn(), 'demo', 'secret');

      expect(error, isNull);
      expect(storage.data['saved_username'], 'demo');
      expect(storage.data['saved_password'], 'secret');
      final state = container.read(authControllerProvider);
      expect(state.savedUsername, 'demo');
      expect(state.hasSavedPassword, isTrue);
    });

    test("a sign-in failure is reported in the user's language, not in the "
        'English ApiException keeps for its logs', () async {
      when(
        () => repo.login(any(), any()),
      ).thenThrow(const NetworkException('Cannot connect to server'));
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      expect(
        await notifier.login(LDe(), 'demo', 'secret'),
        'Keine Verbindung zum Server',
      );
    });

    test('a wrong password says so, rather than reporting the session as '
        'expired the way a plain 401 would', () async {
      when(
        () => repo.login(any(), any()),
      ).thenThrow(const UnauthorizedException(invalidCredentialsMessage));
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      expect(
        await notifier.login(LDe(), 'demo', 'wrong'),
        'Benutzername oder Passwort ist falsch',
      );
    });

    test('registration failures are localized too', () async {
      when(
        () => repo.register(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      ).thenThrow(const NetworkException('Cannot connect to server'));
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      expect(
        await notifier.register(
          l: LDe(),
          username: 'demo',
          email: 'd@x',
          password: 'p',
          firstName: 'D',
          lastName: 'X',
        ),
        'Keine Verbindung zum Server',
      );
    });

    test('login failure does not persist credentials', () async {
      when(
        () => repo.login(any(), any()),
      ).thenThrow(Exception('Invalid username or password'));
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.login(LEn(), 'demo', 'wrong');

      expect(error, 'Invalid username or password');
      expect(storage.data.containsKey('saved_username'), isFalse);
      expect(storage.data.containsKey('saved_password'), isFalse);
    });

    test(
      'login success with storage write failure still signs in, drops saved-password state',
      () async {
        final throwingStorage = ThrowingWriteStorage('saved_password');
        final throwingContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            apiClientProvider.overrideWithValue(apiClient),
            secureStorageProvider.overrideWithValue(throwingStorage),
          ],
        );
        addTearDown(throwingContainer.dispose);
        when(() => repo.login('demo', 'secret')).thenAnswer((_) async => user);
        final notifier = throwingContainer.read(
          authControllerProvider.notifier,
        );
        await notifier.init();

        final error = await notifier.login(LEn(), 'demo', 'secret');

        expect(error, isNull);
        final state = throwingContainer.read(authControllerProvider);
        expect(state.user, user);
        expect(state.hasSavedPassword, isFalse);
      },
    );

    test('register success persists username and password', () async {
      when(
        () => repo.register(
          username: 'new',
          email: 'n@x',
          password: 'pw',
          firstName: 'N',
          lastName: 'U',
        ),
      ).thenAnswer((_) async => user);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      await notifier.register(
        l: LEn(),
        username: 'new',
        email: 'n@x',
        password: 'pw',
        firstName: 'N',
        lastName: 'U',
      );

      expect(storage.data['saved_username'], 'new');
      expect(storage.data['saved_password'], 'pw');
      expect(container.read(authControllerProvider).savedUsername, 'new');
    });

    test(
      'init restores savedUsername and hasSavedPassword from storage',
      () async {
        storage.data['saved_username'] = 'demo';
        storage.data['saved_password'] = 'secret';
        final notifier = container.read(authControllerProvider.notifier);

        await notifier.init();

        final state = container.read(authControllerProvider);
        expect(state.savedUsername, 'demo');
        expect(state.hasSavedPassword, isTrue);
      },
    );

    test(
      'init with username but no password: hasSavedPassword false',
      () async {
        storage.data['saved_username'] = 'demo';
        final notifier = container.read(authControllerProvider.notifier);

        await notifier.init();

        final state = container.read(authControllerProvider);
        expect(state.savedUsername, 'demo');
        expect(state.hasSavedPassword, isFalse);
      },
    );

    test('session expiry on init keeps saved credentials', () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      when(() => repo.hasToken()).thenAnswer((_) async => true);
      when(
        () => repo.getProfile(),
      ).thenThrow(const UnauthorizedException('Not authenticated'));
      final notifier = container.read(authControllerProvider.notifier);

      await notifier.init();

      final state = container.read(authControllerProvider);
      expect(state.user, isNull);
      // The server answered and refused the token: the one failure entitled
      // to drop it, and with it the whole offline cache.
      verify(() => repo.logout()).called(1);
      expect(state.savedUsername, 'demo');
      expect(state.hasSavedPassword, isTrue);
      expect(storage.data['saved_password'], 'secret');
    });

    test(
      'a server that answers with something other than a profile keeps the '
      'token, because a 500 is not a revoked credential',
      () async {
        storage.data['saved_username'] = 'demo';
        storage.data['saved_password'] = 'secret';
        when(() => repo.hasToken()).thenAnswer((_) async => true);
        when(
          () => repo.getProfile(),
        ).thenThrow(const ServerException('Server error (500)'));
        final notifier = container.read(authControllerProvider.notifier);

        await notifier.init();

        expect(container.read(authControllerProvider).user, isNull);
        // logout() would delete the token and clear every cached figure over
        // a fault that is the server's, not the credential's.
        verifyNever(() => repo.logout());
      },
    );

    test(
      'logout forgets what was searched on the list screens, so the next '
      'person to sign in does not inherit it',
      () async {
        final notifier = container.read(authControllerProvider.notifier);
        await notifier.init();
        container
            .read(entityListFilterProvider('accounts').notifier)
            .setQuery('giro');

        await notifier.logout();

        expect(container.read(entityListFilterProvider('accounts')).query, '');
      },
    );

    test('logout deletes both keys and clears state', () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      await notifier.logout();

      expect(storage.data.containsKey('saved_username'), isFalse);
      expect(storage.data.containsKey('saved_password'), isFalse);
      final state = container.read(authControllerProvider);
      expect(state.savedUsername, isNull);
      expect(state.hasSavedPassword, isFalse);
      expect(state.user, isNull);
    });

    test('loginWithSavedCredentials calls repo with stored values', () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      when(() => repo.login('demo', 'secret')).thenAnswer((_) async => user);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.loginWithSavedCredentials(LEn());

      expect(error, isNull);
      verify(() => repo.login('demo', 'secret')).called(1);
      expect(container.read(authControllerProvider).user, user);
    });

    test(
      'loginWithSavedCredentials without stored password returns error',
      () async {
        storage.data['saved_username'] = 'demo';
        final notifier = container.read(authControllerProvider.notifier);
        await notifier.init();

        final error = await notifier.loginWithSavedCredentials(LEn());

        expect(error, 'No saved credentials');
        verifyNever(() => repo.login(any(), any()));
        expect(
          container.read(authControllerProvider).hasSavedPassword,
          isFalse,
        );
      },
    );

    test(
      'loginWithSavedCredentials on 401 drops password, keeps username',
      () async {
        storage.data['saved_username'] = 'demo';
        storage.data['saved_password'] = 'old';
        when(() => repo.login('demo', 'old')).thenThrow(
          const UnauthorizedException('Invalid username or password'),
        );
        final notifier = container.read(authControllerProvider.notifier);
        await notifier.init();

        final error = await notifier.loginWithSavedCredentials(LEn());

        expect(error, 'Saved password no longer valid');
        expect(storage.data['saved_username'], 'demo');
        expect(storage.data.containsKey('saved_password'), isFalse);
        final state = container.read(authControllerProvider);
        expect(state.savedUsername, 'demo');
        expect(state.hasSavedPassword, isFalse);
      },
    );

    test(
      'loginWithSavedCredentials on 403 keeps password, surfaces error',
      () async {
        storage.data['saved_username'] = 'demo';
        storage.data['saved_password'] = 'secret';
        when(
          () => repo.login('demo', 'secret'),
        ).thenThrow(const UnauthorizedException('API access is not enabled'));
        final notifier = container.read(authControllerProvider.notifier);
        await notifier.init();

        final error = await notifier.loginWithSavedCredentials(LEn());

        expect(error, isNotNull);
        expect(error, isNot('Saved password no longer valid'));
        expect(storage.data['saved_password'], 'secret');
        expect(container.read(authControllerProvider).hasSavedPassword, isTrue);
      },
    );

    test(
      'loginWithSavedCredentials on network error signs in from the saved '
      'profile, so the fingerprint works on a train',
      () async {
        storage.data['saved_username'] = 'demo';
        storage.data['saved_password'] = 'secret';
        when(
          () => repo.login('demo', 'secret'),
        ).thenThrow(const NetworkException('No connection'));
        final notifier = container.read(authControllerProvider.notifier);
        // Leaves a fresh profile snapshot behind, which is what the offline
        // sign-in below restores.
        await notifier.init();

        final error = await notifier.loginWithSavedCredentials(LEn());

        expect(error, isNull);
        expect(container.read(authControllerProvider).user, user);
        expect(storage.data['saved_password'], 'secret');
        expect(container.read(authControllerProvider).hasSavedPassword, isTrue);
      },
    );

    test(
      'loginWithSavedCredentials on network error with no saved profile '
      'keeps credentials and reports the failure',
      () async {
        storage.data['saved_username'] = 'demo';
        storage.data['saved_password'] = 'secret';
        when(
          () => repo.login('demo', 'secret'),
        ).thenThrow(const NetworkException('No connection'));
        // No successful profile fetch, so nothing to sign in as offline.
        when(() => repo.hasToken()).thenAnswer((_) async => false);
        final notifier = container.read(authControllerProvider.notifier);
        await notifier.init();
        when(() => repo.hasToken()).thenAnswer((_) async => true);

        final error = await notifier.loginWithSavedCredentials(LEn());

        expect(error, LEn().errorNetwork);
        expect(container.read(authControllerProvider).user, isNull);
        expect(storage.data['saved_password'], 'secret');
        expect(container.read(authControllerProvider).hasSavedPassword, isTrue);
      },
    );

    test('forgetSavedCredentials deletes both keys and clears state', () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      await notifier.forgetSavedCredentials();

      expect(storage.data.containsKey('saved_username'), isFalse);
      expect(storage.data.containsKey('saved_password'), isFalse);
      final state = container.read(authControllerProvider);
      expect(state.savedUsername, isNull);
      expect(state.hasSavedPassword, isFalse);
    });
  });

  group('a session the server no longer accepts', () {
    /// The handler AuthController hands to ApiClient for a 401 that is not
    /// a failed sign-in. Captured from the mock, since that is the seam the
    /// interceptor calls through on a real client.
    void Function() expiredCallback() =>
        verify(() => apiClient.onSessionExpired = captureAny()).captured.last
            as void Function();

    test(
      'a 401 from an ordinary endpoint signs the user out, so the router '
      'sends them to login instead of leaving every screen erroring',
      () async {
        when(() => repo.hasToken()).thenAnswer((_) async => true);
        when(() => repo.getProfile()).thenAnswer((_) async => user);
        final notifier = container.read(authControllerProvider.notifier);
        await notifier.init();
        expect(container.read(authControllerProvider).isLoggedIn, isTrue);

        expiredCallback()();
        await Future<void>.delayed(Duration.zero);

        expect(container.read(authControllerProvider).isLoggedIn, isFalse);
        verify(() => repo.logout()).called(1);
      },
    );

    test('the username is kept, so signing back in does not start from a '
        'blank form', () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      when(() => repo.hasToken()).thenAnswer((_) async => true);
      when(() => repo.getProfile()).thenAnswer((_) async => user);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      expiredCallback()();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authControllerProvider).savedUsername, 'demo');
      expect(storage.data['saved_password'], 'secret');
    });

    test('several requests failing at once sign the user out once, not once '
        'each', () async {
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();
      expect(container.read(authControllerProvider).isLoggedIn, isTrue);

      final expired = expiredCallback();
      expired();
      expired();
      expired();
      await Future<void>.delayed(Duration.zero);

      verify(() => repo.logout()).called(1);
    });
  });

  group('signing in with no server to sign in to', () {
    /// A device carrying what a previous successful online session leaves
    /// behind -- saved credentials and a fresh profile snapshot -- sitting on
    /// the sign-in screen with no server to reach.
    ///
    /// `hasToken` is false across `init()` so this launch restores nobody:
    /// [login] is only ever called from a screen the user is signed out on,
    /// and a test that starts already signed in cannot tell a refusal from a
    /// success.
    Future<AuthController> primed() async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      storage.data['saved_profile'] = jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'profile': user.toJson(),
      });
      when(() => repo.hasToken()).thenAnswer((_) async => false);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();
      when(() => repo.hasToken()).thenAnswer((_) async => true);
      when(
        () => repo.login(any(), any()),
      ).thenThrow(const NetworkException('Cannot connect to server'));
      return notifier;
    }

    test('the right credentials get in, from the saved profile', () async {
      final notifier = await primed();

      final error = await notifier.login(LEn(), 'demo', 'secret');

      expect(error, isNull);
      expect(container.read(authControllerProvider).user, user);
    });

    test('the wrong password does not', () async {
      final notifier = await primed();

      final error = await notifier.login(LEn(), 'demo', 'wrong');

      expect(error, LEn().errorNetwork);
      expect(container.read(authControllerProvider).user, isNull);
    });

    test('nor does the wrong username', () async {
      final notifier = await primed();

      final error = await notifier.login(LEn(), 'someone', 'secret');

      expect(error, LEn().errorNetwork);
      expect(container.read(authControllerProvider).user, isNull);
    });

    test(
      'a password the server itself rejected never reaches the local check',
      () async {
        final notifier = await primed();
        when(
          () => repo.login('demo', 'secret'),
        ).thenThrow(const UnauthorizedException(invalidCredentialsMessage));

        final error = await notifier.login(LEn(), 'demo', 'secret');

        // Falling through to the saved password here would be a way to keep
        // using a credential the server has revoked.
        expect(error, LEn().errorInvalidCredentials);
        expect(container.read(authControllerProvider).user, isNull);
      },
    );

    test(
      'a certificate this install has not trusted is not "offline"',
      () async {
        final notifier = await primed();
        when(() => repo.login('demo', 'secret')).thenThrow(
          ApiException.fromDio(
            DioException(
              requestOptions: RequestOptions(path: '/auth/login'),
              type: DioExceptionType.badCertificate,
            ),
          ),
        );

        final error = await notifier.login(LEn(), 'demo', 'secret');

        // The server answered. Signing in locally here would pre-empt the
        // trust prompt the login screen is about to raise.
        expect(error, LEn().errorCertificate);
        expect(container.read(authControllerProvider).user, isNull);
      },
    );

    test('a token that is already gone refuses the whole thing', () async {
      final notifier = await primed();
      when(() => repo.hasToken()).thenAnswer((_) async => false);

      final error = await notifier.login(LEn(), 'demo', 'secret');

      // Without a token the app would be signed in to nothing: the moment
      // the network returned, the first request would 401 straight back out.
      expect(error, LEn().errorNetwork);
      expect(container.read(authControllerProvider).user, isNull);
    });

    test('a snapshot older than a fortnight is not who is signed in', () async {
      final notifier = await primed();
      storage.data['saved_profile'] = jsonEncode({
        'savedAt': DateTime.now()
            .subtract(offlineProfileMaxAge + const Duration(days: 1))
            .toIso8601String(),
        'profile': user.toJson(),
      });

      final error = await notifier.login(LEn(), 'demo', 'secret');

      expect(error, LEn().errorNetwork);
      expect(container.read(authControllerProvider).user, isNull);
    });

    test(
      'a snapshot that will not parse is a snapshot we do not have',
      () async {
        final notifier = await primed();
        storage.data['saved_profile'] = 'not json';

        final error = await notifier.login(LEn(), 'demo', 'secret');

        expect(error, LEn().errorNetwork);
      },
    );

    test('with biometric unlock on, an unreachable server on init keeps the '
        'token and restores the session for the app lock to guard', () async {
      storage.data['biometric_enabled'] = 'true';
      // One successful launch, to leave a snapshot on the device.
      await container.read(authControllerProvider.notifier).init();
      expect(storage.data['saved_profile'], isNotNull);

      // A second launch, over the same storage, with nothing to reach.
      when(
        () => repo.getProfile(),
      ).thenThrow(const NetworkException('Cannot connect to server'));
      final relaunch = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          apiClientProvider.overrideWithValue(apiClient),
          secureStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(relaunch.dispose);

      await relaunch.read(authControllerProvider.notifier).init();

      final relaunched = relaunch.read(authControllerProvider);
      expect(relaunched.user, user);
      expect(relaunched.restoredSession, isTrue);
      // logout() here is what used to delete the token and wipe every
      // cached figure on a single offline launch.
      verifyNever(() => repo.logout());
    });

    test('without biometric unlock, an offline launch signs nobody in and '
        'asks for the password -- which still works offline', () async {
      // Regression: the snapshot was restored with no check at all, so an
      // offline start opened the app for whoever held the phone.
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      storage.data['saved_profile'] = jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'profile': user.toJson(),
      });
      when(
        () => repo.getProfile(),
      ).thenThrow(const NetworkException('Cannot connect to server'));
      final notifier = container.read(authControllerProvider.notifier);

      await notifier.init();

      final state = container.read(authControllerProvider);
      expect(state.user, isNull);
      expect(state.initialized, isTrue);
      expect(state.savedUsername, 'demo', reason: 'the form is prefilled');
      // The session is not thrown away, only not resumed unchecked.
      verifyNever(() => repo.logout());
      expect(storage.data['saved_profile'], isNotNull);

      when(
        () => repo.login(any(), any()),
      ).thenThrow(const NetworkException('Cannot connect to server'));
      expect(await notifier.login(LEn(), 'demo', 'wrong'), isNotNull);
      expect(container.read(authControllerProvider).user, isNull);
      expect(await notifier.login(LEn(), 'demo', 'secret'), isNull);
      expect(container.read(authControllerProvider).user, user);
    });

    test('forgetSavedCredentials drops the profile snapshot too', () async {
      final notifier = await primed();
      expect(storage.data['saved_profile'], isNotNull);

      await notifier.forgetSavedCredentials();

      expect(storage.data.containsKey('saved_profile'), isFalse);
    });

    test('a failed init can be retried, rather than being the answer for the '
        'life of the process', () async {
      when(() => repo.hasToken()).thenThrow(Exception('storage unavailable'));
      final notifier = container.read(authControllerProvider.notifier);

      await expectLater(notifier.init(), throwsA(isA<Exception>()));
      when(() => repo.hasToken()).thenAnswer((_) async => true);
      await notifier.init();

      // The retry got through to the network half. Memoizing the rejection
      // left the login screen with no saved username and no biometric offer
      // -- the "type both again" bug.
      expect(container.read(authControllerProvider).user, user);
    });

    test('a launch whose network half fails still leaves a form that knows '
        'who you are', () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      storage.data['biometric_enabled'] = 'true';
      when(() => repo.hasToken()).thenThrow(Exception('kaboom'));
      final notifier = container.read(authControllerProvider.notifier);

      await expectLater(notifier.init(), throwsA(isA<Exception>()));

      final state = container.read(authControllerProvider);
      expect(state.initialized, isTrue, reason: 'gates the outbox drain');
      expect(state.savedUsername, 'demo');
      expect(state.hasSavedPassword, isTrue);
      expect(state.biometricEnabled, isTrue);
    });
  });

  group('restoredSession, which the app lock keys off', () {
    String snapshot() => jsonEncode({
      'savedAt': DateTime.now().toIso8601String(),
      'profile': user.toJson(),
    });

    test(
      'a session restored from the stored token is marked restored',
      () async {
        await container.read(authControllerProvider.notifier).init();

        final state = container.read(authControllerProvider);
        expect(state.user, user);
        expect(state.restoredSession, isTrue);
      },
    );

    test(
      'a session restored offline from the snapshot is marked restored',
      () async {
        storage.data['saved_profile'] = snapshot();
        storage.data['biometric_enabled'] = 'true';
        when(
          () => repo.getProfile(),
        ).thenThrow(const NetworkException('Cannot connect to server'));

        await container.read(authControllerProvider.notifier).init();

        final state = container.read(authControllerProvider);
        expect(state.user, user);
        expect(state.restoredSession, isTrue);
      },
    );

    test('a password sign-in is not a restored session', () async {
      when(() => repo.hasToken()).thenAnswer((_) async => false);
      when(() => repo.login('demo', 'secret')).thenAnswer((_) async => user);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      expect(await notifier.login(LEn(), 'demo', 'secret'), isNull);

      final state = container.read(authControllerProvider);
      expect(state.user, user);
      expect(state.restoredSession, isFalse);
    });

    test(
      'an offline password sign-in is not a restored session either',
      () async {
        storage.data['saved_username'] = 'demo';
        storage.data['saved_password'] = 'secret';
        storage.data['saved_profile'] = snapshot();
        when(() => repo.hasToken()).thenAnswer((_) async => false);
        final notifier = container.read(authControllerProvider.notifier);
        await notifier.init();
        when(() => repo.hasToken()).thenAnswer((_) async => true);
        when(
          () => repo.login(any(), any()),
        ).thenThrow(const NetworkException('Cannot connect to server'));

        expect(await notifier.login(LEn(), 'demo', 'secret'), isNull);

        final state = container.read(authControllerProvider);
        expect(state.user, user);
        expect(state.restoredSession, isFalse);
      },
    );

    test('signing out clears it', () async {
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      await notifier.logout();

      expect(container.read(authControllerProvider).restoredSession, isFalse);
    });
  });
}
