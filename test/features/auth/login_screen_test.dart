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
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
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

  Future<_MemoryStorage> pumpLogin(
    WidgetTester tester, {
    _MemoryStorage? storage,
  }) async {
    final s = storage ?? _MemoryStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          secureStorageProvider.overrideWithValue(s),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return s;
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

  testWidgets('prefills username from storage and shows Not you?',
      (tester) async {
    final storage = _MemoryStorage()..data['saved_username'] = 'demo';

    await pumpLogin(tester, storage: storage);

    final usernameField =
        tester.widget<TextFormField>(find.byType(TextFormField).at(0));
    expect(usernameField.controller!.text, 'demo');
    expect(find.text('Not you?'), findsOneWidget);
  });

  testWidgets('no Not you? link without saved username', (tester) async {
    await pumpLogin(tester);
    expect(find.text('Not you?'), findsNothing);
  });

  testWidgets('Not you? clears fields and storage', (tester) async {
    final storage = _MemoryStorage()
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';

    await pumpLogin(tester, storage: storage);
    await tester.tap(find.text('Not you?'));
    await tester.pumpAndSettle();

    final usernameField =
        tester.widget<TextFormField>(find.byType(TextFormField).at(0));
    expect(usernameField.controller!.text, isEmpty);
    expect(storage.data.containsKey('saved_username'), isFalse);
    expect(storage.data.containsKey('saved_password'), isFalse);
    expect(find.text('Not you?'), findsNothing);
  });
}
