import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_controller.dart';
import 'package:cuentimobile/features/scheduled/data/scheduled_repository.dart';
import 'package:cuentimobile/features/scheduled/domain/scheduled_transaction.dart';
import 'package:cuentimobile/features/scheduled/ui/scheduled_controller.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockScheduledRepository extends Mock implements ScheduledRepository {}

class MockAccountsRepository extends Mock implements AccountsRepository {}

class MockTransactionsRepository extends Mock implements TransactionsRepository {}

void main() {
  late MockScheduledRepository repo;
  late MockAccountsRepository accountsRepo;
  late MockTransactionsRepository transactionsRepo;
  late ProviderContainer container;

  final st1 = ScheduledTransaction(
    id: 1,
    type: 'EXPENSE',
    fromAccountId: 1,
    amount: 50,
    nextOccurrence: DateTime.parse('2026-07-19T00:00:00Z'),
  );
  final st2 = ScheduledTransaction(
    id: 2,
    type: 'EXPENSE',
    fromAccountId: 1,
    amount: 100,
    nextOccurrence: DateTime.parse('2026-07-26T00:00:00Z'),
  );

  setUp(() {
    repo = MockScheduledRepository();
    accountsRepo = MockAccountsRepository();
    transactionsRepo = MockTransactionsRepository();
    container = ProviderContainer(overrides: [
      scheduledRepositoryProvider.overrideWithValue(repo),
      accountsRepositoryProvider.overrideWithValue(accountsRepo),
      transactionsRepositoryProvider.overrideWithValue(transactionsRepo),
    ]);
    addTearDown(container.dispose);
  });

  test('build loads scheduled transactions', () async {
    when(() => repo.getAll()).thenAnswer((_) async => [st1, st2]);
    final list = await container.read(scheduledControllerProvider.future);
    expect(list, [st1, st2]);
  });

  test('delete is optimistic and reverts on failure', () async {
    when(() => repo.getAll()).thenAnswer((_) async => [st1, st2]);
    await container.read(scheduledControllerProvider.future);
    when(() => repo.delete(1)).thenThrow(const ServerException('boom'));

    await expectLater(
      container.read(scheduledControllerProvider.notifier).delete(1),
      throwsA(isA<ServerException>()),
    );
    expect(container.read(scheduledControllerProvider).value, [st1, st2]);
  });

  test('post invalidates self, accounts, and transactions controllers', () async {
    when(() => repo.getAll()).thenAnswer((_) async => [st1, st2]);
    when(() => accountsRepo.getAll())
        .thenAnswer((_) async => const [Account(id: 1, accountName: 'Checking')]);
    when(() => transactionsRepo.getPage(
            accountId: null, page: 0, size: TransactionsController.pageSize))
        .thenAnswer((_) async => const TransactionPage(
            content: [], page: 0, size: 50, totalElements: 0, totalPages: 1));

    // Keep the dependent controllers alive with listeners so invalidation
    // triggers eager rebuilds instead of lazy/auto-dispose behavior.
    container
      ..listen(scheduledControllerProvider, (_, _) {})
      ..listen(accountsControllerProvider, (_, _) {})
      ..listen(transactionsControllerProvider(accountId: null), (_, _) {});
    await container.read(scheduledControllerProvider.future);
    await container.read(accountsControllerProvider.future);
    await container
        .read(transactionsControllerProvider(accountId: null).future);
    verify(() => accountsRepo.getAll()).called(1);

    when(() => repo.post(1)).thenAnswer((_) async {});

    await container.read(scheduledControllerProvider.notifier).post(1);
    // Settle rebuilds of the invalidated dependents.
    await container.read(accountsControllerProvider.future);
    await container
        .read(transactionsControllerProvider(accountId: null).future);

    verify(() => repo.post(1)).called(1);
    // Self reloaded: build's getAll fetched again.
    verify(() => repo.getAll()).called(2);
    // Cross-invalidation: accounts and transactions refetched.
    verify(() => accountsRepo.getAll()).called(1);
    verify(() => transactionsRepo.getPage(
            accountId: null, page: 0, size: TransactionsController.pageSize))
        .called(2);
  });
}
