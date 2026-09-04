import 'dart:async';
import 'dart:io';

import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/outbox_ownership.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
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

  Future<void> pumpHost(WidgetTester tester, {required int userId}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionOutboxProvider.overrideWithValue(outbox),
          transactionsRepositoryProvider.overrideWithValue(repo),
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

  /// Taps a sheet button whose handler writes to disk, and waits for that
  /// write outside the fake clock.
  Future<void> tapAndWait(
    WidgetTester tester,
    Finder button,
    Future<bool> Function() done,
  ) async {
    await tester.runAsync(() async {
      await tester.tap(button);
      for (var i = 0; i < 200 && !await done(); i++) {
        await tester.pump(const Duration(milliseconds: 10));
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
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
}
