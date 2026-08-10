import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/features/vehicles/data/vehicles_repository.dart';
import 'package:cuentimobile/features/vehicles/domain/vehicle_report.dart';
import 'package:cuentimobile/features/vehicles/ui/vehicles_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

class MockVehiclesRepository extends Mock implements VehiclesRepository {}

/// Supplies an already-initialized auth state synchronously, bypassing the
/// real controller's async `_init()`.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

void main() {
  late MockCategoriesRepository categoriesRepo;
  late MockVehiclesRepository vehiclesRepo;

  // Enough expense categories that the sheet cannot show them all at once;
  // 'Fuel' is last so it is only reachable by scrolling.
  final categories = [
    for (var i = 1; i <= 25; i++)
      Category(id: i, name: 'Category $i', type: 'EXPENSE'),
    const Category(id: 99, name: 'Fuel', type: 'EXPENSE'),
  ];

  setUpAll(() {
    registerFallbackValue(DateTime(2000));
  });

  setUp(() {
    categoriesRepo = MockCategoriesRepository();
    vehiclesRepo = MockVehiclesRepository();
    when(() => categoriesRepo.getAll()).thenAnswer((_) async => categories);
    when(
      () => vehiclesRepo.getReport(
        categoryId: any(named: 'categoryId'),
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) async => const VehicleReport());
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
          vehiclesRepositoryProvider.overrideWithValue(vehiclesRepo),
          authControllerProvider.overrideWith(
            () => _FakeAuthController(
              const AuthState(
                user: UserProfile(username: 'demo', email: 'd@x'),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: VehiclesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'category sheet scrolls so a fuel category far down the list can be chosen',
    (tester) async {
      await pumpScreen(tester);

      // No default category yet: empty state with the chooser action.
      await tester.tap(find.text('Choose category'));
      await tester.pumpAndSettle();

      expect(find.text('Fuel category'), findsOneWidget);

      // 'Fuel' sits below the fold; the sheet must scroll to reach it.
      // Categories load only once the sheet is open, so the list must be
      // populated now.
      expect(find.text('Category 1'), findsOneWidget);

      // 'Fuel' sits below the fold; the sheet must scroll to reach it.
      await tester.drag(
        find.byType(ListView).last,
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fuel'));
      await tester.pumpAndSettle();

      // Sheet closed, selection applied: chip in the report view shows it.
      expect(find.text('Fuel category'), findsNothing);
      expect(find.text('Fuel'), findsOneWidget);
      verify(
        () => vehiclesRepo.getReport(
          categoryId: 99,
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).called(1);
    },
  );
}
