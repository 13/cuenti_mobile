import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/budgets/data/budgets_repository.dart';
import 'package:cuentimobile/features/budgets/domain/budget.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late BudgetsRepository repo;

  setUp(() {
    dio = MockDio();
    repo = BudgetsRepository(dio);
  });

  test('getProgress parses list with doubles from ints', () async {
    when(() => dio.get<List<dynamic>>('/budgets/progress'))
        .thenAnswer((_) async => ok([
              {
                'budgetId': 1,
                'categoryId': 2,
                'categoryName': 'Groceries',
                'monthlyLimit': 300,
                'spent': 150,
                'remaining': 150,
                'active': true,
              },
              {
                'budgetId': 2,
                'categoryId': 3,
                'categoryName': 'Fun',
                'monthlyLimit': 100.5,
                'spent': 120.25,
                'remaining': -19.75,
                'active': false,
              },
            ]));

    final progress = await repo.getProgress();

    expect(progress, hasLength(2));
    expect(progress[0].budgetId, 1);
    expect(progress[0].categoryName, 'Groceries');
    expect(progress[0].monthlyLimit, 300.0);
    expect(progress[0].spent, 150.0);
    expect(progress[0].remaining, 150.0);
    expect(progress[0].active, true);
    expect(progress[1].monthlyLimit, 100.5);
    expect(progress[1].active, false);
  });

  test('save posts new budget when id is null with explicit payload', () async {
    const budget = Budget(categoryId: 2, monthlyLimit: 300, active: true);
    when(() => dio.post<Map<String, dynamic>>('/budgets',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({
              'id': 9,
              'categoryId': 2,
              'monthlyLimit': 300,
              'active': true,
            }));

    final saved = await repo.save(budget);

    expect(saved.id, 9);
    final captured = verify(() => dio.post<Map<String, dynamic>>('/budgets',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured, {
      'categoryId': 2,
      'monthlyLimit': 300.0,
      'active': true,
    });
    expect(captured.keys, isNot(contains('id')));
  });

  test('save puts existing budget when id is set', () async {
    const budget =
        Budget(id: 4, categoryId: 2, monthlyLimit: 300, active: true);
    when(() => dio.put<Map<String, dynamic>>('/budgets/4',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({
              'id': 4,
              'categoryId': 2,
              'monthlyLimit': 300,
              'active': true,
            }));

    final saved = await repo.save(budget);

    expect(saved.id, 4);
    verify(() => dio.put<Map<String, dynamic>>('/budgets/4',
        data: any(named: 'data'))).called(1);
  });

  test('delete calls DELETE /budgets/{id}', () async {
    when(() => dio.delete<void>('/budgets/5')).thenAnswer((_) async => ok(null));

    await repo.delete(5);

    verify(() => dio.delete<void>('/budgets/5')).called(1);
  });

  test('getProgress maps DioException to ApiException', () async {
    when(() => dio.get<List<dynamic>>('/budgets/progress')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/budgets/progress'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getProgress(), throwsA(isA<NetworkException>()));
  });

  test('save maps 400 duplicate category to ValidationException', () async {
    const budget = Budget(categoryId: 2, monthlyLimit: 300, active: true);
    when(() => dio.post<Map<String, dynamic>>('/budgets',
        data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/budgets'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/budgets'),
          statusCode: 400,
          data: {'error': 'Budget already exists for this category'},
        ),
      ),
    );

    expect(() => repo.save(budget), throwsA(isA<ValidationException>()));
  });
}
