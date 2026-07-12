import 'package:cuentimobile/features/budgets/data/budgets_repository.dart';
import 'package:cuentimobile/features/budgets/domain/budget.dart';
import 'package:cuentimobile/features/budgets/domain/budget_progress.dart';
import 'package:cuentimobile/features/budgets/ui/budgets_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetsRepository extends Mock implements BudgetsRepository {}

void main() {
  late MockBudgetsRepository repo;
  late ProviderContainer container;

  const p1 = BudgetProgress(
    budgetId: 1,
    categoryId: 2,
    categoryName: 'Groceries',
    monthlyLimit: 300,
    spent: 150,
    remaining: 150,
  );

  setUp(() {
    repo = MockBudgetsRepository();
    container = ProviderContainer(overrides: [
      budgetsRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    registerFallbackValue(
      const Budget(categoryId: 0, monthlyLimit: 0),
    );
  });

  test('build loads budget progress', () async {
    when(() => repo.getProgress()).thenAnswer((_) async => [p1]);
    final list = await container.read(budgetsControllerProvider.future);
    expect(list, [p1]);
  });

  test('save invalidates and refetches progress', () async {
    when(() => repo.getProgress()).thenAnswer((_) async => [p1]);
    await container.read(budgetsControllerProvider.future);

    when(() => repo.save(any())).thenAnswer((_) async => const Budget(
          id: 1,
          categoryId: 2,
          monthlyLimit: 300,
          active: true,
        ));

    await container.read(budgetsControllerProvider.notifier).save(
          const Budget(id: 1, categoryId: 2, monthlyLimit: 300),
        );

    verify(() => repo.getProgress()).called(2);
  });

  test('delete invalidates and refetches progress', () async {
    when(() => repo.getProgress()).thenAnswer((_) async => [p1]);
    await container.read(budgetsControllerProvider.future);

    when(() => repo.delete(1)).thenAnswer((_) async {});

    await container.read(budgetsControllerProvider.notifier).delete(1);

    verify(() => repo.getProgress()).called(2);
  });
}
