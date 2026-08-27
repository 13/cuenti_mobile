import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
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

    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      apiClientProvider.overrideWithValue(apiClient),
      secureStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
  });

  test('concurrent init() calls are single-flight: getProfile called once',
      () async {
    final notifier = container.read(authControllerProvider.notifier);

    // Two explicit concurrent calls, plus the microtask `build()` already
    // scheduled internally, all race for the same in-flight init.
    await Future.wait([notifier.init(), notifier.init()]);

    verify(() => repo.getProfile()).called(1);
    expect(container.read(authControllerProvider).user, user);
  });

  group('saved credentials', () {
    test('login success persists username and password', () async {
      when(() => repo.login('demo', 'secret')).thenAnswer((_) async => user);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.login('demo', 'secret');

      expect(error, isNull);
      expect(storage.data['saved_username'], 'demo');
      expect(storage.data['saved_password'], 'secret');
      final state = container.read(authControllerProvider);
      expect(state.savedUsername, 'demo');
      expect(state.hasSavedPassword, isTrue);
    });

    test('login failure does not persist credentials', () async {
      when(() => repo.login(any(), any()))
          .thenThrow(Exception('Invalid username or password'));
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.login('demo', 'wrong');

      expect(error, 'Invalid username or password');
      expect(storage.data.containsKey('saved_username'), isFalse);
      expect(storage.data.containsKey('saved_password'), isFalse);
    });

    test(
        'login success with storage write failure still signs in, drops saved-password state',
        () async {
      final throwingStorage = ThrowingWriteStorage('saved_password');
      final throwingContainer = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        apiClientProvider.overrideWithValue(apiClient),
        secureStorageProvider.overrideWithValue(throwingStorage),
      ]);
      addTearDown(throwingContainer.dispose);
      when(() => repo.login('demo', 'secret')).thenAnswer((_) async => user);
      final notifier = throwingContainer.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.login('demo', 'secret');

      expect(error, isNull);
      final state = throwingContainer.read(authControllerProvider);
      expect(state.user, user);
      expect(state.hasSavedPassword, isFalse);
    });

    test('register success persists username and password', () async {
      when(() => repo.register(
            username: 'new',
            email: 'n@x',
            password: 'pw',
            firstName: 'N',
            lastName: 'U',
          )).thenAnswer((_) async => user);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      await notifier.register(
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

    test('init restores savedUsername and hasSavedPassword from storage',
        () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      final notifier = container.read(authControllerProvider.notifier);

      await notifier.init();

      final state = container.read(authControllerProvider);
      expect(state.savedUsername, 'demo');
      expect(state.hasSavedPassword, isTrue);
    });

    test('init with username but no password: hasSavedPassword false',
        () async {
      storage.data['saved_username'] = 'demo';
      final notifier = container.read(authControllerProvider.notifier);

      await notifier.init();

      final state = container.read(authControllerProvider);
      expect(state.savedUsername, 'demo');
      expect(state.hasSavedPassword, isFalse);
    });

    test('session expiry on init keeps saved credentials', () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      when(() => repo.hasToken()).thenAnswer((_) async => true);
      when(() => repo.getProfile()).thenThrow(Exception('expired'));
      final notifier = container.read(authControllerProvider.notifier);

      await notifier.init();

      final state = container.read(authControllerProvider);
      expect(state.user, isNull);
      expect(state.savedUsername, 'demo');
      expect(state.hasSavedPassword, isTrue);
      expect(storage.data['saved_password'], 'secret');
    });

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

      final error = await notifier.loginWithSavedCredentials();

      expect(error, isNull);
      verify(() => repo.login('demo', 'secret')).called(1);
      expect(container.read(authControllerProvider).user, user);
    });

    test('loginWithSavedCredentials without stored password returns error',
        () async {
      storage.data['saved_username'] = 'demo';
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.loginWithSavedCredentials();

      expect(error, 'No saved credentials');
      verifyNever(() => repo.login(any(), any()));
      expect(container.read(authControllerProvider).hasSavedPassword, isFalse);
    });

    test('loginWithSavedCredentials on 401 drops password, keeps username',
        () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'old';
      when(() => repo.login('demo', 'old')).thenThrow(
          const UnauthorizedException('Invalid username or password'));
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.loginWithSavedCredentials();

      expect(error, 'Saved password no longer valid');
      expect(storage.data['saved_username'], 'demo');
      expect(storage.data.containsKey('saved_password'), isFalse);
      final state = container.read(authControllerProvider);
      expect(state.savedUsername, 'demo');
      expect(state.hasSavedPassword, isFalse);
    });

    test('loginWithSavedCredentials on 403 keeps password, surfaces error',
        () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      when(() => repo.login('demo', 'secret')).thenThrow(
          const UnauthorizedException('API access is not enabled'));
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.loginWithSavedCredentials();

      expect(error, isNotNull);
      expect(error, isNot('Saved password no longer valid'));
      expect(storage.data['saved_password'], 'secret');
      expect(container.read(authControllerProvider).hasSavedPassword, isTrue);
    });

    test('loginWithSavedCredentials on network error keeps credentials',
        () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      when(() => repo.login('demo', 'secret'))
          .thenThrow(const NetworkException('No connection'));
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.loginWithSavedCredentials();

      expect(error, isNotNull);
      expect(storage.data['saved_password'], 'secret');
      expect(container.read(authControllerProvider).hasSavedPassword, isTrue);
    });

    test('forgetSavedCredentials deletes both keys and clears state',
        () async {
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
}
