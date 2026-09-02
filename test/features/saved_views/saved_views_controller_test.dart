import 'dart:async';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/saved_views/data/saved_views_repository.dart';
import 'package:cuentimobile/features/saved_views/domain/saved_view.dart';
import 'package:cuentimobile/features/saved_views/ui/saved_views_controller.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSavedViewsRepository extends Mock implements SavedViewsRepository {}

void main() {
  late MockSavedViewsRepository repo;
  late ProviderContainer container;

  const thisMonth = SavedView(id: 1, name: 'This month');
  const groceries = SavedView(id: 2, name: 'Groceries');

  setUp(() {
    repo = MockSavedViewsRepository();
    container = ProviderContainer(
      overrides: [savedViewsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    when(
      () => repo.getAll(),
    ).thenAnswer((_) async => [thisMonth, groceries]);
  });

  Future<List<SavedView>> loaded() =>
      container.read(savedViewsControllerProvider.future);

  test('build loads the saved views', () async {
    expect(await loaded(), [thisMonth, groceries]);
  });

  test('delete removes the view before the server answers', () async {
    await loaded();
    final completer = Completer<void>();
    when(() => repo.delete(1)).thenAnswer((_) => completer.future);

    final pending = container
        .read(savedViewsControllerProvider.notifier)
        .delete(1);
    expect(container.read(savedViewsControllerProvider).value, [groceries]);

    completer.complete();
    await pending;
  });

  test('a refused delete puts the view back, rather than leaving the sheet '
      'offering a view the server still has', () async {
    await loaded();
    when(() => repo.delete(1)).thenThrow(const ServerException('boom'));

    await expectLater(
      container.read(savedViewsControllerProvider.notifier).delete(1),
      throwsA(isA<ServerException>()),
    );
    expect(container.read(savedViewsControllerProvider).value, [
      thisMonth,
      groceries,
    ]);
  });

  test('saving the current filter encodes it and refetches', () async {
    await loaded();
    when(() => repo.save(any(), any())).thenAnswer((_) async => thisMonth);
    when(() => repo.getAll()).thenAnswer((_) async => [thisMonth]);

    await container
        .read(savedViewsControllerProvider.notifier)
        .saveCurrent('Fuel', const TransactionFilter(search: 'fuel'));

    final name = verify(
      () => repo.save(captureAny(), captureAny()),
    ).captured;
    expect(name.first, 'Fuel');
    expect(
      name.last,
      contains('fuel'),
      reason: 'the filter is encoded into the stored params',
    );
    expect(container.read(savedViewsControllerProvider).value, [thisMonth]);
  });
}
