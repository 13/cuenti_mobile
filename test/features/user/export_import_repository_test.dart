import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/user/data/export_import_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late ExportImportRepository repo;

  setUp(() {
    dio = MockDio();
    repo = ExportImportRepository(dio);
  });

  test('exportJson GETs the export endpoint as plain text', () async {
    when(
      () => dio.get<String>(
        '/json-export-import/export',
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => ok('{"accounts":[]}'));

    final json = await repo.exportJson();

    expect(json, '{"accounts":[]}');
    final captured =
        verify(
              () => dio.get<String>(
                '/json-export-import/export',
                options: captureAny(named: 'options'),
              ),
            ).captured.single
            as Options;
    expect(captured.responseType, ResponseType.plain);
  });

  test('exportJson returns empty string when body is null', () async {
    when(
      () => dio.get<String>(
        '/json-export-import/export',
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<String>(
        requestOptions: RequestOptions(path: '/json-export-import/export'),
        statusCode: 200,
        data: null,
      ),
    );

    final json = await repo.exportJson();

    expect(json, '');
  });

  test('exportJson maps DioException to ApiException', () async {
    when(
      () => dio.get<String>(
        '/json-export-import/export',
        options: any(named: 'options'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/json-export-import/export'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.exportJson(), throwsA(isA<NetworkException>()));
  });

  test(
    'importJson POSTs the JSON as a multipart file (backend requires multipart)',
    () async {
      when(
        () => dio.post<void>(
          '/json-export-import/import',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => ok(null));

      await repo.importJson('{"accounts":[]}');

      final captured =
          verify(
                () => dio.post<void>(
                  '/json-export-import/import',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as FormData;
      expect(captured.files, hasLength(1));
      final fileEntry = captured.files.single;
      expect(fileEntry.key, 'file');
      expect(fileEntry.value.filename, 'import.json');
    },
  );

  test('importJson maps DioException to ApiException', () async {
    when(
      () => dio.post<void>(
        '/json-export-import/import',
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/json-export-import/import'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/json-export-import/import'),
          statusCode: 400,
          data: {'error': 'Malformed import'},
        ),
      ),
    );

    expect(
      () => repo.importJson('not json'),
      throwsA(isA<ValidationException>()),
    );
  });
}
