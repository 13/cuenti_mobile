import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds the DioException shape `ApiException.fromDio` actually receives
/// for a response the server answered with.
DioException badResponse(int status, dynamic body) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.badResponse,
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: body,
  ),
);

void main() {
  group('fromDio keeps what the server said', () {
    test('a JSON error body becomes serverMessage, not just message', () {
      final e = ApiException.fromDio(
        badResponse(422, {'error': 'Amount must be positive'}),
      );

      expect(e, isA<ValidationException>());
      expect(e.message, 'Amount must be positive');
      expect(e.serverMessage, 'Amount must be positive');
      expect(e.statusCode, 422);
    });

    test('a bare string body is taken as the explanation too', () {
      final e = ApiException.fromDio(badResponse(400, 'Missing account'));

      expect(e.message, 'Missing account');
      expect(e.serverMessage, 'Missing account');
      expect(e.statusCode, 400);
    });

    test('a body that explains nothing leaves serverMessage null', () {
      final e = ApiException.fromDio(badResponse(500, <String, dynamic>{}));

      expect(e, isA<ServerException>());
      expect(e.serverMessage, isNull);
      expect(e.statusCode, 500);
    });

    test('an empty string body is not an explanation', () {
      final e = ApiException.fromDio(badResponse(400, ''));

      expect(e.serverMessage, isNull);
    });

    // Without the `msg.isNotEmpty` guard on the JSON branch, an empty
    // string would read as "the server explained itself" -- an empty
    // frame quoting nothing.
    test('a JSON body with an empty error string is not an explanation', () {
      final e = ApiException.fromDio(badResponse(400, {'error': ''}));

      expect(e.serverMessage, isNull);
    });

    // 403 carries the status so localizedMessage can tell "the API is
    // switched off" from "your session expired" -- two things that read
    // identically without it.
    test('403 carries its status', () {
      final e = ApiException.fromDio(badResponse(403, null));

      expect(e, isA<UnauthorizedException>());
      expect(e.statusCode, 403);
    });

    test('401 carries its status', () {
      final e = ApiException.fromDio(badResponse(401, null));

      expect(e, isA<UnauthorizedException>());
      expect(e.statusCode, 401);
    });

    // A misconfigured reverse proxy answers with a whole HTML page. That
    // string is about to be shown to a user inside a snackbar.
    test('an overlong body is truncated', () {
      final e = ApiException.fromDio(badResponse(400, 'x' * 5000));

      expect(e.serverMessage!.length, lessThanOrEqualTo(201));
      expect(e.serverMessage, endsWith('…'));
    });

    test('a body at the limit is not given an ellipsis', () {
      final e = ApiException.fromDio(badResponse(400, 'x' * 200));

      expect(e.serverMessage, 'x' * 200);
    });

    test('a connection failure has no server message or status', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(e, isA<NetworkException>());
      expect(e.message, 'Cannot connect to server');
      expect(e.serverMessage, isNull);
      expect(e.statusCode, isNull);
    });
  });

  group('fromDio maps exception types', () {
    test('a timeout maps to NetworkException', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      expect(e, isA<NetworkException>());
    });

    test('cancel/unknown maps to UnknownApiException', () {
      final e = ApiException.fromDio(
        DioException(requestOptions: RequestOptions(path: '/x')),
      );

      expect(e, isA<UnknownApiException>());
    });
  });
}
