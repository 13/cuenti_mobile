import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/privacy_blur.dart';
import 'package:cuentimobile/features/budgets/data/budgets_repository.dart';
import 'package:cuentimobile/features/budgets/domain/budget_progress.dart';
import 'package:cuentimobile/features/budgets/ui/budgets_screen.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetsRepository extends Mock implements BudgetsRepository {}

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

void main() {
  late MockBudgetsRepository budgetsRepo;
  late MockCategoriesRepository categoriesRepo;

  const overBudget = BudgetProgress(
    budgetId: 1,
    categoryId: 10,
    categoryName: 'Groceries',
    monthlyLimit: 200,
    spent: 250,
    remaining: -50,
  );
  const underBudget = BudgetProgress(
    budgetId: 2,
    categoryId: 11,
    categoryName: 'Fun',
    monthlyLimit: 100,
    spent: 40,
    remaining: 60,
  );
  const inactiveBudget = BudgetProgress(
    budgetId: 3,
    categoryId: 12,
    categoryName: 'Travel',
    monthlyLimit: 500,
    spent: 0,
    remaining: 500,
    active: false,
  );

  setUp(() {
    budgetsRepo = MockBudgetsRepository();
    categoriesRepo = MockCategoriesRepository();

    when(() => budgetsRepo.getProgress()).thenAnswer(
      (_) async => [overBudget, underBudget, inactiveBudget],
    );
    when(() => categoriesRepo.getAll()).thenAnswer(
      (_) async => const [
        Category(id: 10, name: 'Groceries', type: 'EXPENSE'),
        Category(id: 11, name: 'Fun', type: 'EXPENSE'),
        Category(id: 12, name: 'Travel', type: 'EXPENSE'),
        Category(id: 13, name: 'Health', type: 'EXPENSE'),
      ],
    );
  });

  Future<void> pumpScreen(WidgetTester tester, {bool privacyOn = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetsRepositoryProvider.overrideWithValue(budgetsRepo),
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
          if (privacyOn) privacyModeProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: BudgetsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a progress bar per budget, dimmed for inactive', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Fun'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));

    // Inactive card is dimmed via Opacity(0.5).
    final opacities = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .where((o) => o.opacity == 0.5);
    expect(opacities, hasLength(1));

    final context = tester.element(find.byType(BudgetsScreen));
    final colorScheme = Theme.of(context).colorScheme;
    final cuentiColors = context.cuentiColors;

    final bars = tester.widgetList<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bars.where((b) => b.color == cuentiColors.expense), hasLength(1));
    expect(bars.where((b) => b.color == colorScheme.primary), hasLength(2));
  });

  testWidgets('privacy mode masks the remaining amount on budget cards', (
    tester,
  ) async {
    await pumpScreen(tester, privacyOn: true);

    // Every card shows the "Remaining: " label...
    expect(find.text('Remaining: '), findsNWidgets(3));
    // ...and the real value is still in the tree (not substituted with
    // dots), just blurred via PrivacyBlur.
    expect(find.text('•••••'), findsNothing);
    expect(find.text(formatNumber(60)), findsOneWidget);
    expect(find.text(formatNumber(-50)), findsOneWidget);
    // 500 also happens to be the (inactive) Travel budget's monthlyLimit,
    // so it renders twice (Remaining line + limit AmountText).
    expect(find.text(formatNumber(500)), findsNWidgets(2));

    // The spent/limit AmountTexts blur too (2 per card × 3 cards), plus
    // one for each Remaining value.
    expect(find.byType(PrivacyBlur), findsNWidgets(9));
    expect(find.byType(ImageFiltered), findsNWidgets(9));
  });

  testWidgets('shows the raw remaining amount when privacy mode is off', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byType(PrivacyBlur), findsNothing);
    expect(find.text('Remaining: '), findsNWidgets(3));
    expect(find.text(formatNumber(60)), findsOneWidget);
  });

  testWidgets('tapping the FAB opens the add-budget sheet with a category dropdown', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Add Budget'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('tapping a card opens the edit sheet with Delete button', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Fun'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Budget'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });
}
