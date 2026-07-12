import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock implements TransactionsRepository {}

void main() {
  late MockTransactionsRepository repo;
  late ProviderContainer container;

  Transaction tx(int id) => Transaction(
        id: id,
        amount: 10,
        transactionDate: DateTime(2026, 1, id),
      );

  setUp(() {
    repo = MockTransactionsRepository();
    container = ProviderContainer(overrides: [
      transactionsRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
  });

  test('build loads page 0 and flags hasMore when more than one page', () async {
    when(() => repo.getPage(accountId: null, page: 0, size: 50)).thenAnswer(
        (_) async => TransactionPage(
            content: [tx(1), tx(2)], page: 0, size: 50, totalElements: 60, totalPages: 2));

    final state = await container
        .read(transactionsControllerProvider(accountId: null).future);

    expect(state.items, [tx(1), tx(2)]);
    expect(state.nextPage, 1);
    expect(state.hasMore, isTrue);
  });

  test('build flags hasMore false for a single page', () async {
    when(() => repo.getPage(accountId: null, page: 0, size: 50)).thenAnswer(
        (_) async => TransactionPage(
            content: [tx(1)], page: 0, size: 50, totalElements: 1, totalPages: 1));

    final state = await container
        .read(transactionsControllerProvider(accountId: null).future);

    expect(state.hasMore, isFalse);
  });

  test('loadMore appends items and flips hasMore false on last page', () async {
    when(() => repo.getPage(accountId: null, page: 0, size: 50)).thenAnswer(
        (_) async => TransactionPage(
            content: [tx(1)], page: 0, size: 50, totalElements: 2, totalPages: 2));
    when(() => repo.getPage(accountId: null, page: 1, size: 50)).thenAnswer(
        (_) async => TransactionPage(
            content: [tx(2)], page: 1, size: 50, totalElements: 2, totalPages: 2));

    await container.read(transactionsControllerProvider(accountId: null).future);
    await container
        .read(transactionsControllerProvider(accountId: null).notifier)
        .loadMore();

    final state =
        container.read(transactionsControllerProvider(accountId: null)).value!;
    expect(state.items, [tx(1), tx(2)]);
    expect(state.hasMore, isFalse);
    expect(state.loadingMore, isFalse);
  });

  test('loadMore no-ops when hasMore is false', () async {
    when(() => repo.getPage(accountId: null, page: 0, size: 50)).thenAnswer(
        (_) async => TransactionPage(
            content: [tx(1)], page: 0, size: 50, totalElements: 1, totalPages: 1));

    await container.read(transactionsControllerProvider(accountId: null).future);
    await container
        .read(transactionsControllerProvider(accountId: null).notifier)
        .loadMore();

    verifyNever(() => repo.getPage(accountId: null, page: 1, size: 50));
  });

  test('delete is optimistic and reverts on failure', () async {
    when(() => repo.getPage(accountId: null, page: 0, size: 50)).thenAnswer(
        (_) async => TransactionPage(
            content: [tx(1), tx(2)], page: 0, size: 50, totalElements: 2, totalPages: 1));
    await container.read(transactionsControllerProvider(accountId: null).future);
    when(() => repo.delete(1)).thenThrow(const ServerException('boom'));

    await expectLater(
      container
          .read(transactionsControllerProvider(accountId: null).notifier)
          .delete(1),
      throwsA(isA<ServerException>()),
    );
    expect(
        container.read(transactionsControllerProvider(accountId: null)).value!.items,
        [tx(1), tx(2)]);
  });

  test('controller is keyed by accountId family', () async {
    when(() => repo.getPage(accountId: 3, page: 0, size: 50)).thenAnswer(
        (_) async => TransactionPage(
            content: [tx(1)], page: 0, size: 50, totalElements: 1, totalPages: 1));
    when(() => repo.getPage(accountId: null, page: 0, size: 50)).thenAnswer(
        (_) async => TransactionPage(
            content: [tx(2)], page: 0, size: 50, totalElements: 1, totalPages: 1));

    final withAccount =
        await container.read(transactionsControllerProvider(accountId: 3).future);
    final all =
        await container.read(transactionsControllerProvider(accountId: null).future);

    expect(withAccount.items, [tx(1)]);
    expect(all.items, [tx(2)]);
  });
}
