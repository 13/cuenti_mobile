import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/l10n/app_localizations_de.dart';
import 'package:cuentimobile/l10n/app_localizations_en.dart';
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

  group('localizedMessage', () {
    final en = LEn();
    final de = LDe();

    test('a 4xx quotes the server inside a translated frame', () {
      final e = ApiException.fromDio(
        badResponse(422, {'error': 'Amount must be positive'}),
      );

      expect(
        e.localizedMessage(en),
        'Invalid request: Amount must be positive',
      );
      expect(
        e.localizedMessage(de),
        'Ungültige Anfrage: Amount must be positive',
      );
    });

    test('a 4xx with no explanation keeps the plain translated string', () {
      final e = ApiException.fromDio(badResponse(400, null));

      expect(e.localizedMessage(en), 'Invalid request');
      expect(e.localizedMessage(de), 'Ungültige Anfrage');
    });

    test('a 5xx names its status and quotes the server', () {
      final e = ApiException.fromDio(badResponse(503, 'Upstream down'));

      expect(e.localizedMessage(en), 'Server error (503): Upstream down');
    });

    // Dead before this change: statusCode was always null, so every 5xx
    // took the "unexpected response" branch instead.
    test('a 5xx with no explanation names its status', () {
      final e = ApiException.fromDio(badResponse(500, null));

      expect(e.localizedMessage(en), 'Server error (500)');
    });

    // Dead before this change: without statusCode, a switched-off API read
    // as an expired session and sent the user after a password problem.
    test('403 says the API is not enabled, not that you are signed out', () {
      final e = ApiException.fromDio(badResponse(403, null));

      expect(e.localizedMessage(en), 'API access is not enabled');
    });

    test('401 stays the translated string even when the server spoke', () {
      final e = ApiException.fromDio(badResponse(401, 'JWT expired'));

      expect(e.localizedMessage(en), 'Not authenticated');
      expect(e.localizedMessage(de), 'Nicht angemeldet');
    });

    test('a network failure is translated, never quoted', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(e.localizedMessage(de), 'Keine Verbindung zum Server');
    });

    test('the truncated body is what the user is shown', () {
      final e = ApiException.fromDio(badResponse(400, 'y' * 5000));

      expect(e.localizedMessage(en).length, lessThan(230));
      expect(e.localizedMessage(en), endsWith('…'));
    });
  });
}
