import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late CategoriesRepository repo;

  setUp(() {
    dio = MockDio();
    repo = CategoriesRepository(dio);
  });

  test('getAll parses list of categories', () async {
    when(() => dio.get<List<dynamic>>('/categories')).thenAnswer((_) async => ok([
          {'id': 1, 'name': 'Groceries', 'type': 'EXPENSE', 'parentId': null},
          {'id': 2, 'name': 'Income', 'type': 'INCOME', 'parentId': null},
        ]));

    final categories = await repo.getAll();

    expect(categories, hasLength(2));
    expect(categories[0].id, 1);
    expect(categories[0].name, 'Groceries');
    expect(categories[1].type, 'INCOME');
  });

  test('getAll passes type query param when non-null', () async {
    when(() => dio.get<List<dynamic>>('/categories',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => ok([
          {'id': 1, 'name': 'Groceries', 'type': 'EXPENSE'}
        ]));

    await repo.getAll(type: 'EXPENSE');

    verify(() => dio.get<List<dynamic>>('/categories',
        queryParameters: {'type': 'EXPENSE'})).called(1);
  });

  test('save posts new category when id is null', () async {
    const category = Category(
        name: 'New', parentId: 3, fullName: 'Parent > New', parentName: 'Parent');
    when(() => dio.post<Map<String, dynamic>>('/categories',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({'id': 5, 'name': 'New', 'type': 'EXPENSE'}));

    final saved = await repo.save(category);

    expect(saved.id, 5);
    final captured = verify(() => dio.post<Map<String, dynamic>>('/categories',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured, containsPair('name', 'New'));
    expect(captured, containsPair('type', 'EXPENSE'));
    expect(captured, containsPair('parentId', 3));
    expect(captured.keys, isNot(contains('id')));
    expect(captured.keys, isNot(contains('fullName')));
    expect(captured.keys, isNot(contains('parentName')));
  });

  test('save puts existing category when id is set', () async {
    const category = Category(id: 7, name: 'Existing');
    when(() => dio.put<Map<String, dynamic>>('/categories/7',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({'id': 7, 'name': 'Existing'}));

    final saved = await repo.save(category);

    expect(saved.id, 7);
    verify(() => dio.put<Map<String, dynamic>>('/categories/7',
        data: any(named: 'data'))).called(1);
  });

  test('delete calls DELETE /categories/{id}', () async {
    when(() => dio.delete<void>('/categories/3')).thenAnswer((_) async => ok(null));

    await repo.delete(3);

    verify(() => dio.delete<void>('/categories/3')).called(1);
  });

  test('getAll maps DioException to ApiException', () async {
    when(() => dio.get<List<dynamic>>('/categories')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/categories'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getAll(), throwsA(isA<NetworkException>()));
  });
}
