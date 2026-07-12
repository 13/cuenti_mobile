import 'package:cuentimobile/features/auth/ui/app_lock_observer.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
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
  @override
  AuthState build() => _state;
}

const _user = UserProfile(username: 'demo', email: 'd@x');

Widget _host({
  required AuthState authState,
  LocalAuthentication? authenticator,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(authState)),
    ],
    child: MaterialApp(
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
    'cold start shows child immediately when biometric is disabled',
    (tester) async {
      await tester.pumpWidget(
        _host(
          authState: const AuthState(
            user: _user,
            biometricEnabled: false,
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
