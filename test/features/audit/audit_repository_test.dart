import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/audit/data/audit_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late AuditRepository repo;

  setUp(() {
    dio = MockDio();
    repo = AuditRepository(dio);
  });

  test('getPage parses audit entries with filter', () async {
    when(() => dio.get<Map<String, dynamic>>('/audit-log', queryParameters: {
          'filter': 'admin',
          'page': 0,
          'size': 50,
        })).thenAnswer((_) async => ok({
          'content': [
            {
              'id': 1,
              'userId': 1,
              'username': 'admin',
              'timestamp': '2026-01-01T10:00:00Z',
              'entityType': 'Transaction',
              'entityId': 10,
              'action': 'CREATE',
              'details': 'Created transaction',
            },
          ],
          'page': 0,
          'size': 50,
          'totalElements': 1,
          'totalPages': 1,
        }));

    final page = await repo.getPage(page: 0, size: 50, filter: 'admin');

    expect(page.content, hasLength(1));
    expect(page.content[0].id, 1);
    expect(page.content[0].username, 'admin');
    expect(page.totalPages, 1);
  });

  test('getPage omits filter when null', () async {
    when(() => dio.get<Map<String, dynamic>>('/audit-log',
        queryParameters: {
          'page': 0,
          'size': 50,
        })).thenAnswer((_) async => ok({
      'content': <dynamic>[],
      'page': 0,
      'size': 50,
      'totalElements': 0,
      'totalPages': 0,
    }));

    await repo.getPage(page: 0, size: 50, filter: null);

    final captured = verify(() => dio.get<Map<String, dynamic>>('/audit-log',
        queryParameters:
            captureAny(named: 'queryParameters'))).captured.single;
    expect(captured.containsKey('filter'), isFalse);
  });

  test('getPage omits filter when empty string', () async {
    when(() => dio.get<Map<String, dynamic>>('/audit-log',
        queryParameters: {
          'page': 0,
          'size': 50,
        })).thenAnswer((_) async => ok({
      'content': <dynamic>[],
      'page': 0,
      'size': 50,
      'totalElements': 0,
      'totalPages': 0,
    }));

    await repo.getPage(page: 0, size: 50, filter: '');

    final captured = verify(() => dio.get<Map<String, dynamic>>('/audit-log',
        queryParameters:
            captureAny(named: 'queryParameters'))).captured.single;
    expect(captured.containsKey('filter'), isFalse);
  });

  test('getPage maps DioException to ApiException', () async {
    when(() => dio.get<Map<String, dynamic>>('/audit-log',
            queryParameters: any(named: 'queryParameters')))
        .thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/audit-log'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getPage(), throwsA(isA<NetworkException>()));
  });
}
