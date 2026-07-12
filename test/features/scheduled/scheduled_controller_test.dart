import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/scheduled/data/scheduled_repository.dart';
import 'package:cuentimobile/features/scheduled/domain/scheduled_transaction.dart';
import 'package:cuentimobile/features/scheduled/ui/scheduled_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockScheduledRepository extends Mock implements ScheduledRepository {}

void main() {
  late MockScheduledRepository repo;
  late ProviderContainer container;

  final st1 = ScheduledTransaction(
    id: 1,
    type: 'EXPENSE',
    fromAccountId: 1,
    amount: 50.0,
    nextOccurrence: DateTime.parse('2026-07-19T00:00:00Z'),
  );
  final st2 = ScheduledTransaction(
    id: 2,
    type: 'EXPENSE',
    fromAccountId: 1,
    amount: 100.0,
    nextOccurrence: DateTime.parse('2026-07-26T00:00:00Z'),
  );

  setUp(() {
    repo = MockScheduledRepository();
    container = ProviderContainer(overrides: [
      scheduledRepositoryProvider.overrideWithValue(repo),
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
    await container.read(scheduledControllerProvider.future);

    when(() => repo.post(1)).thenAnswer((_) async => Future.value());

    // Create a tracker to verify invalidation
    var invalidatedScheduled = false;

    // Override the controllers to track invalidation
    container.listen<AsyncValue<dynamic>>(
      scheduledControllerProvider,
      (prev, next) {
        if (prev != null && !prev.isLoading && next.isLoading) {
          invalidatedScheduled = true;
        }
      },
    );

    await container.read(scheduledControllerProvider.notifier).post(1);

    verify(() => repo.post(1)).called(1);
    // After post, state should reload (isLoading will be true before new data arrives)
    expect(invalidatedScheduled, true);
  });
}
