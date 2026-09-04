import 'dart:io';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late MockTransactionsRepository repo;
  late ProviderContainer container;

  Transaction tx(int id) => Transaction(
    id: id,
    amount: 10,
    transactionDate: DateTime(2026, 1, id),
  );

  setUpAll(() {
    registerFallbackValue(
      Transaction(amount: 0, transactionDate: DateTime(2026)),
    );
  });

  setUp(() {
    repo = MockTransactionsRepository();
    container = ProviderContainer(
      overrides: [
        transactionsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
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

      expect(state.items, [tx(1), tx(2)]);
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
    expect(state.items, [tx(1), tx(2)]);
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
      expect(state.items, [tx(1), tx(2), tx(3)]);
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
      expect(built.items, [tx(1), tx(2)]);

      await container
          .read(transactionsControllerProvider().notifier)
          .loadMore();

      final state = container.read(transactionsControllerProvider()).value!;
      expect(state.items, [tx(1), tx(2), tx(3)]);
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
    expect(container.read(transactionsControllerProvider()).value!.items, [
      tx(1),
      tx(2),
    ]);
  });

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

    ProviderContainer containerWithOutbox() {
      final container = ProviderContainer(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(repo),
          transactionOutboxProvider.overrideWithValue(
            TransactionOutbox(outboxDir),
          ),
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
  });
}
