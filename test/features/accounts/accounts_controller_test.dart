import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountsRepository extends Mock implements AccountsRepository {}

void main() {
  late MockAccountsRepository repo;
  late ProviderContainer container;

  const a1 = Account(id: 1, accountName: 'Giro');
  const a2 = Account(id: 2, accountName: 'Cash');

  setUp(() {
    repo = MockAccountsRepository();
    container = ProviderContainer(overrides: [
      accountsRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
  });

  test('build loads accounts', () async {
    when(() => repo.getAll()).thenAnswer((_) async => [a1, a2]);
    final list = await container.read(accountsControllerProvider.future);
    expect(list, [a1, a2]);
  });

  test('delete is optimistic and reverts on failure', () async {
    when(() => repo.getAll()).thenAnswer((_) async => [a1, a2]);
    await container.read(accountsControllerProvider.future);
    when(() => repo.delete(1)).thenThrow(const ServerException('boom'));

    await expectLater(
      container.read(accountsControllerProvider.notifier).delete(1),
      throwsA(isA<ServerException>()),
    );
    expect(container.read(accountsControllerProvider).value, [a1, a2]);
  });
}
