import 'dart:io';

import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/outbox_ownership.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_split.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

/// Hands back a settled auth state synchronously, so tests that exercise
/// `_enqueue`'s ownership claim don't kick off the real controller's
/// startup work (a platform-channel token read, a live profile fetch) that
/// a plain unit test has no business triggering.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

const _signedInAuthState = AuthState(
  user: UserProfile(id: 42, username: 'ben'),
);

/// The key the containers below claim their queue under -- none of them
/// override the API client provider, so the base URL is the default one.
///
/// Reads are owner-gated now, so an entry a test writes straight to disk
/// is invisible to the controller unless the queue is claimed for the same
/// account the container is signed in as. In the app the claim comes free:
/// `_enqueue` makes it on every queued write. A test that skips `save()`
/// and writes the file itself has to make it explicitly, or it is testing
/// the guard rather than the merge it means to test.
final String _ourAccountKey = accountKeyFor(
  ApiClient.defaultServerUrl,
  _signedInAuthState,
)!;

void main() {
  late MockTransactionsRepository repo;
  late ProviderContainer container;
  late Directory defaultOutboxDir;

  Transaction tx(int id) => Transaction(
    id: id,
    amount: 10,
    transactionDate: DateTime(2026, 1, id),
  );

  setUpAll(() {
    registerFallbackValue(
      Transaction(amount: 0, transactionDate: DateTime(2026)),
    );
    registerFallbackValue(const TransactionFilter());
  });

  setUp(() {
    repo = MockTransactionsRepository();
    // build()/loadMore() now read the outbox on every page fetch to merge
    // pending writes in, so every test needs one -- an empty directory
    // behaves as an empty outbox and leaves the pre-existing tests' server
    // data untouched aside from the date sort mergePending always applies.
    defaultOutboxDir = Directory.systemTemp.createTempSync(
      'ctrl_outbox_default',
    );
    container = ProviderContainer(
      overrides: [
        transactionsRepositoryProvider.overrideWithValue(repo),
        transactionOutboxProvider.overrideWithValue(
          TransactionOutbox(defaultOutboxDir),
        ),
        // build() reads the auth state on every page fetch now, to know
        // whose queue it may merge. Without this the real controller is
        // built and starts the platform-channel token read and profile
        // fetch these unit tests have no business triggering -- the same
        // reason containerWithOutbox() overrides it below.
        authControllerProvider.overrideWith(
          () => _FakeAuthController(_signedInAuthState),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() => defaultOutboxDir.deleteSync(recursive: true));
  });

  test(
    'build loads page 0 and flags hasMore when more than one page',
    () async {
      when(() => repo.getPage()).thenAnswer(
        (_) async => TransactionPage(
          content: [tx(1), tx(2)],
          page: 0,
          size: 50,
          totalElements: 60,
          totalPages: 2,
        ),
      );

      final state = await container.read(
        transactionsControllerProvider().future,
      );

      // mergePending sorts every merged page by date, newest first, so
      // the server's own order does not determine the result.
      expect(state.items, [tx(2), tx(1)]);
      expect(state.nextPage, 1);
      expect(state.hasMore, isTrue);
    },
  );

  test('build flags hasMore false for a single page', () async {
    when(() => repo.getPage()).thenAnswer(
      (_) async => TransactionPage(
        content: [tx(1)],
        page: 0,
        size: 50,
        totalElements: 1,
        totalPages: 1,
      ),
    );

    final state = await container.read(transactionsControllerProvider().future);

    expect(state.hasMore, isFalse);
  });

  test('loadMore appends items and flips hasMore false on last page', () async {
    when(() => repo.getPage()).thenAnswer(
      (_) async => TransactionPage(
        content: [tx(1)],
        page: 0,
        size: 50,
        totalElements: 2,
        totalPages: 2,
      ),
    );
    when(() => repo.getPage(page: 1)).thenAnswer(
      (_) async => TransactionPage(
        content: [tx(2)],
        page: 1,
        size: 50,
        totalElements: 2,
        totalPages: 2,
      ),
    );

    await container.read(transactionsControllerProvider().future);
    await container.read(transactionsControllerProvider().notifier).loadMore();

    final state = container.read(transactionsControllerProvider()).value!;
    // Newest first: mergePending re-sorts the whole merged page by date.
    expect(state.items, [tx(2), tx(1)]);
    expect(state.hasMore, isFalse);
    expect(state.loadingMore, isFalse);
  });

  test(
    'loadMore dedupes ids when the backend repeats rows across pages',
    () async {
      // Backends without a stable total order (pre-v2.10.1) can hand back
      // rows from the previous page — loadMore must not duplicate them.
      when(() => repo.getPage()).thenAnswer(
        (_) async => TransactionPage(
          content: [tx(1), tx(2)],
          page: 0,
          size: 50,
          totalElements: 3,
          totalPages: 2,
        ),
      );
      when(() => repo.getPage(page: 1)).thenAnswer(
        (_) async => TransactionPage(
          content: [tx(2), tx(3)],
          page: 1,
          size: 50,
          totalElements: 3,
          totalPages: 2,
        ),
      );

      await container.read(transactionsControllerProvider().future);
      await container
          .read(transactionsControllerProvider().notifier)
          .loadMore();

      final state = container.read(transactionsControllerProvider()).value!;
      // Newest first: mergePending re-sorts the whole merged page by date.
      expect(state.items, [tx(3), tx(2), tx(1)]);
      expect(state.items.map((t) => t.id).toSet().length, state.items.length);
    },
  );

  test(
    'dedupes ids repeated WITHIN a single page (build and loadMore)',
    () async {
      // A single page can also repeat a row internally — both the initial
      // build (page 0) and loadMore must collapse it to one item.
      when(() => repo.getPage()).thenAnswer(
        (_) async => TransactionPage(
          content: [tx(1), tx(1), tx(2)],
          page: 0,
          size: 50,
          totalElements: 4,
          totalPages: 2,
        ),
      );
      when(() => repo.getPage(page: 1)).thenAnswer(
        (_) async => TransactionPage(
          content: [tx(3), tx(3)],
          page: 1,
          size: 50,
          totalElements: 4,
          totalPages: 2,
        ),
      );

      final built = await container.read(
        transactionsControllerProvider().future,
      );
      // Newest first: mergePending re-sorts the whole merged page by date.
      expect(built.items, [tx(2), tx(1)]);

      await container
          .read(transactionsControllerProvider().notifier)
          .loadMore();

      final state = container.read(transactionsControllerProvider()).value!;
      expect(state.items, [tx(3), tx(2), tx(1)]);
      expect(state.items.map((t) => t.id).toSet().length, state.items.length);
    },
  );

  test('loadMore no-ops when hasMore is false', () async {
    when(() => repo.getPage()).thenAnswer(
      (_) async => TransactionPage(
        content: [tx(1)],
        page: 0,
        size: 50,
        totalElements: 1,
        totalPages: 1,
      ),
    );

    await container.read(transactionsControllerProvider().future);
    await container.read(transactionsControllerProvider().notifier).loadMore();

    verifyNever(() => repo.getPage(page: 1));
  });

  test('delete is optimistic and reverts on failure', () async {
    when(() => repo.getPage()).thenAnswer(
      (_) async => TransactionPage(
        content: [tx(1), tx(2)],
        page: 0,
        size: 50,
        totalElements: 2,
        totalPages: 1,
      ),
    );
    await container.read(transactionsControllerProvider().future);
    when(() => repo.delete(1)).thenThrow(const ServerException('boom'));

    await expectLater(
      container.read(transactionsControllerProvider().notifier).delete(1),
      throwsA(isA<ServerException>()),
    );
    // Newest first: mergePending re-sorts the whole merged page by date.
    expect(container.read(transactionsControllerProvider()).value!.items, [
      tx(2),
      tx(1),
    ]);
  });

  test(
    'an outbox failure after an accepted delete does not put the row back',
    () async {
      // The server has already accepted the delete. An outbox problem
      // while tidying up a stale queued edit must not be reported as a
      // failed delete, and must not restore a row that is gone.
      when(() => repo.getPage()).thenAnswer(
        (_) async => TransactionPage(
          content: [tx(7)],
          page: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
        ),
      );
      when(() => repo.delete(7)).thenAnswer((_) async {});
      final outboxDir = Directory.systemTemp.createTempSync(
        'ctrl_outbox_broken',
      );
      addTearDown(() => outboxDir.deleteSync(recursive: true));
      final outbox = _BrokenReadOutbox(outboxDir);
      final brokenContainer = ProviderContainer(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(repo),
          transactionOutboxProvider.overrideWithValue(outbox),
          // Its own container, so it needs the auth override the file's
          // setUp makes: delete() reaches the outbox through _queuedIdFor,
          // which reads the auth state to know whose queue it may look in.
          // Without this the real controller is built and its init() fails
          // on the uninitialized binding -- caught, but printed into the
          // test output.
          authControllerProvider.overrideWith(
            () => _FakeAuthController(_signedInAuthState),
          ),
        ],
      );
      addTearDown(brokenContainer.dispose);
      await brokenContainer.read(transactionsControllerProvider().future);
      // Only now, after the initial load already succeeded, does the
      // outbox start failing -- mirroring a storage problem that shows up
      // mid-session rather than one that would have kept the screen from
      // loading in the first place.
      outbox.broken = true;

      final outcome = await brokenContainer
          .read(transactionsControllerProvider().notifier)
          .delete(7);

      expect(outcome, SaveOutcome.sent);
      expect(
        brokenContainer
            .read(transactionsControllerProvider())
            .value!
            .items
            .map((t) => t.id),
        isNot(contains(7)),
      );
    },
  );

  test('controller is keyed by accountId family', () async {
    when(
      () => repo.getPage(filter: const TransactionFilter(accountId: 3)),
    ).thenAnswer(
      (_) async => TransactionPage(
        content: [tx(1)],
        page: 0,
        size: 50,
        totalElements: 1,
        totalPages: 1,
      ),
    );
    when(() => repo.getPage()).thenAnswer(
      (_) async => TransactionPage(
        content: [tx(2)],
        page: 0,
        size: 50,
        totalElements: 1,
        totalPages: 1,
      ),
    );

    final withAccount = await container.read(
      transactionsControllerProvider(
        filter: const TransactionFilter(accountId: 3),
      ).future,
    );
    final all = await container.read(transactionsControllerProvider().future);

    expect(withAccount.items, [tx(1)]);
    expect(all.items, [tx(2)]);
  });

  test('filter change creates a distinct family instance', () async {
    const filterA = TransactionFilter(type: 'EXPENSE');
    const filterB = TransactionFilter(type: 'INCOME');
    when(() => repo.getPage(filter: filterA)).thenAnswer(
      (_) async => TransactionPage(
        content: [tx(1)],
        page: 0,
        size: 50,
        totalElements: 1,
        totalPages: 1,
      ),
    );
    when(() => repo.getPage(filter: filterB)).thenAnswer(
      (_) async => TransactionPage(
        content: [tx(2)],
        page: 0,
        size: 50,
        totalElements: 1,
        totalPages: 1,
      ),
    );

    final stateA = await container.read(
      transactionsControllerProvider(filter: filterA).future,
    );
    final stateB = await container.read(
      transactionsControllerProvider(filter: filterB).future,
    );

    expect(stateA.items, [tx(1)]);
    expect(stateB.items, [tx(2)]);
    verify(() => repo.getPage(filter: filterA)).called(1);
    verify(() => repo.getPage(filter: filterB)).called(1);
  });

  group('saving without a connection', () {
    late Directory outboxDir;

    setUp(() {
      outboxDir = Directory.systemTemp.createTempSync('ctrl_outbox');
      when(() => repo.getPage()).thenAnswer(
        (_) async => const TransactionPage(
          content: [],
          page: 0,
          size: 50,
          totalElements: 0,
          totalPages: 1,
        ),
      );
    });
    tearDown(() => outboxDir.deleteSync(recursive: true));

    ProviderContainer containerWithOutbox({
      AuthState auth = _signedInAuthState,
    }) {
      final container = ProviderContainer(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(repo),
          transactionOutboxProvider.overrideWithValue(
            TransactionOutbox(outboxDir),
          ),
          // Overridden here as well as in the file's setUp, because this
          // helper builds its own container: _enqueue reads this to decide
          // who to claim the queue for, and every read of the outbox reads
          // it to decide whose queue may be seen. Named as a parameter
          // rather than fixed, which the setUp's copy cannot do -- it
          // defaults signed in, and a test passes an unauthenticated state
          // to check the no-claim path.
          authControllerProvider.overrideWith(() => _FakeAuthController(auth)),
        ],
      );
      addTearDown(container.dispose);
      // Mirrors a widget's ref.watch: without a listener, the autoDispose
      // provider can be torn down between the real file-I/O awaits inside
      // save()/_enqueue(), which then throws when it tries to invalidate
      // itself.
      container.listen(transactionsControllerProvider(), (_, _) {});
      return container;
    }

    test('a connection failure queues the transaction and says so', () async {
      when(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      ).thenThrow(const NetworkException('Cannot connect to server'));
      final container = containerWithOutbox();
      await container.read(transactionsControllerProvider().future);

      final outcome = await container
          .read(transactionsControllerProvider().notifier)
          .save(Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)));

      expect(outcome, SaveOutcome.queued);
      final queued = await container.read(transactionOutboxProvider).all();
      expect(queued.single.transaction.amount, 5);
      expect(queued.single.operation, PendingOperation.create);
    });

    test(
      'a server refusal is not queued: the server answered, so deferring '
      'the bad news helps nobody',
      () async {
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const ValidationException('Amount is required'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);

        await expectLater(
          container
              .read(transactionsControllerProvider().notifier)
              .save(
                Transaction(amount: 0, transactionDate: DateTime(2026, 9, 4)),
              ),
          throwsA(isA<ValidationException>()),
        );
        expect(await container.read(transactionOutboxProvider).all(), isEmpty);
      },
    );

    test('a successful save queues nothing', () async {
      when(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      ).thenAnswer((i) async => i.positionalArguments.first as Transaction);
      final container = containerWithOutbox();
      await container.read(transactionsControllerProvider().future);

      final outcome = await container
          .read(transactionsControllerProvider().notifier)
          .save(Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)));

      expect(outcome, SaveOutcome.sent);
      expect(await container.read(transactionOutboxProvider).all(), isEmpty);
    });

    test(
      'editing something still queued rewrites that entry rather than '
      'queueing an update against a transaction the server never saw',
      () async {
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);
        final notifier = container.read(
          transactionsControllerProvider().notifier,
        );

        await notifier.save(
          Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)),
        );
        final localId = (await container.read(transactionOutboxProvider).all())
            .single
            .localId;
        await notifier.save(
          Transaction(amount: 9, transactionDate: DateTime(2026, 9, 4)),
          localId: localId,
        );

        final queued = await container.read(transactionOutboxProvider).all();
        expect(queued, hasLength(1));
        expect(queued.single.transaction.amount, 9);
        expect(queued.single.operation, PendingOperation.create);
      },
    );

    test(
      'a queued edit that touched splits records that, not the default',
      () async {
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);
        final notifier = container.read(
          transactionsControllerProvider().notifier,
        );

        await notifier.save(
          Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)),
          splitsTouched: true,
        );

        final queued = await container.read(transactionOutboxProvider).all();
        expect(queued.single.splitsTouched, isTrue);
      },
    );

    test(
      're-editing a queued entry keeps the splits flag it was recorded '
      'with: the dialog starts every edit at splitsTouched false, and the '
      'payload still carries the splits',
      () async {
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);
        final notifier = container.read(
          transactionsControllerProvider().notifier,
        );

        await notifier.save(
          Transaction(
            amount: 5,
            transactionDate: DateTime(2026, 9, 4),
            splits: const [TransactionSplit(amount: 5, categoryId: 3)],
          ),
          splitsTouched: true,
        );
        final localId = (await container.read(transactionOutboxProvider).all())
            .single
            .localId;

        // Re-opening that entry and changing only the amount: the dialog
        // re-initialises its splits from the transaction but starts the
        // flag at false.
        await notifier.save(
          Transaction(
            amount: 9,
            transactionDate: DateTime(2026, 9, 4),
            splits: const [TransactionSplit(amount: 9, categoryId: 3)],
          ),
          localId: localId,
        );

        final queued = await container.read(transactionOutboxProvider).all();
        expect(queued.single.transaction.splits, hasLength(1));
        expect(
          queued.single.splitsTouched,
          isTrue,
          reason:
              'the repository strips the splits key under a false flag, so '
              'the split would never be sent at all',
        );
      },
    );

    test(
      'a queued edit that did not touch splits records that too',
      () async {
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);
        final notifier = container.read(
          transactionsControllerProvider().notifier,
        );

        await notifier.save(
          Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)),
        );

        final queued = await container.read(transactionOutboxProvider).all();
        expect(queued.single.splitsTouched, isFalse);
      },
    );

    test(
      'two saves in quick succession leave two entries, not one colliding '
      'on the same local id',
      () async {
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);
        final notifier = container.read(
          transactionsControllerProvider().notifier,
        );

        await Future.wait([
          notifier.save(
            Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)),
          ),
          notifier.save(
            Transaction(amount: 6, transactionDate: DateTime(2026, 9, 4)),
          ),
        ]);

        final queued = await container.read(transactionOutboxProvider).all();
        expect(queued, hasLength(2));
        expect(queued.map((e) => e.localId).toSet(), hasLength(2));
        expect(queued.map((e) => e.transaction.amount).toSet(), {5, 6});
      },
    );

    test('a connection failure on delete queues the delete', () async {
      when(() => repo.getPage()).thenAnswer(
        (_) async => TransactionPage(
          content: [tx(1)],
          page: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
        ),
      );
      when(() => repo.delete(1)).thenThrow(
        const NetworkException('Cannot connect to server'),
      );
      final container = containerWithOutbox();
      await container.read(transactionsControllerProvider().future);

      final outcome = await container
          .read(transactionsControllerProvider().notifier)
          .delete(1);

      expect(outcome, SaveOutcome.queued);
      final queued = await container.read(transactionOutboxProvider).all();
      expect(queued.single.operation, PendingOperation.delete);
      expect(queued.single.transaction.id, 1);
    });

    test(
      'a successful resave through save(..., localId:) clears the queued '
      'entry, so a later drain does not send it twice',
      () async {
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);
        final notifier = container.read(
          transactionsControllerProvider().notifier,
        );

        await notifier.save(
          Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)),
        );
        final localId = (await container.read(transactionOutboxProvider).all())
            .single
            .localId;

        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenAnswer((i) async => i.positionalArguments.first as Transaction);
        final outcome = await notifier.save(
          Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)),
          localId: localId,
        );

        expect(outcome, SaveOutcome.sent);
        expect(await container.read(transactionOutboxProvider).all(), isEmpty);
      },
    );

    test(
      'deleting something already queued as an edit replaces that entry '
      'with the delete, rather than leaving both queued for the same row',
      () async {
        when(() => repo.getPage()).thenAnswer(
          (_) async => TransactionPage(
            content: [tx(7)],
            page: 0,
            size: 50,
            totalElements: 1,
            totalPages: 1,
          ),
        );
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        when(() => repo.delete(7)).thenThrow(
          const NetworkException('Cannot connect to server'),
        );
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);
        final notifier = container.read(
          transactionsControllerProvider().notifier,
        );

        await notifier.save(
          Transaction(
            id: 7,
            amount: 9,
            transactionDate: DateTime(2026, 9, 4),
          ),
        );
        await notifier.delete(7);

        final queued = await container.read(transactionOutboxProvider).all();
        expect(queued, hasLength(1));
        expect(queued.single.transaction.id, 7);
        expect(queued.single.operation, PendingOperation.delete);
      },
    );

    test(
      'a delete that reaches the server clears the edit still queued for '
      'that row, which would otherwise PUT a transaction that is gone',
      () async {
        when(() => repo.getPage()).thenAnswer(
          (_) async => TransactionPage(
            content: [tx(7)],
            page: 0,
            size: 50,
            totalElements: 1,
            totalPages: 1,
          ),
        );
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);
        final notifier = container.read(
          transactionsControllerProvider().notifier,
        );

        await notifier.save(
          Transaction(id: 7, amount: 9, transactionDate: DateTime(2026, 9, 4)),
        );
        expect(
          await container.read(transactionOutboxProvider).all(),
          hasLength(1),
        );

        // The connection is back, and the row is deleted outright.
        when(() => repo.delete(7)).thenAnswer((_) async {});
        expect(await notifier.delete(7), SaveOutcome.sent);

        expect(
          await container.read(transactionOutboxProvider).all(),
          isEmpty,
          reason:
              'that entry would be PUT to a deleted id, take a 404 and be '
              'marked refused -- and mergePending can never show it, since '
              'it only overlays updates onto rows the server still has',
        );
      },
    );

    test(
      'a pending create that does not match the active filter stays out of '
      'the list: a filtered list showing rows that do not match it is a lie '
      'about the data',
      () async {
        const filter = TransactionFilter(accountId: 999, search: 'zzz');
        when(() => repo.getPage(filter: filter)).thenAnswer(
          (_) async => const TransactionPage(
            content: [],
            page: 0,
            size: 50,
            totalElements: 0,
            totalPages: 1,
          ),
        );
        final container = ProviderContainer(
          overrides: [
            transactionsRepositoryProvider.overrideWithValue(repo),
            transactionOutboxProvider.overrideWithValue(
              TransactionOutbox(outboxDir),
            ),
            authControllerProvider.overrideWith(
              () => _FakeAuthController(_signedInAuthState),
            ),
          ],
        );
        addTearDown(container.dispose);
        // Ours, so what keeps the row out of the list is the filter and
        // nothing else: an unclaimed queue reads as empty and this would
        // pass without the filter ever being consulted.
        await container
            .read(transactionOutboxProvider)
            .setOwner(
              _ourAccountKey,
            );
        await container
            .read(transactionOutboxProvider)
            .add(
              PendingTransaction(
                localId: 'local-1',
                operation: PendingOperation.create,
                transaction: Transaction(
                  amount: 5,
                  fromAccountId: 1,
                  payee: 'Aldi',
                  transactionDate: DateTime(2026, 9, 4),
                ),
                queuedAt: DateTime(2026, 9, 4, 10),
              ),
            );

        final state = await container.read(
          transactionsControllerProvider(filter: filter).future,
        );

        expect(state.items, isEmpty);
      },
    );

    test('a pending create the filter does match is still shown, so an '
        'entry made offline is not lost behind the account it belongs '
        'to', () async {
      const filter = TransactionFilter(accountId: 1);
      when(() => repo.getPage(filter: filter)).thenAnswer(
        (_) async => const TransactionPage(
          content: [],
          page: 0,
          size: 50,
          totalElements: 0,
          totalPages: 1,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(repo),
          transactionOutboxProvider.overrideWithValue(
            TransactionOutbox(outboxDir),
          ),
          authControllerProvider.overrideWith(
            () => _FakeAuthController(_signedInAuthState),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(transactionOutboxProvider).setOwner(_ourAccountKey);
      await container
          .read(transactionOutboxProvider)
          .add(
            PendingTransaction(
              localId: 'local-1',
              operation: PendingOperation.create,
              transaction: Transaction(
                amount: 5,
                fromAccountId: 1,
                payee: 'Aldi',
                transactionDate: DateTime(2026, 9, 4),
              ),
              queuedAt: DateTime(2026, 9, 4, 10),
            ),
          );

      final state = await container.read(
        transactionsControllerProvider(filter: filter).future,
      );

      expect(state.items.single.payee, 'Aldi');
    });

    test('a queued create appears in the list, in date order', () async {
      when(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      ).thenThrow(const NetworkException('Cannot connect to server'));
      when(
        () => repo.getPage(
          page: any(named: 'page'),
          size: any(named: 'size'),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer(
        (_) async => TransactionPage(
          content: [
            Transaction(
              id: 1,
              amount: 10,
              transactionDate: DateTime(2026, 9),
            ),
          ],
          page: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
        ),
      );
      final container = containerWithOutbox();
      await container.read(transactionsControllerProvider().future);

      await container
          .read(transactionsControllerProvider().notifier)
          .save(Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)));

      final state = container.read(transactionsControllerProvider()).value!;
      expect(state.items.map((t) => t.amount), [5, 10]);
      expect(state.pending, hasLength(1));
    });

    test('deleting a row that already has an edit queued replaces it, so '
        'the server is not sent an update and then a delete', () async {
      when(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      ).thenThrow(const NetworkException('Cannot connect to server'));
      when(
        () => repo.delete(any()),
      ).thenThrow(const NetworkException('Cannot connect to server'));
      when(
        () => repo.getPage(
          page: any(named: 'page'),
          size: any(named: 'size'),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer(
        (_) async => TransactionPage(
          content: [
            Transaction(
              id: 1,
              amount: 10,
              transactionDate: DateTime(2026, 9),
            ),
          ],
          page: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
        ),
      );
      final container = containerWithOutbox();
      await container.read(transactionsControllerProvider().future);
      final notifier = container.read(
        transactionsControllerProvider().notifier,
      );

      await notifier.save(
        Transaction(id: 1, amount: 99, transactionDate: DateTime(2026, 9)),
      );
      await notifier.delete(1);

      final queued = await container.read(transactionOutboxProvider).all();
      expect(queued, hasLength(1));
      expect(queued.single.operation, PendingOperation.delete);
    });

    test('a queued delete hides the row it removes', () async {
      when(
        () => repo.delete(any()),
      ).thenThrow(const NetworkException('Cannot connect to server'));
      when(
        () => repo.getPage(
          page: any(named: 'page'),
          size: any(named: 'size'),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer(
        (_) async => TransactionPage(
          content: [
            Transaction(
              id: 1,
              amount: 10,
              transactionDate: DateTime(2026, 9),
            ),
          ],
          page: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
        ),
      );
      final container = containerWithOutbox();
      await container.read(transactionsControllerProvider().future);

      await container.read(transactionsControllerProvider().notifier).delete(1);

      expect(
        container.read(transactionsControllerProvider()).value!.items,
        isEmpty,
      );
    });

    test(
      'a delete queued in an earlier session hides its row on a fresh '
      'build, not only through the optimistic removal delete() itself does',
      () async {
        // delete() removes the row from state immediately regardless of
        // mergePending, so that path alone can't prove the merge excludes
        // deleted rows. Queuing the delete directly and building fresh --
        // the way the app starts up with an outbox left over from before --
        // isolates mergePending's own contribution.
        when(() => repo.getPage()).thenAnswer(
          (_) async => TransactionPage(
            content: [
              Transaction(
                id: 1,
                amount: 10,
                transactionDate: DateTime(2026, 9),
              ),
            ],
            page: 0,
            size: 50,
            totalElements: 1,
            totalPages: 1,
          ),
        );
        // Written before the container exists: containerWithOutbox() starts
        // build() the moment it listens, so writing through the provider
        // afterwards would race that first read of the outbox. Claimed for
        // the same account, the way `_enqueue` would have claimed it in
        // the earlier session this entry is meant to come from.
        await TransactionOutbox(outboxDir).setOwner(_ourAccountKey);
        await TransactionOutbox(outboxDir).add(
          PendingTransaction(
            localId: 'local-predelete-1',
            operation: PendingOperation.delete,
            transaction: Transaction(
              id: 1,
              amount: 10,
              transactionDate: DateTime(2026, 9),
            ),
            queuedAt: DateTime(2026, 9, 2),
          ),
        );
        final container = containerWithOutbox();

        final state = await container.read(
          transactionsControllerProvider().future,
        );

        expect(state.items, isEmpty);
        expect(state.pending, hasLength(1));
      },
    );

    test(
      'a queued create is placed by date, not merely appended or prepended',
      () async {
        // Three orderings would each look plausible from a bug and must be
        // told apart: append puts the queued row last, prepend puts it
        // first, and only true date order puts it in the middle here.
        when(() => repo.getPage()).thenAnswer(
          (_) async => TransactionPage(
            content: [
              Transaction(
                id: 1,
                amount: 100,
                transactionDate: DateTime(2026, 9, 10),
              ),
              Transaction(
                id: 2,
                amount: 200,
                transactionDate: DateTime(2026, 9),
              ),
            ],
            page: 0,
            size: 50,
            totalElements: 2,
            totalPages: 1,
          ),
        );
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);

        await container
            .read(transactionsControllerProvider().notifier)
            .save(
              Transaction(amount: 50, transactionDate: DateTime(2026, 9, 5)),
            );

        final state = container.read(transactionsControllerProvider()).value!;
        expect(state.items.map((t) => t.amount), [100, 50, 200]);
      },
    );

    test(
      'a queued update overlays the server row with the queued values',
      () async {
        when(() => repo.getPage()).thenAnswer(
          (_) async => TransactionPage(
            content: [
              Transaction(
                id: 1,
                amount: 10,
                transactionDate: DateTime(2026, 9),
              ),
            ],
            page: 0,
            size: 50,
            totalElements: 1,
            totalPages: 1,
          ),
        );
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);

        await container
            .read(transactionsControllerProvider().notifier)
            .save(
              Transaction(
                id: 1,
                amount: 999,
                transactionDate: DateTime(2026, 9),
              ),
            );

        final state = container.read(transactionsControllerProvider()).value!;
        // The row is still the server's (same id, still just one row) but
        // carries the value the user queued, not the value the server had.
        expect(state.items, hasLength(1));
        expect(state.items.single.amount, 999);
      },
    );

    test(
      'a refresh (a fresh build, not the save that queued the write) still '
      'shows a pending write',
      () async {
        when(() => repo.getPage()).thenAnswer(
          (_) async => TransactionPage(
            content: [
              Transaction(
                id: 1,
                amount: 10,
                transactionDate: DateTime(2026, 9),
              ),
            ],
            page: 0,
            size: 50,
            totalElements: 1,
            totalPages: 1,
          ),
        );
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);
        expect(
          container.read(transactionsControllerProvider()).value!.items,
          hasLength(1),
        );

        // Queued directly, bypassing save(), so this exercises the rebuild
        // path on its own rather than the invalidateSelf inside save().
        // Bypassing save() also bypasses the claim `_enqueue` makes, so
        // the queue is claimed here instead -- unclaimed, it reads as
        // empty and the rebuild would have nothing to fold in.
        await container
            .read(transactionOutboxProvider)
            .setOwner(
              _ourAccountKey,
            );
        await container
            .read(transactionOutboxProvider)
            .add(
              PendingTransaction(
                localId: 'local-refresh-1',
                operation: PendingOperation.create,
                transaction: Transaction(
                  amount: 42,
                  transactionDate: DateTime(2026, 9, 3),
                ),
                queuedAt: DateTime(2026, 9, 3),
              ),
            );

        container.invalidate(transactionsControllerProvider());
        final refreshed = await container.read(
          transactionsControllerProvider().future,
        );

        expect(refreshed.items.map((t) => t.amount), [42, 10]);
        expect(refreshed.pending, hasLength(1));
      },
    );

    test(
      'loadMore folds in a pending write too, without duplicating it',
      () async {
        when(() => repo.getPage()).thenAnswer(
          (_) async => TransactionPage(
            content: [
              Transaction(
                id: 1,
                amount: 100,
                transactionDate: DateTime(2026, 9, 20),
              ),
            ],
            page: 0,
            size: 50,
            totalElements: 2,
            totalPages: 2,
          ),
        );
        when(() => repo.getPage(page: 1)).thenAnswer(
          (_) async => TransactionPage(
            content: [
              Transaction(
                id: 2,
                amount: 50,
                transactionDate: DateTime(2026, 9, 10),
              ),
            ],
            page: 1,
            size: 50,
            totalElements: 2,
            totalPages: 2,
          ),
        );
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);

        // Queued directly so it is already reflected before loadMore runs,
        // and claimed here because that bypasses `_enqueue`'s own claim.
        await container
            .read(transactionOutboxProvider)
            .setOwner(
              _ourAccountKey,
            );
        await container
            .read(transactionOutboxProvider)
            .add(
              PendingTransaction(
                localId: 'local-loadmore-1',
                operation: PendingOperation.create,
                transaction: Transaction(
                  amount: 77,
                  transactionDate: DateTime(2026, 9, 15),
                ),
                queuedAt: DateTime(2026, 9, 15),
              ),
            );
        container.invalidate(transactionsControllerProvider());
        await container.read(transactionsControllerProvider().future);

        await container
            .read(transactionsControllerProvider().notifier)
            .loadMore();

        final state = container.read(transactionsControllerProvider()).value!;
        expect(state.items.map((t) => t.amount), [100, 77, 50]);
        // The pending create must appear exactly once, not once from the
        // page it was already folded into and again from the outbox.
        expect(
          state.items.where((t) => t.amount == 77),
          hasLength(1),
        );
      },
    );

    test(
      'a queued save returns even though the list cannot refresh: offline, '
      'the page fetch a self-invalidation triggers fails too',
      () async {
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);
        // Reads are offline as well now. That is the only state an offline
        // save can actually happen in, and the one where waiting on a
        // rebuild waits forever.
        when(() => repo.getPage()).thenThrow(
          const NetworkException('Cannot connect to server'),
        );

        final outcome = await container
            .read(transactionsControllerProvider().notifier)
            .save(
              Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)),
            )
            .timeout(const Duration(seconds: 3));

        expect(outcome, SaveOutcome.queued);
      },
    );

    test(
      'a queued save is folded into the list from the outbox, without a '
      'page fetch that would fail anyway',
      () async {
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);
        when(() => repo.getPage()).thenThrow(
          const NetworkException('Cannot connect to server'),
        );

        await container
            .read(transactionsControllerProvider().notifier)
            .save(
              Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)),
            )
            .timeout(const Duration(seconds: 3));

        final state = container.read(transactionsControllerProvider()).value!;
        expect(state.pending, hasLength(1));
        expect(state.items.map((t) => t.amount), [5]);
      },
    );

    test(
      'queueing a save claims the queue for the signed-in account',
      () async {
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);

        await container
            .read(transactionsControllerProvider().notifier)
            .save(
              Transaction(amount: 12.34, transactionDate: DateTime(2026, 9, 4)),
            );

        expect(
          await container.read(transactionOutboxProvider).owner(),
          isNotNull,
        );
      },
    );

    // Was "a second save does not re-claim an already owned queue": it
    // asserted that saving as the signed-in account left a queue owned by
    // 'someone-else' untouched -- the old claimIfUnowned semantics, where
    // any existing owner (whoever it was) was left alone. Task 4b makes
    // that the wrong answer on purpose: a foreign queue is now taken over
    // rather than kept, so the entry just saved is not sealed away from
    // the person who typed it. Rewritten below to assert the new
    // behaviour, with a queued entry present so the takeover -- and the
    // loss of what was there -- is actually observable.
    test(
      'a save into a foreign queue takes the queue over, and the entry '
      'just saved is visible to the account that saved it',
      () async {
        await TransactionOutbox(outboxDir).setOwner('account-a');
        await TransactionOutbox(outboxDir).add(
          PendingTransaction(
            localId: 'local-theirs',
            operation: PendingOperation.create,
            transaction: Transaction(
              amount: 1,
              payee: 'Aldi',
              transactionDate: DateTime(2026, 9),
            ),
            queuedAt: DateTime(2026, 9, 1, 10),
          ),
        );
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);

        await container
            .read(transactionsControllerProvider().notifier)
            .save(
              Transaction(amount: 12.34, transactionDate: DateTime(2026, 9, 4)),
            );

        final outbox = container.read(transactionOutboxProvider);
        final all = await outbox.all();
        expect(all, hasLength(1));
        expect(all.single.transaction.amount, 12.34);
        expect(await outbox.owner(), _ourAccountKey);
        expect(
          await ownedEntries(outbox, _ourAccountKey),
          all,
          reason: 'the point of the takeover: b can see what b just saved',
        );
      },
    );

    // Task 4b: claimForWriting resolves the queue's ownership before
    // _enqueue reads or writes it, instead of after -- see
    // outbox_ownership.dart's doc comment on claimForWriting for why the
    // old order (claim after add) leaves holes.
    group("a write resolves the queue's ownership first", () {
      // Was 'an edit on an unclaimed queue keeps its sticky operation,
      // queuedAt and splitsTouched, instead of losing them to a lookup
      // that a sealed unclaimed queue fails' -- it queued the entry with
      // no owner. An unclaimed queue is now set aside by the write rather
      // than adopted by it (see the test below), so on that premise the
      // lookup is *meant* to find nothing and the sticky fields are meant
      // to be lost. The behaviour this test is about -- the lookup runs
      // against a queue it can actually read, because ownership was
      // resolved first -- is unchanged on the queue where it matters, so
      // the premise moves to a queue that is ours.
      test(
        'an edit on our own queue keeps its sticky operation, queuedAt and '
        'splitsTouched, instead of losing them to a lookup made before '
        'ownership was resolved',
        () async {
          final originalQueuedAt = DateTime(2026, 9, 1, 8);
          await TransactionOutbox(outboxDir).setOwner(_ourAccountKey);
          await TransactionOutbox(outboxDir).add(
            PendingTransaction(
              localId: 'local-1',
              operation: PendingOperation.update,
              transaction: Transaction(
                id: 1,
                amount: 5,
                transactionDate: DateTime(2026, 9, 4),
              ),
              queuedAt: originalQueuedAt,
              splitsTouched: true,
            ),
          );
          when(
            () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
          ).thenThrow(const NetworkException('Cannot connect to server'));
          final container = containerWithOutbox();
          await container.read(transactionsControllerProvider().future);

          await container
              .read(transactionsControllerProvider().notifier)
              .save(
                Transaction(
                  id: 1,
                  amount: 9,
                  transactionDate: DateTime(2026, 9, 4),
                ),
                localId: 'local-1',
              );

          final queued = await container.read(transactionOutboxProvider).all();
          expect(queued, hasLength(1));
          expect(queued.single.operation, PendingOperation.update);
          expect(queued.single.queuedAt, originalQueuedAt);
          expect(queued.single.splitsTouched, isTrue);
        },
      );

      // Was 'on an unclaimed queue', for the same reason as the test
      // above: with the queue unclaimed this now passes because the old
      // edit is set aside, not because the delete replaced it -- which is
      // not what the sentence claims. On a queue that is ours it is the
      // replacement being tested again.
      test(
        'an offline delete of a row with a queued edit on our own queue '
        'replaces that edit rather than adding a second entry beside it',
        () async {
          await TransactionOutbox(outboxDir).setOwner(_ourAccountKey);
          await TransactionOutbox(outboxDir).add(
            PendingTransaction(
              localId: 'local-1',
              operation: PendingOperation.update,
              transaction: Transaction(
                id: 1,
                amount: 99,
                transactionDate: DateTime(2026, 9),
              ),
              queuedAt: DateTime(2026, 9),
            ),
          );
          when(() => repo.getPage()).thenAnswer(
            (_) async => TransactionPage(
              content: [
                Transaction(
                  id: 1,
                  amount: 10,
                  transactionDate: DateTime(2026, 9),
                ),
              ],
              page: 0,
              size: 50,
              totalElements: 1,
              totalPages: 1,
            ),
          );
          when(
            () => repo.delete(any()),
          ).thenThrow(const NetworkException('Cannot connect to server'));
          final container = containerWithOutbox();
          await container.read(transactionsControllerProvider().future);

          await container
              .read(transactionsControllerProvider().notifier)
              .delete(1);

          final queued = await container.read(transactionOutboxProvider).all();
          expect(queued, hasLength(1));
          expect(queued.single.operation, PendingOperation.delete);
        },
      );

      // The control test 4b's brief insists on: claimForWriting clears a
      // foreign queue, and a clearing function needs a test proving it
      // does not clear when it must not. Without the `owner == accountKey`
      // early return, this fails alongside tests 1-3.
      test('a queue already ours is not cleared by a second save', () async {
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox();
        await container.read(transactionsControllerProvider().future);
        final notifier = container.read(
          transactionsControllerProvider().notifier,
        );

        await notifier.save(
          Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)),
        );
        await notifier.save(
          Transaction(amount: 6, transactionDate: DateTime(2026, 9, 5)),
        );

        final queued = await container.read(transactionOutboxProvider).all();
        expect(queued, hasLength(2));
        expect(queued.map((e) => e.transaction.amount).toSet(), {5, 6});
      });

      // The whole point of I1, end to end through the real save path: the
      // upgrade sheet was shown, the user tapped "Not now" (which writes
      // nothing at all, so the queue is still unowned here), and then they
      // saved something offline. The old entries must not go out under
      // this account's name.
      test(
        'declining the upgrade sheet and then saving offline sets the old '
        'entries aside instead of adopting them',
        () async {
          await TransactionOutbox(outboxDir).add(
            PendingTransaction(
              localId: 'local-before-the-upgrade',
              operation: PendingOperation.create,
              transaction: Transaction(
                amount: 1,
                payee: 'Aldi',
                transactionDate: DateTime(2026, 9),
              ),
              queuedAt: DateTime(2026, 9, 1, 10),
            ),
          );
          when(
            () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
          ).thenThrow(const NetworkException('Cannot connect to server'));
          final container = containerWithOutbox();
          await container.read(transactionsControllerProvider().future);

          await container
              .read(transactionsControllerProvider().notifier)
              .save(
                Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)),
              );

          final outbox = container.read(transactionOutboxProvider);
          expect(
            (await ownedEntries(outbox, _ourAccountKey)).map(
              (e) => e.transaction.amount,
            ),
            [5],
            reason:
                'the entry this account typed, and not one it never '
                'claimed -- an unowned queue may belong to anybody',
          );
          expect(
            outboxDir
                .listSync()
                .whereType<Directory>()
                .expand((d) => d.listSync())
                .whereType<File>(),
            isNotEmpty,
            reason: 'set aside on disk, not destroyed',
          );
        },
      );

      test(
        'signed out, saving onto a foreign queue claims and clears '
        'nothing: a queue we cannot attribute is not one we may take',
        () async {
          await TransactionOutbox(outboxDir).setOwner('account-a');
          await TransactionOutbox(outboxDir).add(
            PendingTransaction(
              localId: 'local-theirs',
              operation: PendingOperation.create,
              transaction: Transaction(
                amount: 1,
                payee: 'Aldi',
                transactionDate: DateTime(2026, 9),
              ),
              queuedAt: DateTime(2026, 9, 1, 10),
            ),
          );
          when(
            () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
          ).thenThrow(const NetworkException('Cannot connect to server'));
          final container = containerWithOutbox(auth: const AuthState());
          await container.read(transactionsControllerProvider().future);

          await container
              .read(transactionsControllerProvider().notifier)
              .save(
                Transaction(amount: 5, transactionDate: DateTime(2026, 9, 4)),
              );

          final outbox = container.read(transactionOutboxProvider);
          final all = await outbox.all();
          expect(
            all.map((e) => e.localId),
            contains('local-theirs'),
            reason:
                'nobody signed in means nothing may be claimed, so the '
                'foreign entry must survive untouched',
          );
          expect(await outbox.owner(), 'account-a');
        },
      );
    });

    test(
      'saving offline with nobody signed in still queues the entry: '
      'accountKeyFor has nobody to attribute the queue to, so the claim '
      'no-ops, but the save itself must not be caught up in that',
      () async {
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));
        final container = containerWithOutbox(auth: const AuthState());
        await container.read(transactionsControllerProvider().future);

        final outcome = await container
            .read(transactionsControllerProvider().notifier)
            .save(
              Transaction(amount: 12.34, transactionDate: DateTime(2026, 9, 4)),
            );

        expect(outcome, SaveOutcome.queued);
        final outbox = container.read(transactionOutboxProvider);
        expect((await outbox.all()).single.transaction.amount, 12.34);
        expect(await outbox.owner(), isNull);
      },
    );

    // The display half of the guard, which the sending tests in
    // transaction_sync_test.dart cannot reach. An entry carries an amount
    // and a payee, so drawing another account's queue into this account's
    // list is its own leak even if nothing is ever sent from it -- and it
    // is the same read that decides what sign-out offers to discard.
    group('a queue that is not ours is not shown', () {
      Future<void> queueForeign() async {
        final outbox = TransactionOutbox(outboxDir);
        await outbox.add(
          PendingTransaction(
            localId: 'local-theirs',
            operation: PendingOperation.create,
            transaction: Transaction(
              amount: 12.34,
              payee: 'Aldi',
              transactionDate: DateTime(2026, 9, 4),
            ),
            queuedAt: DateTime(2026, 9, 4, 10),
          ),
        );
      }

      test('a queue owned by another account stays off the list', () async {
        await queueForeign();
        await TransactionOutbox(outboxDir).setOwner('https://cuenti.muh#7');
        final container = containerWithOutbox();

        final state = await container.read(
          transactionsControllerProvider().future,
        );

        expect(state.pending, isEmpty);
        expect(
          state.items,
          isEmpty,
          reason: "somebody else's amount and payee, drawn into our list",
        );
      });

      test('an unclaimed queue stays off it too', () async {
        await queueForeign();
        final container = containerWithOutbox();

        final state = await container.read(
          transactionsControllerProvider().future,
        );

        expect(state.pending, isEmpty);
        expect(state.items, isEmpty);
      });

      // The control: the guard has to seal a foreign queue without
      // sealing ours, or the list simply stopped working.
      test('our own queue is still shown', () async {
        await queueForeign();
        await TransactionOutbox(outboxDir).setOwner(_ourAccountKey);
        final container = containerWithOutbox();

        final state = await container.read(
          transactionsControllerProvider().future,
        );

        expect(state.pending, hasLength(1));
        expect(state.items.single.payee, 'Aldi');
      });

      test('nobody signed in sees no queue at all', () async {
        await queueForeign();
        await TransactionOutbox(outboxDir).setOwner(_ourAccountKey);
        final container = containerWithOutbox(auth: const AuthState());

        final state = await container.read(
          transactionsControllerProvider().future,
        );

        expect(state.pending, isEmpty);
        expect(state.items, isEmpty);
      });
    });
  });
}

/// An outbox whose reads fail once [broken] is set, standing in for a
/// storage problem that shows up mid-session rather than at the initial
/// load.
class _BrokenReadOutbox extends TransactionOutbox {
  _BrokenReadOutbox(super._directory);

  bool broken = false;

  @override
  Future<List<PendingTransaction>> all() async {
    if (broken) throw const FileSystemException('gone');
    return super.all();
  }
}
