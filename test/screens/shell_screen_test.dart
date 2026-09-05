import 'dart:async';
import 'dart:io';

import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/api/offline_cache_interceptor.dart';
import 'package:cuentimobile/core/api/response_cache.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/scheduled/data/scheduled_repository.dart';
import 'package:cuentimobile/features/scheduled/domain/scheduled_transaction.dart';
import 'package:cuentimobile/features/transactions/data/outbox_ownership.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transaction_sync.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/screens/shell_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/misc.dart' show Override;

class _MockScheduledRepository extends Mock implements ScheduledRepository {}

/// PrivacyMode reads this on every shell build; without an override it hits
/// the real flutter_secure_storage plugin channel, which throws
/// MissingPluginException the moment anything (runAsync, in the logout
/// group below) actually lets that pending real call run.
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

/// Records how many times [drain] is asked for, without touching the
/// outbox or the network -- these tests are about *when* a drain is
/// triggered, not what it does.
class _RecordingSync implements TransactionSync {
  int drains = 0;

  @override
  Future<int> drain() async {
    drains++;
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Supplies an already-initialized auth state synchronously, bypassing the
/// real controller's async `_init()`.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this._state, {this.logoutGate});
  final AuthState _state;

  /// Pushes a new state, the way a profile refresh does mid-session.
  /// Anything watching the whole AuthState rebuilds on it.
  ///
  /// A method rather than a setter because a setter would want a matching
  /// getter (avoid_setters_without_getters) that nothing here would call.
  // ignore: use_setters_to_change_properties
  void emit(AuthState next) => state = next;

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

/// The account the Logout group is signed in as, and the one its queue is
/// claimed under.
const _drawerAuthState = AuthState(
  user: UserProfile(username: 'demo', email: 'd@x', firstName: 'Demo'),
);

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
    List<Override> overrides = const [],
    OfflineCacheInterceptor? offlineCache,
    Directory? outboxDir,
  }) async {
    final dir =
        outboxDir ?? Directory.systemTemp.createTempSync('shell_outbox');
    if (outboxDir == null) addTearDown(() => dir.deleteSync(recursive: true));
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
          transactionOutboxProvider.overrideWithValue(TransactionOutbox(dir)),
          secureStorageProvider.overrideWithValue(_MemoryStorage()),
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
          if (offlineCache != null)
            apiClientProvider.overrideWithValue(
              ApiClient(
                const SecureStorage(),
                dioOverride: Dio(),
                offlineCache: offlineCache,
              ),
            ),
          ...overrides,
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

  group("the drawer's Logout, with unsent transactions", () {
    late Directory outboxDir;

    setUp(
      () => outboxDir = Directory.systemTemp.createTempSync('shell_logout_ob'),
    );
    tearDown(() => outboxDir.deleteSync(recursive: true));

    /// TransactionOutbox.add does real disk I/O, which the widget-test
    /// clock never lets complete on its own; runAsync steps outside it.
    ///
    /// Claimed as well as written, for the account the drawer is signed in
    /// as: sign-out counts and clears only a queue this account owns, and
    /// in the app a queued write makes that claim for it.
    Future<void> queueOne(WidgetTester tester) => tester.runAsync(() async {
      final outbox = TransactionOutbox(outboxDir);
      await outbox.setOwner(
        accountKeyFor(ApiClient.defaultServerUrl, _drawerAuthState)!,
      );
      await outbox.add(
        PendingTransaction(
          localId: 'local-1',
          operation: PendingOperation.create,
          transaction: Transaction(
            amount: 12.34,
            transactionDate: DateTime(2026, 9, 4),
          ),
          queuedAt: DateTime(2026, 9, 4, 10),
        ),
      );
    });

    Future<_FakeAuthController> openDrawerAndTapLogout(
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final auth = _FakeAuthController(_drawerAuthState);
      await pumpShell(tester, controller: auth, outboxDir: outboxDir);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      return auth;
    }

    testWidgets('asks first, naming how many would be lost', (tester) async {
      await queueOne(tester);

      final auth = await openDrawerAndTapLogout(tester);

      expect(find.text('Unsent transactions'), findsOneWidget);
      expect(
        auth.logoutCalls,
        0,
        reason:
            'the queue would otherwise survive into the next account, and '
            "that session's drain would post it into their books",
      );
    });

    testWidgets('cancelling leaves the queue and the session alone', (
      tester,
    ) async {
      await queueOne(tester);

      final auth = await openDrawerAndTapLogout(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(auth.logoutCalls, 0);
      expect(find.text('login page'), findsNothing);
      // all() is synchronous inside, unlike add()/clear().
      expect(await TransactionOutbox(outboxDir).all(), hasLength(1));
    });

    testWidgets('an empty queue signs out without asking', (tester) async {
      final auth = await openDrawerAndTapLogout(tester);

      expect(find.text('Unsent transactions'), findsNothing);
      expect(auth.logoutCalls, 1);
    });

    testWidgets('confirming signs out and clears the queue', (tester) async {
      await queueOne(tester);
      final auth = await openDrawerAndTapLogout(tester);

      // discardEntries() and logout() both run from inside the sheet's
      // handler, so the tap and the wait for its effect happen inside
      // runAsync -- the real disk I/O does not progress once that escape
      // hatch closes.
      //
      // A deadline rather than an iteration bound: if a regression stops
      // the handler completing, this says so, instead of falling through
      // to a wrong-value assertion that reads like the test is broken.
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (auth.logoutCalls == 0) {
          if (DateTime.now().isAfter(deadline)) {
            fail('timed out after 20s waiting for the sign-out to complete');
          }
          await tester.pump(const Duration(milliseconds: 10));
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();

      expect(auth.logoutCalls, 1);
      expect(await TransactionOutbox(outboxDir).all(), isEmpty);
    });
  });

  group("the queue that is not this account's", () {
    late Directory outboxDir;

    setUp(
      () => outboxDir = Directory.systemTemp.createTempSync('shell_claim_ob'),
    );
    tearDown(() {
      // The discard path deletes and recreates the directory; a test that
      // took it leaves nothing to remove.
      if (outboxDir.existsSync()) outboxDir.deleteSync(recursive: true);
    });

    /// Signed in, and past `ApiClient.init()` -- which is what settles the
    /// base URL the account key is built from.
    const signedIn = AuthState(
      user: UserProfile(
        id: 2,
        username: 'demo',
        email: 'd@x',
        firstName: 'Demo',
      ),
      initialized: true,
    );

    const foreignTitle = 'Unsent transactions from another account';

    Future<void> queueOwnedBy(WidgetTester tester, String owner) =>
        tester.runAsync(() async {
          final outbox = TransactionOutbox(outboxDir);
          await outbox.add(
            PendingTransaction(
              localId: 'local-1',
              operation: PendingOperation.create,
              transaction: Transaction(
                amount: 12.34,
                transactionDate: DateTime(2026, 9, 4),
              ),
              queuedAt: DateTime(2026, 9, 4, 10),
            ),
          );
          await outbox.setOwner(owner);
        });

    testWidgets('the shell asks about it on arrival, since ShellScreen is '
        'where both a fresh login and a restored session land', (
      tester,
    ) async {
      await queueOwnedBy(tester, '${ApiClient.defaultServerUrl}#99');

      await pumpShell(
        tester,
        controller: _FakeAuthController(signedIn),
        outboxDir: outboxDir,
      );

      expect(find.text(foreignTitle), findsOneWidget);
    });

    testWidgets('it is asked once, not again every time the auth state '
        'changes underneath the shell', (tester) async {
      await queueOwnedBy(tester, '${ApiClient.defaultServerUrl}#99');
      final auth = _FakeAuthController(signedIn);

      await pumpShell(tester, controller: auth, outboxDir: outboxDir);
      expect(find.text(foreignTitle), findsOneWidget);

      // A profile refresh, an arriving flag -- anything that re-emits the
      // auth state while the sheet is still up.
      auth.emit(
        signedIn.copyWith(user: signedIn.user!.copyWith(firstName: 'Ada')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(foreignTitle),
        findsOneWidget,
        reason:
            'a second sheet stacked on the first asks the same question '
            'twice and buries the answer to the first',
      );
    });

    testWidgets("this account's own queue is not asked about", (tester) async {
      await queueOwnedBy(
        tester,
        accountKeyFor(ApiClient.defaultServerUrl, signedIn)!,
      );

      await pumpShell(
        tester,
        controller: _FakeAuthController(signedIn),
        outboxDir: outboxDir,
      );

      expect(find.text(foreignTitle), findsNothing);
    });
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

  group('the drawer avatar initial', () {
    Future<void> pumpWithProfile(WidgetTester tester, UserProfile user) async {
      await pumpShell(
        tester,
        controller: _FakeAuthController(AuthState(user: user)),
      );
    }

    testWidgets('uses the first letter of the first name', (tester) async {
      await pumpWithProfile(
        tester,
        const UserProfile(username: 'demo', email: 'd@x', firstName: 'Ada'),
      );
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('a profile with no first name falls back instead of '
        'crashing the whole shell on an empty string', (tester) async {
      await pumpWithProfile(
        tester,
        const UserProfile(username: 'demo', email: 'd@x'),
      );

      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('U'), findsOneWidget);
    });

    testWidgets('a first name of only spaces falls back too', (tester) async {
      await pumpWithProfile(
        tester,
        const UserProfile(username: 'demo', email: 'd@x', firstName: '   '),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('sending the outbox when the connection returns', () {
    testWidgets('the queue is sent when the connection comes back', (
      tester,
    ) async {
      final sync = _RecordingSync();
      final interceptor = OfflineCacheInterceptor(
        ResponseCache(Directory.systemTemp.createTempSync('shell_cache')),
      );
      await pumpShell(
        tester,
        overrides: [transactionSyncProvider.overrideWithValue(sync)],
        offlineCache: interceptor,
      );

      interceptor.stale.value = true;
      await tester.pump();
      final before = sync.drains;

      interceptor.stale.value = false;
      await tester.pumpAndSettle();

      expect(sync.drains, before + 1);
    });

    testWidgets('a connection that stays down does not drain on every '
        'frame', (tester) async {
      final sync = _RecordingSync();
      final interceptor = OfflineCacheInterceptor(
        ResponseCache(Directory.systemTemp.createTempSync('shell_cache2')),
      );
      await pumpShell(
        tester,
        overrides: [transactionSyncProvider.overrideWithValue(sync)],
        offlineCache: interceptor,
      );

      interceptor.stale.value = true;
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(sync.drains, 0);
    });

    testWidgets('going online for the first time, with no prior offline '
        'spell, drains nothing -- only an actual reconnection does', (
      tester,
    ) async {
      final sync = _RecordingSync();
      final interceptor = OfflineCacheInterceptor(
        ResponseCache(Directory.systemTemp.createTempSync('shell_cache3')),
      );

      await pumpShell(
        tester,
        overrides: [transactionSyncProvider.overrideWithValue(sync)],
        offlineCache: interceptor,
      );

      expect(sync.drains, 0);
    });
  });
}
