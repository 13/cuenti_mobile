import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException dioError({
  DioExceptionType type = DioExceptionType.badResponse,
  int? status,
  dynamic body,
}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  test('connection error maps to NetworkException', () {
    final e = ApiException.fromDio(
        dioError(type: DioExceptionType.connectionError));
    expect(e, isA<NetworkException>());
    expect(e.message, 'Cannot connect to server');
  });

  test('timeout maps to NetworkException', () {
    final e = ApiException.fromDio(
        dioError(type: DioExceptionType.receiveTimeout));
    expect(e, isA<NetworkException>());
  });

  test('401 maps to UnauthorizedException', () {
    final e = ApiException.fromDio(dioError(status: 401));
    expect(e, isA<UnauthorizedException>());
  });

  test('400 with error body surfaces server message', () {
    final e = ApiException.fromDio(
        dioError(status: 400, body: {'error': 'Split amounts must sum'}));
    expect(e, isA<ValidationException>());
    expect(e.message, 'Split amounts must sum');
  });

  test('400 with string body surfaces it', () {
    final e = ApiException.fromDio(dioError(status: 400, body: 'Bad input'));
    expect(e.message, 'Bad input');
  });

  test('500 maps to ServerException', () {
    final e = ApiException.fromDio(dioError(status: 500));
    expect(e, isA<ServerException>());
  });

  test('no response maps to UnknownApiException', () {
    final e = ApiException.fromDio(dioError(type: DioExceptionType.unknown));
    expect(e, isA<UnknownApiException>());
  });
}
