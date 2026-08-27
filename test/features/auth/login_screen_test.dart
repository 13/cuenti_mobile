import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/auth/ui/login_screen.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
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

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late MockAuthRepository repo;

  setUpAll(() {
    registerFallbackValue('');
  });

  const user = UserProfile(username: 'demo', email: 'd@x');

  MockLocalAuthentication authenticatorReturning(bool result) {
    final a = MockLocalAuthentication();
    when(() => a.authenticate(
          localizedReason: any(named: 'localizedReason'),
        )).thenAnswer((_) async => result);
    return a;
  }

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
    LocalAuthentication? authenticator,
  }) async {
    final s = storage ?? _MemoryStorage();
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => LoginScreen(authenticator: authenticator),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          secureStorageProvider.overrideWithValue(s),
        ],
        child: MaterialApp.router(routerConfig: router),
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

  testWidgets('no biometric button when biometric disabled', (tester) async {
    final storage = _MemoryStorage()
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';

    await pumpLogin(tester, storage: storage);

    expect(find.text('Sign in with biometrics'), findsNothing);
  });

  testWidgets('no biometric button when enabled but no saved password',
      (tester) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo';

    await pumpLogin(tester, storage: storage);

    expect(find.text('Sign in with biometrics'), findsNothing);
  });

  testWidgets('auto-prompts biometric once and signs in on success',
      (tester) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';
    final authenticator = authenticatorReturning(true);
    when(() => repo.login('demo', 'secret')).thenAnswer((_) async => user);

    await pumpLogin(tester, storage: storage, authenticator: authenticator);

    verify(() => authenticator.authenticate(
          localizedReason: 'Sign in to Cuenti',
        )).called(1);
    verify(() => repo.login('demo', 'secret')).called(1);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('biometric cancel: button stays, no login, no error',
      (tester) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';
    final authenticator = authenticatorReturning(false);

    await pumpLogin(tester, storage: storage, authenticator: authenticator);

    verifyNever(() => repo.login(any(), any()));
    expect(find.text('Sign in with biometrics'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    // Tapping the button retries the prompt.
    await tester.tap(find.text('Sign in with biometrics'));
    await tester.pumpAndSettle();
    verify(() => authenticator.authenticate(
          localizedReason: any(named: 'localizedReason'),
        )).called(2);
  });

  testWidgets('biometric exception falls back silently', (tester) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';
    final authenticator = MockLocalAuthentication();
    when(() => authenticator.authenticate(
          localizedReason: any(named: 'localizedReason'),
        )).thenThrow(Exception('NotAvailable'));

    await pumpLogin(tester, storage: storage, authenticator: authenticator);

    verifyNever(() => repo.login(any(), any()));
    expect(find.text('NotAvailable'), findsNothing);
  });

  testWidgets('rejected saved password shows error and hides button',
      (tester) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'old';
    final authenticator = authenticatorReturning(true);
    when(() => repo.login('demo', 'old')).thenThrow(
        const UnauthorizedException('Invalid username or password'));

    await pumpLogin(tester, storage: storage, authenticator: authenticator);

    expect(find.text('Saved password no longer valid'), findsOneWidget);
    expect(find.text('Sign in with biometrics'), findsNothing);
    expect(storage.data.containsKey('saved_password'), isFalse);
    final usernameField =
        tester.widget<TextFormField>(find.byType(TextFormField).at(0));
    expect(usernameField.controller!.text, 'demo');
  });
}
