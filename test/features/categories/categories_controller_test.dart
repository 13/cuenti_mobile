import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/categories_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

void main() {
  late MockCategoriesRepository repo;
  late ProviderContainer container;

  const c1 = Category(id: 1, name: 'Groceries');
  const c2 = Category(id: 2, name: 'Utilities');

  setUp(() {
    repo = MockCategoriesRepository();
    container = ProviderContainer(overrides: [
      categoriesRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
  });

  test('build loads categories', () async {
    when(() => repo.getAll()).thenAnswer((_) async => [c1, c2]);
    final list = await container.read(categoriesControllerProvider.future);
    expect(list, [c1, c2]);
  });

  test('delete is optimistic and reverts on failure', () async {
    when(() => repo.getAll()).thenAnswer((_) async => [c1, c2]);
    await container.read(categoriesControllerProvider.future);
    when(() => repo.delete(1)).thenThrow(const ServerException('boom'));

    await expectLater(
      container.read(categoriesControllerProvider.notifier).delete(1),
      throwsA(isA<ServerException>()),
    );
    expect(container.read(categoriesControllerProvider).value, [c1, c2]);
  });
}
