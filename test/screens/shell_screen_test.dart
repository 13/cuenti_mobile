import 'dart:async';

import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/screens/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Supplies an already-initialized auth state synchronously, bypassing the
/// real controller's async `_init()`.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this._state, {this.logoutGate});
  final AuthState _state;

  /// When set, [logout] blocks on this until the test completes it, so a
  /// test can observe what the UI does while the sign-out is still running.
  final Completer<void>? logoutGate;
  int logoutCalls = 0;

  @override
  AuthState build() => _state;

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutGate != null) await logoutGate!.future;
  }
}

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    _FakeAuthController? controller,
  }) async {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const Text('login page'),
        ),
        ShellRoute(
          builder: (context, state, child) => ShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const Text('dash'),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () =>
                controller ??
                _FakeAuthController(
                  const AuthState(
                    user: UserProfile(
                      username: 'demo',
                      email: 'd@x',
                      firstName: 'Demo',
                    ),
                  ),
                ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('drawer lists Vehicles in the General section', (tester) async {
    // Tall surface so the whole drawer renders without scrolling.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpShell(tester);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    final vehiclesY = tester.getTopLeft(find.text('Vehicles')).dy;
    final managementY = tester.getTopLeft(find.text('Management')).dy;
    final generalY = tester.getTopLeft(find.text('General')).dy;

    expect(vehiclesY, greaterThan(generalY));
    expect(
      vehiclesY,
      lessThan(managementY),
      reason:
          'Vehicles must appear in the General section, '
          'above the Management header',
    );
  });

  testWidgets('logout clears the session before navigating to login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final gate = Completer<void>();
    final auth = _FakeAuthController(
      const AuthState(
        user: UserProfile(username: 'demo', email: 'd@x', firstName: 'Demo'),
      ),
      logoutGate: gate,
    );

    await pumpShell(tester, controller: auth);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(auth.logoutCalls, 1);
    expect(
      find.text('login page'),
      findsNothing,
      reason:
          'the token clear and saved-credential wipe are still in flight; '
          'landing on the login screen first leaves them racing a fresh login',
    );

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('login page'), findsOneWidget);
  });
}
