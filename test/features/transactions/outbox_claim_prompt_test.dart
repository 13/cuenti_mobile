import 'dart:async';
import 'dart:io';

import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/outbox_ownership.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transaction_sync.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/ui/outbox_claim_prompt.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

/// Supplies an already-initialized auth state synchronously, bypassing the
/// real controller's async `_init()` -- the same shape shell_screen_test
/// uses.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

/// Records how many times [drain] is asked for, without touching the
/// outbox or the network -- copied from shell_screen_test.dart, which
/// these tests share the shape of (a reclaim before the sheet decides
/// anything, followed by a drain if something came back).
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

/// Runs [promptForForeignOutbox] once, the way ShellScreen does.
class _Host extends ConsumerStatefulWidget {
  const _Host();

  @override
  ConsumerState<_Host> createState() => _HostState();
}

class _HostState extends ConsumerState<_Host> {
  @override
  void initState() {
    super.initState();
    // After the first frame, so there is a Navigator to put a sheet on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(promptForForeignOutbox(context, ref));
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('host'));
}

void main() {
  late Directory dir;
  late TransactionOutbox outbox;
  late MockTransactionsRepository repo;

  setUpAll(
    () => registerFallbackValue(
      Transaction(amount: 0, transactionDate: DateTime(2026)),
    ),
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('claim_prompt');
    outbox = TransactionOutbox(dir);
    repo = MockTransactionsRepository();
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenAnswer((i) async => i.positionalArguments.first as Transaction);
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// The account key a user with [id] gets on the default server -- the
  /// base URL an un-overridden ApiClient reports.
  String keyFor(int id) => accountKeyFor(
    ApiClient.defaultServerUrl,
    AuthState(
      user: UserProfile(id: id, username: 'demo'),
    ),
  )!;

  /// TransactionOutbox.add and setOwner do real disk I/O, which the
  /// widget-test clock never lets complete on its own; runAsync steps
  /// outside it, as settings_screen_test.dart does for the same store.
  Future<void> queue(String localId, {String? owner}) async {
    await outbox.add(
      PendingTransaction(
        localId: localId,
        operation: PendingOperation.create,
        transaction: Transaction(
          amount: 1,
          transactionDate: DateTime(2026, 9, 4),
        ),
        queuedAt: DateTime(2026, 9, 4, 10),
      ),
    );
    if (owner != null) await outbox.setOwner(owner);
  }

  Future<void> pumpHost(
    WidgetTester tester, {
    required int userId,
    TransactionSync? sync,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionOutboxProvider.overrideWithValue(outbox),
          transactionsRepositoryProvider.overrideWithValue(repo),
          if (sync != null) transactionSyncProvider.overrideWithValue(sync),
          authControllerProvider.overrideWith(
            () => _FakeAuthController(
              AuthState(
                user: UserProfile(id: userId, username: 'demo'),
                initialized: true,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: _Host(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Gives the real clock long enough that a disk write started by the
  /// last interaction would have finished. Used to prove one did *not*
  /// happen: without it the assertion would pass merely because nothing
  /// had had time to run yet.
  Future<void> settleOutsideTheFakeClock(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await tester.pumpAndSettle();
  }

  /// Waits, from inside [WidgetTester.runAsync], until [done] holds.
  ///
  /// A deadline rather than a fixed delay or an iteration bound -- copied
  /// in shape from `transactions_screen_test.dart`'s own `waitFor` -- so a
  /// regression that stops the write hangs on a message naming what it
  /// was waiting for, rather than the caller guessing how many turns are
  /// enough. Must be called from inside [WidgetTester.runAsync]: real
  /// disk I/O started by [pumpHost] does not progress once that escape
  /// hatch closes, so [done] has to become true before the caller leaves
  /// it, not after.
  Future<void> waitFor(
    WidgetTester tester,
    String what,
    Future<bool> Function() done, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!await done()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('timed out after ${timeout.inSeconds}s waiting for: $what');
      }
      await tester.pump(const Duration(milliseconds: 10));
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  /// Taps a sheet button whose handler writes to disk, and waits for that
  /// write outside the fake clock, on [waitFor]'s deadline rather than a
  /// bounded loop -- a wrong-value assertion on exhaustion would have named
  /// the value it read, not what it was actually waiting for.
  Future<void> tapAndWait(
    WidgetTester tester,
    Finder button,
    Future<bool> Function() done, {
    String what = 'the disk write the button triggers',
  }) async {
    await tester.runAsync(() async {
      await tester.tap(button);
      await waitFor(tester, what, done);
    });
    await tester.pumpAndSettle();
  }

  testWidgets('a foreign queue is named, and discarding empties it', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await queue('local-1');
      await queue('local-2', owner: keyFor(1));
    });
    await pumpHost(tester, userId: 2);

    expect(
      find.text('Unsent transactions from another account'),
      findsOneWidget,
    );
    expect(find.textContaining('2 unsent transactions were'), findsOneWidget);

    await tapAndWait(
      tester,
      find.widgetWithText(FilledButton, 'Discard'),
      () async => (await outbox.all()).isEmpty,
    );

    expect(await outbox.all(), isEmpty);
  });

  // The count in the message is of the root entries. A recursive clear()
  // would also destroy anything an earlier takeover set aside -- work
  // this sheet neither counted nor showed, discarded by a button the
  // user pressed about something else.
  testWidgets('discarding a foreign queue destroys what it counted, and '
      'not what it never showed', (tester) async {
    late Directory sidelined;
    await tester.runAsync(() async {
      await queue('local-1', owner: keyFor(1));
      sidelined = Directory('${dir.path}/.sidelined-earlier')..createSync();
      File('${sidelined.path}/set-aside.json').writeAsStringSync('{}');
    });
    await pumpHost(tester, userId: 2);

    expect(find.textContaining('1 unsent transaction was'), findsOneWidget);

    await tapAndWait(
      tester,
      find.widgetWithText(FilledButton, 'Discard'),
      () async => (await outbox.all()).isEmpty,
    );

    expect(await outbox.all(), isEmpty);
    expect(
      sidelined.listSync().whereType<File>(),
      hasLength(1),
      reason: 'the sheet counted one entry, so it may destroy one entry',
    );
  });

  testWidgets('keeping a foreign queue leaves it, still sealed', (
    tester,
  ) async {
    await tester.runAsync(() => queue('local-1', owner: keyFor(1)));
    await pumpHost(tester, userId: 2);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Keep'));
    await tester.pumpAndSettle();

    expect(await outbox.all(), hasLength(1));
    expect(await outbox.owner(), keyFor(1));
    expect(await ownedEntries(outbox, keyFor(2)), isEmpty);
  });

  testWidgets('a foreign queue does not blame the other account for the '
      'server address the user may have mistyped', (tester) async {
    await tester.runAsync(() => queue('local-1', owner: keyFor(1)));
    await pumpHost(tester, userId: 2);

    expect(find.textContaining('server address'), findsOneWidget);
  });

  testWidgets('discarding a foreign queue is the red one, since it is the '
      'one that destroys work', (tester) async {
    await tester.runAsync(() => queue('local-1', owner: keyFor(1)));
    await pumpHost(tester, userId: 2);

    final discard = find.widgetWithText(FilledButton, 'Discard');
    final scheme = Theme.of(tester.element(discard)).colorScheme;

    expect(
      tester
          .widget<FilledButton>(discard)
          .style
          ?.backgroundColor
          ?.resolve(const {}),
      scheme.error,
    );
  });

  testWidgets('an unclaimed queue offers to adopt it', (tester) async {
    // Still offline, so the drain that now follows the adoption leaves
    // the entry where it is: this test is about the queue becoming ours
    // and staying visible, and a successful send would empty it before
    // the assertion could see it. That the adoption sends at all is the
    // next test.
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenThrow(const NetworkException('Cannot connect to server'));
    await tester.runAsync(() => queue('local-1'));
    await pumpHost(tester, userId: 2);

    expect(
      find.text('Unsent transactions from an earlier version'),
      findsOneWidget,
    );
    expect(find.textContaining('demo'), findsOneWidget);

    await tapAndWait(
      tester,
      find.widgetWithText(FilledButton, 'Send as this account'),
      () async => await outbox.owner() != null,
    );

    expect(await outbox.owner(), keyFor(2));
    expect(await ownedEntries(outbox, keyFor(2)), hasLength(1));
  });

  // The button says "Send as this account". Claiming the queue and
  // stopping there sends nothing: the app-start drain ran long before the
  // sheet was answered, so the entries would sit unsent until some
  // unrelated gesture triggered a drain.
  testWidgets('adopting an unclaimed queue actually sends it', (tester) async {
    await tester.runAsync(() => queue('local-1'));
    await pumpHost(tester, userId: 2);

    await tapAndWait(
      tester,
      find.widgetWithText(FilledButton, 'Send as this account'),
      () async => (await outbox.all()).isEmpty,
    );

    verify(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).called(1);
    expect(
      await outbox.all(),
      isEmpty,
      reason: 'a delivered entry leaves the queue',
    );
  });

  testWidgets('adopting an unclaimed queue is not dressed up as a '
      'destructive act -- it is the safe answer', (tester) async {
    await tester.runAsync(() => queue('local-1'));
    await pumpHost(tester, userId: 2);

    final adopt = find.widgetWithText(FilledButton, 'Send as this account');
    final scheme = Theme.of(tester.element(adopt)).colorScheme;

    expect(
      tester
          .widget<FilledButton>(adopt)
          .style
          ?.backgroundColor
          ?.resolve(
            const {},
          ),
      isNot(scheme.error),
    );
  });

  testWidgets('declining to adopt an unclaimed queue writes nothing -- it '
      'is not offered as a discard', (tester) async {
    await tester.runAsync(() => queue('local-1'));
    await pumpHost(tester, userId: 2);

    expect(find.widgetWithText(OutlinedButton, 'Discard'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Not now'));
    await settleOutsideTheFakeClock(tester);

    expect(await outbox.all(), hasLength(1));
    expect(await outbox.owner(), isNull);
  });

  // A modal sheet is dismissible by a scrim tap, a drag or the back
  // button, and showConfirmSheet reports all three as a cancel -- so
  // whatever cancel does is what an accidental brush of the screen does.
  // On this branch that must be nothing at all: an implicit discard of
  // work the user has never been shown is the failure the sheet exists to
  // prevent.
  testWidgets('dismissing the upgrade sheet leaves the queue intact', (
    tester,
  ) async {
    await tester.runAsync(() => queue('local-1'));
    await pumpHost(tester, userId: 2);

    expect(
      find.text('Unsent transactions from an earlier version'),
      findsOneWidget,
    );

    // The scrim, well above the sheet at the bottom of the screen.
    await tester.tapAt(const Offset(20, 20));
    await settleOutsideTheFakeClock(tester);

    expect(
      find.text('Unsent transactions from an earlier version'),
      findsNothing,
      reason: 'the tap has to have actually dismissed the sheet',
    );
    expect(await outbox.all(), hasLength(1));
    expect(await outbox.owner(), isNull);
  });

  group('the count reads as a sentence, singular or plural', () {
    testWidgets('one foreign entry is one transaction', (tester) async {
      await tester.runAsync(() => queue('local-1', owner: keyFor(1)));
      await pumpHost(tester, userId: 2);

      expect(
        find.textContaining('1 unsent transaction was'),
        findsOneWidget,
        reason: '"1 unsent transactions were" is not a sentence',
      );
    });

    testWidgets('one unclaimed entry is one transaction', (tester) async {
      await tester.runAsync(() => queue('local-1'));
      await pumpHost(tester, userId: 2);

      expect(find.textContaining('1 unsent transaction was'), findsOneWidget);
    });

    testWidgets('two unclaimed entries are transactions', (tester) async {
      await tester.runAsync(() async {
        await queue('local-1');
        await queue('local-2');
      });
      await pumpHost(tester, userId: 2);

      expect(find.textContaining('2 unsent transactions were'), findsOneWidget);
    });
  });

  group('who the queue would be sent as', () {
    testWidgets('the sheet names the person, not the storage key', (
      tester,
    ) async {
      await tester.runAsync(() => queue('local-1'));
      await pumpHost(tester, userId: 2);

      expect(find.textContaining('Send it as demo?'), findsOneWidget);
      expect(
        find.textContaining(keyFor(2)),
        findsNothing,
        reason:
            'https://cuenti.muh#2 asks the user to accept an identity claim '
            'written as a URL and a database id they have never been shown',
      );
    });

    test('the default server is left out, since it distinguishes nobody', () {
      expect(
        accountDisplayName(
          ApiClient.defaultServerUrl,
          const AuthState(user: UserProfile(id: 2, username: 'demo')),
        ),
        'demo',
      );
    });

    test('another server is named, since there it is part of who you are', () {
      expect(
        accountDisplayName(
          'https://books.example',
          const AuthState(user: UserProfile(id: 2, username: 'demo')),
        ),
        'demo (books.example)',
      );
    });

    test('a profile with no username falls back to the id', () {
      expect(
        accountDisplayName(
          ApiClient.defaultServerUrl,
          const AuthState(user: UserProfile(id: 2)),
        ),
        '2',
      );
    });

    test('nobody signed in has no name, the way they have no key', () {
      expect(
        accountDisplayName(ApiClient.defaultServerUrl, const AuthState()),
        isNull,
      );
    });
  });

  testWidgets('our own queue asks nothing', (tester) async {
    await tester.runAsync(() => queue('local-1', owner: keyFor(2)));
    await pumpHost(tester, userId: 2);

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.textContaining('another account'), findsNothing);
    expect(find.textContaining('earlier version'), findsNothing);
  });

  testWidgets('an empty queue asks nothing', (tester) async {
    await pumpHost(tester, userId: 2);

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.textContaining('another account'), findsNothing);
  });

  testWidgets('a queue nobody can be signed in for is left alone', (
    tester,
  ) async {
    await tester.runAsync(() => queue('local-1', owner: keyFor(1)));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionOutboxProvider.overrideWithValue(outbox),
          authControllerProvider.overrideWith(
            () => _FakeAuthController(const AuthState(initialized: true)),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: _Host(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(await outbox.all(), hasLength(1));
  });

  group('reclaiming a set-aside queue at sign-in', () {
    testWidgets('a returning account gets its set-aside queue back without '
        'saving anything, and nothing is asked', (tester) async {
      // Account 2 wrote while account 1's queue was current, so 1's queue
      // was set aside. Now 2 has signed out and 1 is back: the root is
      // 2's, empty after 2's own sign-out cleared it.
      await tester.runAsync(() async {
        await queue('one-1');
        await outbox.setOwner(keyFor(1));
        await outbox.sideline();
      });
      // Sign-out of account 2 leaves an empty, unowned root.

      // The reclaim itself writes to disk (setOwner, then the restore's
      // renames), which -- like every other write in this file -- the
      // widget-test clock never lets complete on its own; the whole pump,
      // plus a wait for the write to actually land, has to run outside it.
      //
      // The wait has to be on what the assertions below actually read,
      // not on outbox.owner() alone: _reclaim sets the owner file
      // *before* it moves the entries back, and promptForForeignOutbox
      // does not ask for a drain until the whole reclaim -- owner plus
      // restore -- has resolved. A wait that ends on the owner file can
      // fire in the gap between those two steps: runAsync's callback
      // returns, its real-I/O escape hatch closes, and the restore and
      // the fire-and-forget drain that follows it are left to finish (or
      // not) back in the fake clock -- which is exactly the flake this
      // replaced: ownedEntries usually already reflected the restore by
      // the time the assertion ran, but sync.drains sometimes did not.
      final sync = _RecordingSync();
      await tester.runAsync(() async {
        await pumpHost(tester, userId: 1, sync: sync);
        await waitFor(
          tester,
          'the reclaimed entry to be owned again and the drain it '
          'triggers to have actually run',
          () async =>
              sync.drains > 0 &&
              (await ownedEntries(outbox, keyFor(1))).length == 1,
        );
      });
      await tester.pumpAndSettle();

      expect(find.textContaining('another account'), findsNothing);
      expect((await ownedEntries(outbox, keyFor(1))).single.localId, 'one-1');
      expect(
        sync.drains,
        greaterThan(0),
        reason: 'the app-start drain already ran; this has to send',
      );
    });

    testWidgets('a set-aside queue is not reclaimed into a root another '
        'account still owns, and that root is asked about', (tester) async {
      await tester.runAsync(() async {
        await queue('one-1');
        await outbox.setOwner(keyFor(1));
        await outbox.sideline();
        await queue('two-1');
        await outbox.setOwner(keyFor(2));
      });

      await pumpHost(tester, userId: 1);

      expect(find.textContaining('another account'), findsOneWidget);
      expect(await ownedEntries(outbox, keyFor(1)), isEmpty);
      expect(await outbox.sidelinedQueues(), hasLength(1));
    });
  });

  group('reclaiming once the sheet frees the root', () {
    // I3, the spec's headline story: the reclaim at the top of the
    // function and the sheet are mutually exclusive in one call -- the
    // reclaim ran first and found the root foreign, which is exactly why
    // the sheet is open at all. Discarding is what frees the root, and
    // that has to trigger a second reclaim in the same call, or account
    // 1's own set-aside queue stays set aside until something else
    // remounts this screen.
    testWidgets(
      'discarding a foreign queue reclaims our own set-aside queue and '
      'drains it, in the same prompt',
      (tester) async {
        await tester.runAsync(() async {
          await queue('one-1');
          await outbox.setOwner(keyFor(1));
          await outbox.sideline();
          await queue('two-1');
          await outbox.setOwner(keyFor(2));
        });

        final sync = _RecordingSync();
        await pumpHost(tester, userId: 1, sync: sync);

        expect(find.textContaining('another account'), findsOneWidget);

        await tapAndWait(
          tester,
          find.widgetWithText(FilledButton, 'Discard'),
          () async =>
              sync.drains > 0 &&
              (await ownedEntries(outbox, keyFor(1))).length == 1,
        );

        expect(
          (await ownedEntries(outbox, keyFor(1))).single.localId,
          'one-1',
        );
        expect(await outbox.owner(), keyFor(1));
        expect(
          sync.drains,
          greaterThan(0),
          reason:
              'a queue reclaimed this late already missed the '
              'app-start drain',
        );
      },
    );
  });
}
