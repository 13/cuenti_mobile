import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/auth/ui/register_screen.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockApiClient extends Mock implements ApiClient {}

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

void main() {
  const user = UserProfile(username: 'demo', email: 'demo@example.com');

  late MockAuthRepository repo;
  late MockApiClient client;

  setUp(() {
    repo = MockAuthRepository();
    client = MockApiClient();
    when(client.init).thenAnswer((_) async {});
    when(repo.hasToken).thenAnswer((_) async => false);
    when(repo.fetchRegistrationEnabled).thenAnswer((_) async => true);
    when(
      () => repo.register(
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
      ),
    ).thenAnswer((_) async => user);
  });

  Future<void> pumpRegister(WidgetTester tester, {Locale? locale}) async {
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login page')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          apiClientProvider.overrideWithValue(client),
          secureStorageProvider.overrideWithValue(_MemoryStorage()),
        ],
        child: MaterialApp.router(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The six fields in the order the form lays them out.
  Future<void> fillIn(
    WidgetTester tester, {
    String first = 'Ada',
    String last = 'Lovelace',
    String username = 'ada',
    String email = 'ada@example.com',
    String password = 'secret1',
    String? confirm,
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), first);
    await tester.enterText(fields.at(1), last);
    await tester.enterText(fields.at(2), username);
    await tester.enterText(fields.at(3), email);
    await tester.enterText(fields.at(4), password);
    await tester.enterText(fields.at(5), confirm ?? password);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, {String label = 'Register'}) async {
    final button = find.widgetWithText(FilledButton, label);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('a complete form registers and lands on the dashboard', (
    tester,
  ) async {
    await pumpRegister(tester);
    await fillIn(tester);

    await submit(tester);

    verify(
      () => repo.register(
        username: 'ada',
        email: 'ada@example.com',
        password: 'secret1',
        firstName: 'Ada',
        lastName: 'Lovelace',
      ),
    ).called(1);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  group('what it refuses, and in which language', () {
    testWidgets('an empty form does not reach the server', (tester) async {
      await pumpRegister(tester);

      await submit(tester);

      verifyNever(
        () => repo.register(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      );
    });

    testWidgets('a mismatched confirmation is caught before the server', (
      tester,
    ) async {
      await pumpRegister(tester);
      await fillIn(tester, confirm: 'different');

      await submit(tester);

      verifyNever(
        () => repo.register(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      );
    });

    testWidgets('a required field says so in the reader’s language, not in '
        'English', (tester) async {
      await pumpRegister(tester, locale: const Locale('de'));

      await submit(tester, label: 'Registrieren');

      expect(find.text('Required'), findsNothing);
      expect(find.text('Pflichtfeld'), findsWidgets);
    });

    testWidgets('so does a too-short username', (tester) async {
      await pumpRegister(tester, locale: const Locale('de'));
      await fillIn(tester, username: 'ab');

      await submit(tester, label: 'Registrieren');

      expect(find.textContaining('Min 3'), findsNothing);
      expect(find.textContaining('Mindestens 3'), findsOneWidget);
    });

    testWidgets('so does an address with no @ in it', (tester) async {
      await pumpRegister(tester, locale: const Locale('de'));
      await fillIn(tester, email: 'nope');

      await submit(tester, label: 'Registrieren');

      expect(find.text('Invalid email'), findsNothing);
      expect(find.text('Ungültige E-Mail'), findsOneWidget);
    });

    testWidgets('so does a mismatched confirmation', (tester) async {
      await pumpRegister(tester, locale: const Locale('de'));
      await fillIn(tester, confirm: 'different');

      await submit(tester, label: 'Registrieren');

      expect(find.text('Passwords do not match'), findsNothing);
      expect(find.text('Passwörter stimmen nicht überein'), findsOneWidget);
    });
  });

  testWidgets('a server that refuses shows why and stays on the form', (
    tester,
  ) async {
    when(
      () => repo.register(
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
      ),
    ).thenThrow(Exception('taken'));

    await pumpRegister(tester);
    await fillIn(tester);

    await submit(tester);

    expect(find.text('Dashboard'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('there is a way back to signing in', (tester) async {
    await pumpRegister(tester);

    // Below the fold on a test-sized screen.
    final back = find.byType(TextButton);
    await tester.ensureVisible(back);
    await tester.pumpAndSettle();
    await tester.tap(back);
    await tester.pumpAndSettle();

    expect(find.text('Login page'), findsOneWidget);
  });
}
