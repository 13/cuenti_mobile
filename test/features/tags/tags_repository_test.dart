import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/tags/data/tags_repository.dart';
import 'package:cuentimobile/features/tags/domain/tag.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late TagsRepository repo;

  setUp(() {
    dio = MockDio();
    repo = TagsRepository(dio);
  });

  test('getAll parses list of tags', () async {
    when(() => dio.get<List<dynamic>>('/tags')).thenAnswer((_) async => ok([
          {'id': 1, 'name': 'Work'},
          {'id': 2, 'name': 'Personal'},
        ]));

    final tags = await repo.getAll();

    expect(tags, hasLength(2));
    expect(tags[0].id, 1);
    expect(tags[0].name, 'Work');
    expect(tags[1].name, 'Personal');
  });

  test('getAll passes search query param when non-null', () async {
    when(() => dio.get<List<dynamic>>('/tags',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => ok([
          {'id': 1, 'name': 'Work'}
        ]));

    await repo.getAll(search: 'work');

    verify(() => dio.get<List<dynamic>>('/tags',
        queryParameters: {'search': 'work'})).called(1);
  });

  test('save posts new tag when id is null', () async {
    const tag = Tag(name: 'New Tag');
    when(() => dio.post<Map<String, dynamic>>('/tags',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({'id': 5, 'name': 'New Tag'}));

    final saved = await repo.save(tag);

    expect(saved.id, 5);
    final captured = verify(() => dio.post<Map<String, dynamic>>('/tags',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured.containsKey('id'), isFalse);
    expect(captured['name'], 'New Tag');
  });

  test('save puts existing tag when id is set', () async {
    const tag = Tag(id: 7, name: 'Existing');
    when(() => dio.put<Map<String, dynamic>>('/tags/7',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({'id': 7, 'name': 'Existing'}));

    final saved = await repo.save(tag);

    expect(saved.id, 7);
    verify(() => dio.put<Map<String, dynamic>>('/tags/7',
        data: any(named: 'data'))).called(1);
  });

  test('delete calls DELETE /tags/{id}', () async {
    when(() => dio.delete<void>('/tags/3')).thenAnswer((_) async => ok(null));

    await repo.delete(3);

    verify(() => dio.delete<void>('/tags/3')).called(1);
  });

  test('getAll maps DioException to ApiException', () async {
    when(() => dio.get<List<dynamic>>('/tags')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/tags'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getAll(), throwsA(isA<NetworkException>()));
  });
}
