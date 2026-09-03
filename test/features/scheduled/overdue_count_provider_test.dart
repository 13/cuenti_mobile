import 'package:cuentimobile/features/scheduled/data/scheduled_repository.dart';
import 'package:cuentimobile/features/scheduled/domain/scheduled_transaction.dart';
import 'package:cuentimobile/features/scheduled/ui/scheduled_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockScheduledRepository extends Mock implements ScheduledRepository {}

void main() {
  late MockScheduledRepository repo;

  ScheduledTransaction due(DateTime date, {bool enabled = true}) =>
      ScheduledTransaction(
        id: date.millisecondsSinceEpoch,
        amount: 10,
        nextOccurrence: date,
        enabled: enabled,
      );

  final yesterday = DateTime.now().subtract(const Duration(days: 2));
  final tomorrow = DateTime.now().add(const Duration(days: 2));

  setUp(() {
    repo = MockScheduledRepository();
  });

  ProviderContainer containerWith(List<ScheduledTransaction> entries) {
    when(repo.getAll).thenAnswer((_) async => entries);
    final container = ProviderContainer(
      overrides: [scheduledRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('counts what is past due once the list has arrived', () async {
    final container = containerWith([
      due(yesterday),
      due(yesterday),
      due(tomorrow),
    ]);

    await container.read(scheduledControllerProvider.future);

    expect(container.read(overdueScheduledCountProvider), 2);
  });

  test('a paused entry is not counted', () async {
    final container = containerWith([
      due(yesterday, enabled: false),
      due(yesterday),
    ]);

    await container.read(scheduledControllerProvider.future);

    expect(container.read(overdueScheduledCountProvider), 1);
  });

  test('nothing overdue counts zero', () async {
    final container = containerWith([due(tomorrow)]);

    await container.read(scheduledControllerProvider.future);

    expect(container.read(overdueScheduledCountProvider), 0);
  });

  test('reads zero while the list is still loading, rather than flashing a '
      'badge on before it knows', () {
    final container = containerWith([due(yesterday)]);

    expect(container.read(overdueScheduledCountProvider), 0);
  });

  test('reads zero when the request failed, because an alert raised by a '
      'half-failed fetch is worse than no alert', () async {
    when(repo.getAll).thenThrow(Exception('offline'));
    final container = ProviderContainer(
      overrides: [scheduledRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container
        .read(scheduledControllerProvider.future)
        .then<void>((_) {}, onError: (_, _) {});

    expect(container.read(overdueScheduledCountProvider), 0);
  });
}
