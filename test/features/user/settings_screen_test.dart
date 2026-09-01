import 'dart:async';

import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/currencies/data/currencies_repository.dart';
import 'package:cuentimobile/features/user/data/user_repository.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/features/user/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockCurrenciesRepository extends Mock implements CurrenciesRepository {}

/// Supplies an already-initialized auth state synchronously, bypassing the
/// real controller's async init and its secure-storage reads.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this._state, {this.logoutGate});
  final AuthState _state;
  final Completer<void>? logoutGate;

  int logoutCalls = 0;
  int refreshCalls = 0;
  final List<bool> biometricWrites = [];

  @override
  AuthState build() => _state;

  @override
  String get serverUrl => 'https://cuenti.test';

  @override
  Future<void> refreshProfile() async => refreshCalls++;

  @override
  Future<void> setBiometricEnabled({required bool enabled}) async =>
      biometricWrites.add(enabled);

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutGate != null) await logoutGate!.future;
  }
}

void main() {
  late MockUserRepository userRepo;
  late MockCurrenciesRepository currenciesRepo;

  const user = UserProfile(
    id: 1,
    username: 'demo',
    email: 'demo@cuenti.test',
    firstName: 'Demo',
    lastName: 'User',
  );

  setUpAll(() => registerFallbackValue(<String, Object?>{}));

  setUp(() {
    userRepo = MockUserRepository();
    currenciesRepo = MockCurrenciesRepository();
    when(() => currenciesRepo.getAll()).thenAnswer((_) async => []);
    when(
      () => userRepo.updatePreferences(any()),
    ).thenAnswer((_) async => user);
  });

  Future<_FakeAuthController> pumpSettings(
    WidgetTester tester, {
    // Tall surface: the screen is one long ListView and several assertions
    // target cards below the fold of a phone-sized viewport.
    UserProfile? profile = user,
    bool biometricEnabled = false,
    Completer<void>? logoutGate,
  }) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = _FakeAuthController(
      AuthState(user: profile, biometricEnabled: biometricEnabled),
      logoutGate: logoutGate,
    );
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: SettingsScreen()),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Text('login page'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          userRepositoryProvider.overrideWithValue(userRepo),
          currenciesRepositoryProvider.overrideWithValue(currenciesRepo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('shows the signed-in profile', (tester) async {
    await pumpSettings(tester);

    expect(find.text('demo'), findsOneWidget);
    expect(find.text('Demo User'), findsOneWidget);
    expect(find.text('demo@cuenti.test'), findsOneWidget);
  });

  testWidgets('says so when there is no session rather than rendering an '
      'empty form', (tester) async {
    await pumpSettings(tester, profile: null);

    expect(find.text('Not logged in'), findsOneWidget);
    expect(find.text('Change Password'), findsNothing);
  });

  testWidgets('toggling Dark Mode persists it and refetches the profile', (
    tester,
  ) async {
    final auth = await pumpSettings(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Dark Mode'));
    await tester.pumpAndSettle();

    final sent =
        verify(
              () => userRepo.updatePreferences(captureAny()),
            ).captured.single
            as Map<String, dynamic>;
    expect(sent, {'darkMode': false});
    expect(
      auth.refreshCalls,
      1,
      reason:
          'the switch renders from the profile, so it has to be refetched '
          'or it snaps back to the stale value',
    );
  });

  testWidgets('toggling API Access persists it', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, 'API Access'));
    await tester.pumpAndSettle();

    final sent =
        verify(
              () => userRepo.updatePreferences(captureAny()),
            ).captured.single
            as Map<String, dynamic>;
    expect(sent, {'apiEnabled': true});
  });

  testWidgets('toggling Biometric Unlock goes through the auth controller', (
    tester,
  ) async {
    final auth = await pumpSettings(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Biometric Unlock'));
    await tester.pumpAndSettle();

    expect(auth.biometricWrites, [true]);
    verifyNever(() => userRepo.updatePreferences(any()));
  });

  testWidgets('hides the admin section from a non-admin', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Administration'), findsNothing);
  });

  testWidgets('shows the admin section to an admin', (tester) async {
    await pumpSettings(
      tester,
      profile: user.copyWith(roles: const {'ROLE_ADMIN'}),
    );

    expect(find.text('Administration'), findsOneWidget);
  });

  testWidgets('logout clears the session before navigating to login', (
    tester,
  ) async {
    final gate = Completer<void>();
    final auth = await pumpSettings(tester, logoutGate: gate);

    final logout = find.widgetWithText(OutlinedButton, 'Logout');
    await tester.ensureVisible(logout);
    await tester.pumpAndSettle();
    await tester.tap(logout);
    await tester.pumpAndSettle();

    expect(auth.logoutCalls, 1);
    expect(
      find.text('login page'),
      findsNothing,
      reason: 'the token clear is still in flight',
    );

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('login page'), findsOneWidget);
  });
}
