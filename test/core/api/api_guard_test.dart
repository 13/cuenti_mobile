import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/api_guard.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final options = RequestOptions(path: '/anything');

  test('passes a successful result straight through', () async {
    expect(await guardApi(() async => 42), 42);
  });

  test('converts a DioException into the matching ApiException', () async {
    expect(
      () => guardApi<void>(
        () async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<void>(requestOptions: options, statusCode: 401),
        ),
      ),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('turns a malformed payload into a visible server error rather than '
      'an unhandled TypeError', () async {
    expect(
      () => guardApi<int>(() async {
        // What `json['total'] as int` does when the server sends a string.
        const Object value = 'not a number';
        return value as int;
      }),
      throwsA(isA<ServerException>()),
    );
  });

  test('lets a programming error through untouched', () async {
    expect(
      () => guardApi<void>(() async => throw StateError('bug')),
      throwsA(isA<StateError>()),
    );
  });
}
