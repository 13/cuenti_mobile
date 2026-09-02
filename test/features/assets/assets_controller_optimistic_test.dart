import 'dart:async';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/assets/data/assets_repository.dart';
import 'package:cuentimobile/features/assets/domain/asset.dart';
import 'package:cuentimobile/features/assets/ui/assets_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetsRepository extends Mock implements AssetsRepository {}

void main() {
  late MockAssetsRepository repo;
  late ProviderContainer container;

  const gold = Asset(id: 1, name: 'Gold');
  const fund = Asset(id: 2, name: 'Fund');

  setUpAll(() {
    registerFallbackValue(gold);
  });

  setUp(() {
    repo = MockAssetsRepository();
    container = ProviderContainer(
      overrides: [assetsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    when(() => repo.getAll()).thenAnswer((_) async => [gold, fund]);
  });

  Future<List<Asset>> loaded() =>
      container.read(assetsControllerProvider.future);

  test('build loads the assets', () async {
    expect(await loaded(), [gold, fund]);
  });

  test('delete removes the row before the server answers, so the list does '
      'not sit there looking unchanged', () async {
    await loaded();
    final completer = Completer<void>();
    when(() => repo.delete(1)).thenAnswer((_) => completer.future);

    final pending = container.read(assetsControllerProvider.notifier).delete(1);
    expect(container.read(assetsControllerProvider).value, [fund]);

    completer.complete();
    await pending;
  });

  test('a refused delete puts the row back rather than leaving the list '
      'claiming something was deleted that was not', () async {
    await loaded();
    when(() => repo.delete(1)).thenThrow(const ServerException('boom'));

    await expectLater(
      container.read(assetsControllerProvider.notifier).delete(1),
      throwsA(isA<ServerException>()),
    );
    expect(container.read(assetsControllerProvider).value, [gold, fund]);
  });

  test('saving refetches, so the list shows what the server stored rather '
      'than what was sent', () async {
    await loaded();
    when(() => repo.save(any())).thenAnswer((_) async => gold);
    when(() => repo.getAll()).thenAnswer((_) async => [gold]);

    await container.read(assetsControllerProvider.notifier).save(gold);

    expect(container.read(assetsControllerProvider).value, [gold]);
  });

  test('refreshing a price refetches too', () async {
    await loaded();
    when(() => repo.refreshPrice(1)).thenAnswer((_) async => fund);
    when(() => repo.getAll()).thenAnswer((_) async => [fund]);

    await container.read(assetsControllerProvider.notifier).refreshPrice(1);

    verify(() => repo.refreshPrice(1)).called(1);
    expect(container.read(assetsControllerProvider).value, [fund]);
  });
}
