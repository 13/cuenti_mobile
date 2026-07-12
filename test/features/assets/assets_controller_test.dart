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

  const a1 = Asset(id: 1, symbol: 'AAPL', name: 'Apple Inc', currency: 'USD');
  const a2 = Asset(id: 2, symbol: 'BTC', name: 'Bitcoin', type: 'CRYPTO', currency: 'USD');

  setUp(() {
    repo = MockAssetsRepository();
    container = ProviderContainer(overrides: [
      assetsRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
  });

  test('build loads assets', () async {
    when(() => repo.getAll()).thenAnswer((_) async => [a1, a2]);
    final list = await container.read(assetsControllerProvider.future);
    expect(list, [a1, a2]);
  });

  test('refreshPrice calls repo then reloads the list', () async {
    when(() => repo.getAll()).thenAnswer((_) async => [a1, a2]);
    await container.read(assetsControllerProvider.future);
    when(() => repo.refreshPrice(1)).thenAnswer(
        (_) async => const Asset(id: 1, symbol: 'AAPL', name: 'Apple Inc', currentPrice: 150.25));

    await container.read(assetsControllerProvider.notifier).refreshPrice(1);

    verify(() => repo.refreshPrice(1)).called(1);
    // Reload: build's getAll is fetched again after invalidateSelf.
    verify(() => repo.getAll()).called(2);
  });
}
