import 'package:cuentimobile/core/api/api_client.dart';
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
  final Map<String, String> _data = {};
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
}

void main() {
  late MockAuthRepository repo;
  late MockApiClient apiClient;
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
    when(() => apiClient.init()).thenAnswer((_) async {});
    when(() => repo.hasToken()).thenAnswer((_) async => true);
    when(() => repo.getProfile()).thenAnswer((_) async => user);
    when(() => repo.fetchRegistrationEnabled()).thenAnswer((_) async => true);

    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      apiClientProvider.overrideWithValue(apiClient),
      secureStorageProvider.overrideWithValue(MemoryStorage()),
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
}
