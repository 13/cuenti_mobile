import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/saved_views/data/saved_views_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late SavedViewsRepository repo;

  setUp(() {
    dio = MockDio();
    repo = SavedViewsRepository(dio);
  });

  test('getAll parses list of saved views', () async {
    when(() => dio.get<List<dynamic>>('/saved-views')).thenAnswer(
      (_) async => ok([
        {
          'id': 1,
          'name': 'Groceries',
          'params': '{"v":1,"categoryId":2}',
          'createdAt': '2026-01-01T00:00:00.000Z',
        },
        {'id': 2, 'name': 'Web view', 'params': '{"foo":true}'},
      ]),
    );

    final views = await repo.getAll();

    expect(views, hasLength(2));
    expect(views[0].id, 1);
    expect(views[0].name, 'Groceries');
    expect(views[1].name, 'Web view');
  });

  test('save posts name and params, upserting by name', () async {
    when(() => dio.post<Map<String, dynamic>>('/saved-views',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({'id': 5, 'name': 'Groceries'}));

    await repo.save('Groceries', '{"v":1,"categoryId":2}');

    final captured = verify(() => dio.post<Map<String, dynamic>>(
            '/saved-views',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured, {
      'name': 'Groceries',
      'params': '{"v":1,"categoryId":2}',
    });
  });

  test('delete calls DELETE /saved-views/{id}', () async {
    when(() => dio.delete<void>('/saved-views/3'))
        .thenAnswer((_) async => ok(null));

    await repo.delete(3);

    verify(() => dio.delete<void>('/saved-views/3')).called(1);
  });

  test('getAll maps DioException to ApiException', () async {
    when(() => dio.get<List<dynamic>>('/saved-views')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/saved-views'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getAll(), throwsA(isA<NetworkException>()));
  });
}
