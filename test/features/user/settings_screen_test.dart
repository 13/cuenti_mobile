import 'dart:async';
import 'dart:io';

import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/currencies/data/currencies_repository.dart';
import 'package:cuentimobile/features/transactions/data/outbox_ownership.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/user/data/user_repository.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/features/user/ui/settings_screen.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

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

/// Waits, from inside [WidgetTester.runAsync], until the confirm button's
/// handler has called [AuthController.logout].
///
/// A deadline rather than a fixed iteration bound: a regression that stops
/// the handler completing (the real disk I/O `discardEntries()` does,
/// ahead of `logout()` in the same handler) hangs on a
/// message naming what it was waiting for, rather than surfacing as a
/// wrong-value assertion that reads like the test itself is broken. Must
/// be called from inside [WidgetTester.runAsync] -- the real I/O the
/// handler does does not progress once that escape hatch closes.
Future<void> _waitForLogout(
  WidgetTester tester,
  _FakeAuthController auth, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (auth.logoutCalls == 0) {
    if (DateTime.now().isAfter(deadline)) {
      fail(
        'timed out after ${timeout.inSeconds}s waiting for logout() to be '
        'called',
      );
    }
    await tester.pump(const Duration(milliseconds: 10));
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late MockUserRepository userRepo;
  late MockCurrenciesRepository currenciesRepo;
  late _MemoryStorage storage;
  late Directory defaultOutboxDir;

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
    storage = _MemoryStorage();
    defaultOutboxDir = Directory.systemTemp.createTempSync(
      'settings_screen_outbox',
    );
    addTearDown(() => defaultOutboxDir.deleteSync(recursive: true));
    when(() => currenciesRepo.getAll()).thenAnswer((_) async => []);
    when(
      () => userRepo.updatePreferences(any()),
    ).thenAnswer((_) async => user);
  });

  Future<_FakeAuthController> pumpSettings(
    WidgetTester tester, {
    Locale? locale,
    // Tall surface: the screen is one long ListView and several assertions
    // target cards below the fold of a phone-sized viewport.
    UserProfile? profile = user,
    bool biometricEnabled = false,
    Completer<void>? logoutGate,
    Directory? outboxDir,
    bool outboxIsFallback = false,
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
          secureStorageProvider.overrideWithValue(storage),
          transactionOutboxProvider.overrideWithValue(
            TransactionOutbox(
              outboxDir ?? defaultOutboxDir,
              isFallback: outboxIsFallback,
            ),
          ),
        ],
        child: MaterialApp.router(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          routerConfig: router,
        ),
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

  group('signing out with unsent transactions', () {
    late Directory outboxDir;

    setUp(() => outboxDir = Directory.systemTemp.createTempSync('logout_ob'));
    tearDown(() => outboxDir.deleteSync(recursive: true));

    /// Claimed as well as written. Sign-out only counts and clears a queue
    /// this account owns, and in the app the claim is made for it: every
    /// queued write claims the queue. An entry put straight on disk with
    /// no owner is somebody's, but nobody can say whose, so it reads as
    /// empty -- which is the guard doing its job, not this test's subject.
    Future<void> queueOne() async {
      final outbox = TransactionOutbox(outboxDir);
      await outbox.setOwner(
        accountKeyFor(
          ApiClient.defaultServerUrl,
          const AuthState(user: user),
        )!,
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
    }

    Future<void> queueTwo() async {
      final outbox = TransactionOutbox(outboxDir);
      await outbox.setOwner(
        accountKeyFor(
          ApiClient.defaultServerUrl,
          const AuthState(user: user),
        )!,
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
      await outbox.add(
        PendingTransaction(
          localId: 'local-2',
          operation: PendingOperation.create,
          transaction: Transaction(
            amount: 56.78,
            transactionDate: DateTime(2026, 9, 4),
          ),
          queuedAt: DateTime(2026, 9, 4, 11),
        ),
      );
    }

    testWidgets('asks first, naming how many would be lost', (tester) async {
      // TransactionOutbox does real disk I/O, which the widget-test clock
      // (AutomatedTestWidgetsFlutterBinding runs the body inside FakeAsync)
      // never lets complete on its own -- awaiting it directly hangs
      // forever. runAsync steps outside that fake clock for the real
      // operation, matching the pattern transactions_screen_test.dart uses
      // for the same store.
      await tester.runAsync(queueOne);
      await pumpSettings(tester, outboxDir: outboxDir);

      final logout = find.widgetWithText(OutlinedButton, 'Logout');
      await tester.ensureVisible(logout);
      await tester.pumpAndSettle();
      await tester.tap(logout);
      await tester.pumpAndSettle();

      expect(find.text('Unsent transactions'), findsOneWidget);
      expect(
        find.textContaining('1 transaction has not reached the server'),
        findsOneWidget,
      );
    });

    testWidgets('pins the plural branch for more than one', (tester) async {
      await tester.runAsync(queueTwo);
      await pumpSettings(tester, outboxDir: outboxDir);

      final logout = find.widgetWithText(OutlinedButton, 'Logout');
      await tester.ensureVisible(logout);
      await tester.pumpAndSettle();
      await tester.tap(logout);
      await tester.pumpAndSettle();

      expect(find.text('Unsent transactions'), findsOneWidget);
      expect(
        find.textContaining('2 transactions have not reached'),
        findsOneWidget,
      );
    });

    testWidgets('cancelling leaves the queue and the session alone', (
      tester,
    ) async {
      await tester.runAsync(queueOne);
      final auth = await pumpSettings(tester, outboxDir: outboxDir);

      final logout = find.widgetWithText(OutlinedButton, 'Logout');
      await tester.ensureVisible(logout);
      await tester.pumpAndSettle();
      await tester.tap(logout);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(auth.logoutCalls, 0);
      // TransactionOutbox.all() only does synchronous file I/O internally,
      // so unlike add()/clear() it resolves fine without runAsync -- the
      // same reason transactions_screen_test.dart reads it bare too.
      expect(await TransactionOutbox(outboxDir).all(), hasLength(1));
    });

    testWidgets('an empty queue signs out without asking', (tester) async {
      final auth = await pumpSettings(tester, outboxDir: outboxDir);

      final logout = find.widgetWithText(OutlinedButton, 'Logout');
      await tester.ensureVisible(logout);
      await tester.pumpAndSettle();
      await tester.tap(logout);
      await tester.pumpAndSettle();

      expect(find.text('Unsent transactions'), findsNothing);
      expect(auth.logoutCalls, 1);
    });

    testWidgets('a queue that could not be read is still asked about, even '
        'though it looks empty', (tester) async {
      // The fallback store is empty because the real one could not be
      // opened -- not because there is nothing unsent. Signing out without
      // asking would discard whatever the real store holds.
      final auth = await pumpSettings(
        tester,
        outboxDir: outboxDir,
        outboxIsFallback: true,
      );

      final logout = find.widgetWithText(OutlinedButton, 'Logout');
      await tester.ensureVisible(logout);
      await tester.pumpAndSettle();
      await tester.tap(logout);
      await tester.pumpAndSettle();

      expect(find.textContaining('could not be read'), findsOneWidget);
      expect(auth.logoutCalls, 0);
    });

    testWidgets('a fallback store that can be read names its count, and '
        'confirming discards it', (tester) async {
      // A session that starts in fallback still queues into that store, and
      // the fallback directory is a stable path -- so it can hold entries.
      // Those entries ARE what sign-out clears, so the message has to be
      // the count-and-discard one, not the "will stay on this device" one.
      await tester.runAsync(queueOne);
      final auth = await pumpSettings(
        tester,
        outboxDir: outboxDir,
        outboxIsFallback: true,
      );

      final logout = find.widgetWithText(OutlinedButton, 'Logout');
      await tester.ensureVisible(logout);
      await tester.pumpAndSettle();
      await tester.tap(logout);
      await tester.pumpAndSettle();

      expect(find.textContaining('could not be read'), findsNothing);
      expect(
        find.textContaining('1 transaction has not reached the server'),
        findsOneWidget,
      );
      expect(find.textContaining('discard'), findsOneWidget);

      // And the promise the message makes is the one that is kept: see
      // 'confirming signs out and clears the outbox' for why this tap and
      // its wait both live inside runAsync.
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
        await _waitForLogout(tester, auth);
      });
      await tester.pumpAndSettle();

      expect(auth.logoutCalls, 1);
      expect(await TransactionOutbox(outboxDir).all(), isEmpty);
    });

    testWidgets(
      'a queue belonging to another account is neither counted nor cleared',
      (tester) async {
        // Both doors end here: a store the fallback left behind, and a
        // queue kept across an expired session. Signing out must not
        // count somebody else's entries in the warning, and must not
        // delete them either -- discarding a queue this account was never
        // shown would destroy work with no warning at all.
        await tester.runAsync(() async {
          final outbox = TransactionOutbox(outboxDir);
          await outbox.setOwner('https://cuenti.muh#999');
          await outbox.add(
            PendingTransaction(
              localId: 'local-theirs',
              operation: PendingOperation.create,
              transaction: Transaction(
                amount: 12.34,
                transactionDate: DateTime(2026, 9, 4),
              ),
              queuedAt: DateTime(2026, 9, 4, 10),
            ),
          );
        });
        final auth = await pumpSettings(tester, outboxDir: outboxDir);

        final logout = find.widgetWithText(OutlinedButton, 'Logout');
        await tester.ensureVisible(logout);
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await tester.tap(logout);
          await _waitForLogout(tester, auth);
        });
        await tester.pumpAndSettle();

        expect(
          find.text('Unsent transactions'),
          findsNothing,
          reason: "the count would be somebody else's",
        );
        expect(auth.logoutCalls, 1);
        expect(
          await TransactionOutbox(outboxDir).all(),
          hasLength(1),
          reason: 'left where it is, not discarded unannounced',
        );
      },
    );

    testWidgets('confirming signs out and clears the outbox', (tester) async {
      await tester.runAsync(queueOne);
      final auth = await pumpSettings(tester, outboxDir: outboxDir);

      final logout = find.widgetWithText(OutlinedButton, 'Logout');
      await tester.ensureVisible(logout);
      await tester.pumpAndSettle();
      await tester.tap(logout);
      await tester.pumpAndSettle();

      // Confirming triggers the outbox's real discardEntries() and then
      // logout() from inside the button's handler -- same reason the tap
      // and the wait for its effect both have to happen inside runAsync;
      // pumpAndSettle only tracks scheduled frames, not this unrelated
      // real I/O. Polling logoutCalls rather than the outbox itself avoids
      // racing this loop's own reads against discardEntries()'s file
      // deletes, and only flips once discardEntries() -- which sequences
      // before logout() in the handler -- has already run.
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
        await _waitForLogout(tester, auth);
      });
      await tester.pumpAndSettle();

      expect(auth.logoutCalls, 1);
      expect(await TransactionOutbox(outboxDir).all(), isEmpty);
    });

    // I4: before this branch a sidelined queue was unrecoverable anyway,
    // so signOut's recursive clear() destroying it alongside the owned
    // root cost nothing. Now reclaimSidelined can bring a set-aside queue
    // back, and clear() would delete it with no warning -- the warning
    // counted only what this account owns. discardEntries() must delete
    // exactly that and nothing beside it.
    testWidgets(
      "signing out empties the owned root and leaves a foreign account's "
      'sidelined queue intact',
      (tester) async {
        late Directory sidelined;
        await tester.runAsync(() async {
          // A foreign account's queue was set aside by an earlier claim.
          final outbox = TransactionOutbox(outboxDir);
          await outbox.setOwner('https://cuenti.muh#999');
          await outbox.add(
            PendingTransaction(
              localId: 'local-theirs',
              operation: PendingOperation.create,
              transaction: Transaction(
                amount: 1,
                transactionDate: DateTime(2026, 9, 4),
              ),
              queuedAt: DateTime(2026, 9, 4, 9),
            ),
          );
          await outbox.sideline();
          // This account claims the now-empty root and queues its own
          // entry.
          await queueOne();
          sidelined = (await outbox.sidelinedQueues()).single.directory;
        });
        final auth = await pumpSettings(tester, outboxDir: outboxDir);

        final logout = find.widgetWithText(OutlinedButton, 'Logout');
        await tester.ensureVisible(logout);
        await tester.pumpAndSettle();
        await tester.tap(logout);
        await tester.pumpAndSettle();

        // The warning's count is of the owned root alone -- the sidelined
        // queue is not this account's to be warned about.
        expect(
          find.textContaining('1 transaction has not reached the server'),
          findsOneWidget,
        );

        await tester.runAsync(() async {
          await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
          await _waitForLogout(tester, auth);
        });
        await tester.pumpAndSettle();

        expect(auth.logoutCalls, 1);
        expect(
          await TransactionOutbox(outboxDir).all(),
          isEmpty,
          reason: 'the owned root is exactly what the warning counted',
        );
        expect(
          sidelined.existsSync(),
          isTrue,
          reason:
              "the sidelined queue is not this session's to discard, and "
              'is now recoverable -- destroying it costs real data',
        );
        expect(
          sidelined.listSync().whereType<File>().map(
            (f) => f.uri.pathSegments.last,
          ),
          containsAll(['.owner.json']),
          reason: 'still attributable, not just present as an empty shell',
        );
      },
    );
  });

  testWidgets('the whole screen renders in German', (tester) async {
    await pumpSettings(tester, locale: const Locale('de'));

    expect(find.text('Dunkler Modus'), findsOneWidget);
    expect(find.text('Biometrische Entsperrung'), findsOneWidget);
    expect(find.text('Passwort ändern'), findsOneWidget);
    expect(find.text('Abmelden'), findsOneWidget);
    expect(find.text('Dark Mode'), findsNothing);
  });

  testWidgets('the whole screen renders in Italian', (tester) async {
    await pumpSettings(tester, locale: const Locale('it'));

    expect(find.text('Modalità scura'), findsOneWidget);
    expect(find.text('Sblocco biometrico'), findsOneWidget);
    expect(find.text('Cambia password'), findsOneWidget);
    expect(find.text('Esci'), findsOneWidget);
  });

  testWidgets('the locale picker offers only languages the app speaks', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(find.widgetWithText(ListTile, 'Locale'));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('Italiano'), findsOneWidget);
    expect(
      find.textContaining('fr-FR'),
      findsNothing,
      reason: 'French was offered but never translated',
    );
  });

  group('the automatic update check toggle', () {
    testWidgets('is on for a fresh install', (tester) async {
      await pumpSettings(tester);

      final tile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Automatic update check'),
      );
      expect(tile.value, isTrue);
    });

    testWidgets('turning it off is remembered', (tester) async {
      await pumpSettings(tester);

      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Automatic update check'),
      );
      await tester.pumpAndSettle();

      expect(storage.data['update_auto_check'], 'false');
      final tile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Automatic update check'),
      );
      expect(tile.value, isFalse);
    });

    testWidgets('reads back as off when it was switched off before', (
      tester,
    ) async {
      storage.data['update_auto_check'] = 'false';

      await pumpSettings(tester);

      final tile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Automatic update check'),
      );
      expect(tile.value, isFalse);
    });

    testWidgets('stays local rather than syncing to the account, which has '
        'no use for an Android updater setting', (tester) async {
      await pumpSettings(tester);

      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Automatic update check'),
      );
      await tester.pumpAndSettle();

      verifyNever(() => userRepo.updatePreferences(any()));
    });
  });

  testWidgets('the profile labels are translated, not left in English', (
    tester,
  ) async {
    await pumpSettings(tester, locale: const Locale('de'));

    expect(find.text('Benutzername'), findsOneWidget);
    expect(find.text('E-Mail'), findsOneWidget);
    expect(find.text('Username'), findsNothing);
  });
}
