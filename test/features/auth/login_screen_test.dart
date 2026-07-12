import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/auth/ui/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// In-memory [SecureStorage] fake so `ApiClient.init()` (called from
/// `AuthController.init()`) never touches the real `flutter_secure_storage`
/// platform channel, which isn't available in widget tests.
class _MemoryStorage extends SecureStorage {
  _MemoryStorage() : super();
  final Map<String, String> _data = {};
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
    // Stub the calls `AuthController.init()` makes automatically on build.
    when(() => repo.hasToken()).thenAnswer((_) async => false);
    when(() => repo.fetchRegistrationEnabled()).thenAnswer((_) async => true);
    when(() => repo.serverUrl).thenReturn('https://cuenti.test');
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          secureStorageProvider.overrideWithValue(_MemoryStorage()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('calls repository with entered credentials and shows error on failure',
      (tester) async {
    when(() => repo.login(any(), any()))
        .thenThrow(Exception('Invalid username or password'));

    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'demo');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pumpAndSettle();

    verify(() => repo.login('demo', 'wrong-password')).called(1);
    expect(find.text('Invalid username or password'), findsOneWidget);
  });
}
