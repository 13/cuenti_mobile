import 'dart:async';

import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/certificate_pins.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/auth/ui/login_screen.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
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

const _fingerprint = 'AA:BB:CC:DD';
const _host = 'cuenti.muh';

void main() {
  late MockAuthRepository repo;
  late CertificatePins pins;
  late ApiClient client;

  setUpAll(() {
    registerFallbackValue('');
  });

  const user = UserProfile(username: 'demo', email: 'd@x');

  MockLocalAuthentication authenticatorReturning({required bool result}) {
    final a = MockLocalAuthentication();
    when(
      () => a.authenticate(
        localizedReason: any(named: 'localizedReason'),
      ),
    ).thenAnswer((_) async => result);
    return a;
  }

  setUp(() {
    repo = MockAuthRepository();
    pins = CertificatePins(_MemoryStorage());
    client = ApiClient(_MemoryStorage(), dioOverride: Dio(), pins: pins);
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
          builder: (_, _) => LoginScreen(authenticator: authenticator),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          apiClientProvider.overrideWithValue(client),
          secureStorageProvider.overrideWithValue(s),
        ],
        child: MaterialApp.router(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return s;
  }

  testWidgets(
    'calls repository with entered credentials and shows error on failure',
    (tester) async {
      when(
        () => repo.login(any(), any()),
      ).thenThrow(Exception('Invalid username or password'));

      await pumpLogin(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'demo');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'wrong-password',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      verify(() => repo.login('demo', 'wrong-password')).called(1);
      expect(find.text('Invalid username or password'), findsOneWidget);
    },
  );

  testWidgets('prefills username from storage and shows Not you?', (
    tester,
  ) async {
    final storage = _MemoryStorage()..data['saved_username'] = 'demo';

    await pumpLogin(tester, storage: storage);

    final usernameField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(0),
    );
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

    final usernameField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(0),
    );
    expect(usernameField.controller!.text, isEmpty);
    expect(storage.data.containsKey('saved_username'), isFalse);
    expect(storage.data.containsKey('saved_password'), isFalse);
    expect(find.text('Not you?'), findsNothing);
    final usernameEditableState = tester.state<EditableTextState>(
      find.descendant(
        of: find.byType(TextFormField).at(0),
        matching: find.byType(EditableText),
      ),
    );
    expect(usernameEditableState.widget.focusNode.hasFocus, isTrue);
  });

  testWidgets('no biometric button when biometric disabled', (tester) async {
    final storage = _MemoryStorage()
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';

    await pumpLogin(tester, storage: storage);

    expect(find.text('Sign in with biometrics'), findsNothing);
  });

  testWidgets('no biometric button when enabled but no saved password', (
    tester,
  ) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo';

    await pumpLogin(tester, storage: storage);

    expect(find.text('Sign in with biometrics'), findsNothing);
  });

  testWidgets('auto-prompts biometric once and signs in on success', (
    tester,
  ) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';
    final authenticator = authenticatorReturning(result: true);
    when(() => repo.login('demo', 'secret')).thenAnswer((_) async => user);

    await pumpLogin(tester, storage: storage, authenticator: authenticator);

    verify(
      () => authenticator.authenticate(
        localizedReason: 'Sign in to Cuenti',
      ),
    ).called(1);
    verify(() => repo.login('demo', 'secret')).called(1);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('biometric cancel: button stays, no login, no error', (
    tester,
  ) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';
    final authenticator = authenticatorReturning(result: false);

    await pumpLogin(tester, storage: storage, authenticator: authenticator);

    verifyNever(() => repo.login(any(), any()));
    expect(find.text('Sign in with biometrics'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    // Tapping the button retries the prompt.
    await tester.tap(find.text('Sign in with biometrics'));
    await tester.pumpAndSettle();
    verify(
      () => authenticator.authenticate(
        localizedReason: any(named: 'localizedReason'),
      ),
    ).called(2);
  });

  testWidgets('biometric exception falls back silently', (tester) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';
    final authenticator = MockLocalAuthentication();
    when(
      () => authenticator.authenticate(
        localizedReason: any(named: 'localizedReason'),
      ),
    ).thenThrow(Exception('NotAvailable'));

    await pumpLogin(tester, storage: storage, authenticator: authenticator);

    verifyNever(() => repo.login(any(), any()));
    expect(find.text('NotAvailable'), findsNothing);
  });

  testWidgets(
    'biometric prompt disables both buttons until it resolves, then re-enables',
    (tester) async {
      final storage = _MemoryStorage()
        ..data['biometric_enabled'] = 'true'
        ..data['saved_username'] = 'demo'
        ..data['saved_password'] = 'secret';
      // First call is the auto-prompt fired from init(); it must resolve
      // promptly so `pumpLogin`'s settle doesn't spin forever on the
      // indeterminate progress indicator. The second call (the manual tap
      // below) stays pending until the test completes it.
      var callCount = 0;
      final completer = Completer<bool>();
      final authenticator = MockLocalAuthentication();
      when(
        () => authenticator.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) {
        callCount++;
        return callCount == 1 ? Future.value(false) : completer.future;
      });

      await pumpLogin(tester, storage: storage, authenticator: authenticator);

      await tester.tap(find.text('Sign in with biometrics'));
      await tester.pump();

      final signInButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      final biometricButton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(signInButton.onPressed, isNull);
      expect(biometricButton.onPressed, isNull);

      completer.complete(false);
      await tester.pumpAndSettle();

      final signInButtonAfter = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      final biometricButtonAfter = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(signInButtonAfter.onPressed, isNotNull);
      expect(biometricButtonAfter.onPressed, isNotNull);
      verifyNever(() => repo.login(any(), any()));
    },
  );

  testWidgets('rejected saved password shows error and hides button', (
    tester,
  ) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'old';
    final authenticator = authenticatorReturning(result: true);
    when(
      () => repo.login('demo', 'old'),
    ).thenThrow(const UnauthorizedException('Invalid username or password'));

    await pumpLogin(tester, storage: storage, authenticator: authenticator);

    expect(find.text('Saved password no longer valid'), findsOneWidget);
    expect(find.text('Sign in with biometrics'), findsNothing);
    expect(storage.data.containsKey('saved_password'), isFalse);
    final usernameField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(0),
    );
    expect(usernameField.controller!.text, 'demo');
  });

  testWidgets('an unreachable server still leaves a usable login form', (
    tester,
  ) async {
    // AuthController.init() calls this unguarded, so a server that is down
    // takes the whole session restore with it.
    when(
      () => repo.fetchRegistrationEnabled(),
    ).thenThrow(const ServerException('server unreachable'));

    await pumpLogin(tester);

    expect(
      tester.takeException(),
      isNull,
      reason: 'a failed session restore must not escape as an async error',
    );
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
  });

  /// The session restore `LoginScreen` runs on first frame reaches the
  /// server, so a certificate turned away there is what a fresh install sees
  /// before it has typed anything.
  void rejectCertificateOnStartupProbe() {
    when(() => repo.fetchRegistrationEnabled()).thenAnswer((_) async {
      pins.evaluate(_host, _fingerprint);
      return true;
    });
  }

  testWidgets('a first launch against the default server asks the user to '
      'vouch for its certificate', (tester) async {
    rejectCertificateOnStartupProbe();

    await pumpLogin(tester);

    expect(
      find.textContaining(_fingerprint),
      findsOneWidget,
      reason:
          'the user never passes through server setup on a fresh install, '
          'so the prompt has to be offered here',
    );
    expect(
      find.textContaining(_host),
      findsOneWidget,
      reason: 'the prompt names the host it is asking the user to vouch for',
    );
  });

  testWidgets('trusting from the login screen pins the certificate', (
    tester,
  ) async {
    rejectCertificateOnStartupProbe();

    await pumpLogin(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Trust'));
    await tester.pumpAndSettle();

    expect(pins.pinFor(_host), _fingerprint);
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('declining leaves the certificate unpinned and the form usable', (
    tester,
  ) async {
    rejectCertificateOnStartupProbe();

    await pumpLogin(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(pins.pinFor(_host), isNull);
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('a sign-in refused over an untrusted certificate offers to '
      'trust it and then goes through', (tester) async {
    var attempts = 0;
    when(() => repo.login(any(), any())).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) {
        pins.evaluate(_host, _fingerprint);
        throw const NetworkException('certificate not trusted');
      }
      return user;
    });

    await pumpLogin(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'demo');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.textContaining(_fingerprint), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Trust'));
    await tester.pumpAndSettle();

    expect(pins.pinFor(_host), _fingerprint);
    expect(attempts, 2, reason: 'the sign-in is retried once trusted');
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('an ordinary sign-in failure does not raise a trust prompt', (
    tester,
  ) async {
    when(
      () => repo.login(any(), any()),
    ).thenThrow(const UnauthorizedException('Invalid username or password'));

    await pumpLogin(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'demo');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Trust'), findsNothing);
    expect(find.text('Invalid username or password'), findsOneWidget);
  });
}
