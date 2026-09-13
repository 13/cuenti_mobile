import 'package:cuentimobile/features/auth/ui/app_lock_observer.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

/// Bypasses AuthController's async `_init()` so tests can supply an
/// already-initialized state synchronously, exactly as it would look the
/// instant the real controller finishes restoring a session.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this._state);
  final AuthState _state;
  bool loggedOut = false;
  @override
  AuthState build() => _state;
  @override
  Future<void> logout() async {
    loggedOut = true;
    state = state.copyWith(user: null);
  }
}

const _user = UserProfile(username: 'demo', email: 'd@x');

Widget _host({
  required AuthState authState,
  LocalAuthentication? authenticator,
  _FakeAuthController? controller,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        () => controller ?? _FakeAuthController(authState),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: AppLockObserver(
        authenticator: authenticator,
        child: const Text('Home'),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  testWidgets(
    'cold start locks when a restored session is logged in with biometrics enabled',
    (tester) async {
      final authenticator = MockLocalAuthentication();
      when(
        () => authenticator.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        _host(
          authState: const AuthState(
            user: _user,
            biometricEnabled: true,
            initialized: true,
          ),
          authenticator: authenticator,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cuenti is Locked'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    },
  );

  testWidgets(
    'fails closed: an authenticator that cannot run keeps the app locked',
    (tester) async {
      // Regression: a sensor locked out after too many attempts (or no
      // biometrics enrolled any more) made authenticate() throw, and the
      // catch unlocked the app.
      final authenticator = MockLocalAuthentication();
      when(
        () => authenticator.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenThrow(Exception('LockedOut'));

      await tester.pumpWidget(
        _host(
          authState: const AuthState(
            user: _user,
            biometricEnabled: true,
            initialized: true,
          ),
          authenticator: authenticator,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cuenti is Locked'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.textContaining('not available right now'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    },
  );

  testWidgets(
    'signing out from the lock screen logs out and drops the lock',
    (tester) async {
      final authenticator = MockLocalAuthentication();
      when(
        () => authenticator.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenThrow(Exception('NotAvailable'));
      final controller = _FakeAuthController(
        const AuthState(user: _user, biometricEnabled: true, initialized: true),
      );

      await tester.pumpWidget(
        _host(
          authState: const AuthState(),
          authenticator: authenticator,
          controller: controller,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(controller.loggedOut, isTrue);
      expect(find.text('Cuenti is Locked'), findsNothing);
    },
  );

  testWidgets(
    'a successful retry after an unavailable authenticator unlocks',
    (tester) async {
      final authenticator = MockLocalAuthentication();
      var attempts = 0;
      when(
        () => authenticator.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) throw Exception('Temporarily unavailable');
        return true;
      });

      await tester.pumpWidget(
        _host(
          authState: const AuthState(
            user: _user,
            biometricEnabled: true,
            initialized: true,
          ),
          authenticator: authenticator,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cuenti is Locked'), findsOneWidget);

      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    },
  );

  testWidgets(
    'cold start shows child immediately when biometric is disabled',
    (tester) async {
      await tester.pumpWidget(
        _host(
          authState: const AuthState(
            user: _user,
            initialized: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Cuenti is Locked'), findsNothing);
    },
  );

  testWidgets(
    'cold start shows child immediately when logged out, even with biometric enabled',
    (tester) async {
      await tester.pumpWidget(
        _host(
          authState: const AuthState(
            biometricEnabled: true,
            initialized: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Cuenti is Locked'), findsNothing);
    },
  );
}
