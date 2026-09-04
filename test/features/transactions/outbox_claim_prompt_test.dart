import 'dart:async';
import 'dart:io';

import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/outbox_ownership.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/ui/outbox_claim_prompt.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  setUp(() {
    dir = Directory.systemTemp.createTempSync('claim_prompt');
    outbox = TransactionOutbox(dir);
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
    await tester.runAsync(() => queue('local-1', owner: keyFor(1)));
    await pumpHost(tester, userId: 2);

    expect(
      find.text('Unsent transactions from another account'),
      findsOneWidget,
    );
    expect(find.textContaining('1 unsent transactions'), findsOneWidget);

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
    await tester.runAsync(() => queue('local-1'));
    await pumpHost(tester, userId: 2);

    expect(
      find.text('Unsent transactions from an earlier version'),
      findsOneWidget,
    );
    expect(find.textContaining(keyFor(2)), findsOneWidget);

    await tapAndWait(
      tester,
      find.widgetWithText(FilledButton, 'Send as this account'),
      () async => await outbox.owner() != null,
    );

    expect(await outbox.owner(), keyFor(2));
    expect(await ownedEntries(outbox, keyFor(2)), hasLength(1));
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

  testWidgets('declining to adopt an unclaimed queue discards it', (
    tester,
  ) async {
    await tester.runAsync(() => queue('local-1'));
    await pumpHost(tester, userId: 2);

    await tapAndWait(
      tester,
      find.widgetWithText(OutlinedButton, 'Discard'),
      () async => (await outbox.all()).isEmpty,
    );

    expect(await outbox.all(), isEmpty);
    expect(await outbox.owner(), isNull);
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
