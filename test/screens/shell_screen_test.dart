import 'dart:async';

import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/scheduled/data/scheduled_repository.dart';
import 'package:cuentimobile/features/scheduled/domain/scheduled_transaction.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/screens/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockScheduledRepository extends Mock implements ScheduledRepository {}

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
  /// Scheduled entries the shell reads for the overdue badge. Stubbed empty
  /// by default so the existing tests see no badge at all.
  late _MockScheduledRepository scheduledRepo;

  setUp(() {
    scheduledRepo = _MockScheduledRepository();
    when(scheduledRepo.getAll).thenAnswer((_) async => []);
  });

  ScheduledTransaction dueOn(DateTime date, {bool enabled = true}) =>
      ScheduledTransaction(
        id: date.millisecondsSinceEpoch,
        amount: 10,
        nextOccurrence: date,
        enabled: enabled,
      );

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
          scheduledRepositoryProvider.overrideWithValue(scheduledRepo),
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
        child: MaterialApp.router(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          routerConfig: router,
        ),
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

  group('the overdue badge on Geplant', () {
    /// Tall enough that the whole drawer renders without scrolling.
    void useTallSurface(WidgetTester tester) {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    final overdue = DateTime.now().subtract(const Duration(days: 3));
    final upcoming = DateTime.now().add(const Duration(days: 3));

    testWidgets('counts the overdue entries next to the drawer item', (
      tester,
    ) async {
      useTallSurface(tester);
      when(scheduledRepo.getAll).thenAnswer(
        (_) async => [dueOn(overdue), dueOn(overdue), dueOn(upcoming)],
      );

      await pumpShell(tester);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      expect(find.byType(Badge), findsWidgets);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows nothing when nothing is overdue', (tester) async {
      useTallSurface(tester);
      when(scheduledRepo.getAll).thenAnswer((_) async => [dueOn(upcoming)]);

      await pumpShell(tester);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('marks the closed menu button too, since a badge inside a '
        'shut drawer alerts nobody', (tester) async {
      when(scheduledRepo.getAll).thenAnswer((_) async => [dueOn(overdue)]);

      await pumpShell(tester);

      expect(
        find.descendant(
          of: find.byTooltip('Open navigation menu'),
          matching: find.byType(Badge),
        ),
        findsOneWidget,
      );
    });

    testWidgets('leaves the menu button alone when nothing is overdue', (
      tester,
    ) async {
      await pumpShell(tester);

      expect(
        find.descendant(
          of: find.byTooltip('Open navigation menu'),
          matching: find.byType(Badge),
        ),
        findsNothing,
      );
    });

    testWidgets('a paused entry raises no alert', (tester) async {
      when(scheduledRepo.getAll).thenAnswer(
        (_) async => [dueOn(overdue, enabled: false)],
      );

      await pumpShell(tester);

      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('the drawer still opens when the fetch failed, without the '
        'shell taking the error', (tester) async {
      when(scheduledRepo.getAll).thenThrow(Exception('offline'));

      await pumpShell(tester);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Badge), findsNothing);
    });
  });
}
