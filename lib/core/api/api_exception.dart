import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

/// Typed API error. Repositories throw only this; DioException never
/// escapes the data layer.
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.serverMessage, this.statusCode});

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException('Cannot connect to server');
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        final body = e.response?.data;
        final raw = switch (body) {
          {'error': final String msg} when msg.isNotEmpty => msg,
          final String s when s.isNotEmpty => s,
          _ => null,
        };
        // This string is shown to a user now, and a misconfigured reverse
        // proxy answers with an entire HTML page. Cut it here, once, so
        // every consumer gets the same rule.
        final serverMessage =
            raw == null || raw.length <= maxServerMessageLength
            ? raw
            : '${raw.substring(0, maxServerMessageLength)}…';
        if (status == 401) {
          return UnauthorizedException(
            serverMessage ?? 'Not authenticated',
            serverMessage: serverMessage,
            statusCode: status,
          );
        }
        if (status == 403) {
          return UnauthorizedException(
            serverMessage ?? 'API access is not enabled',
            serverMessage: serverMessage,
            statusCode: status,
          );
        }
        if (status >= 400 && status < 500) {
          return ValidationException(
            serverMessage ?? 'Invalid request',
            serverMessage: serverMessage,
            statusCode: status,
          );
        }
        return ServerException(
          serverMessage ?? 'Server error ($status)',
          serverMessage: serverMessage,
          statusCode: status,
        );
      case DioExceptionType.badCertificate:
        return const NetworkException(_certificateMessage);
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return UnknownApiException(e.message ?? 'An error occurred');
    }
  }

  /// English, for logs and tests. [localizedMessage] is what the UI shows.
  final String message;

  /// What the server itself said, when it said anything. Already in the
  /// server's own language, so it is shown as-is rather than translated --
  /// though [localizedMessage] may frame it inside a translated sentence
  /// for [ValidationException] and [ServerException].
  final String? serverMessage;

  final int? statusCode;

  /// The message to put in front of the user.
  ///
  /// Where the server's own sentence tells the user something this client
  /// cannot -- which field it rejected, which upstream is down -- it is
  /// quoted inside a translated frame, so the words around it are in the
  /// user's language even when the server's are not. Everything else is
  /// translated outright: a 401's "Not authenticated" or a connection
  /// failure adds nothing over the string written here, and 403 has a
  /// specific one that is better than anything the server will say.
  String localizedMessage(L l) {
    final detail = serverMessage;
    final explained = detail != null && detail.isNotEmpty;
    return switch (this) {
      NetworkException() =>
        message == _certificateMessage ? l.errorCertificate : l.errorNetwork,
      UnauthorizedException() => switch (this) {
        _ when message == invalidCredentialsMessage =>
          l.errorInvalidCredentials,
        _ when statusCode == 403 => l.errorApiDisabled,
        _ => l.errorNotAuthenticated,
      },
      ValidationException() =>
        explained ? l.errorInvalidRequestDetail(detail) : l.errorInvalidRequest,
      ServerException() => switch (statusCode) {
        null => l.errorUnexpectedResponse,
        final status when explained => l.errorServerDetail('$status', detail),
        final status => l.errorServer('$status'),
      },
      UnknownApiException() => l.errorUnknown,
    };
  }

  @override
  String toString() => message;
}

/// A 401 from the login endpoint means the credentials were wrong, not that
/// a session expired -- two things an [UnauthorizedException] would
/// otherwise report identically. Kept as a constant so the repository that
/// raises it, the controller that special-cases it, and
/// [ApiException.localizedMessage] all agree on the one spelling.
const invalidCredentialsMessage = 'Invalid username or password';

/// Kept as a constant so [ApiException.localizedMessage] can tell a
/// certificate refusal from an ordinary connection failure without adding a
/// subtype for it.
const _certificateMessage =
    'The server certificate is not trusted. Re-run Server Setup to '
    'check its fingerprint and trust it.';

/// How much of the server's own explanation is worth putting in front of a
/// user. A body long enough to matter is an HTML error page, not a sentence.
const maxServerMessageLength = 200;

final class NetworkException extends ApiException {
  const NetworkException(
    super.message, {
    super.serverMessage,
    super.statusCode,
  });
}

final class UnauthorizedException extends ApiException {
  const UnauthorizedException(
    super.message, {
    super.serverMessage,
    super.statusCode,
  });
}

final class ValidationException extends ApiException {
  const ValidationException(
    super.message, {
    super.serverMessage,
    super.statusCode,
  });
}

final class ServerException extends ApiException {
  const ServerException(super.message, {super.serverMessage, super.statusCode});
}

final class UnknownApiException extends ApiException {
  const UnknownApiException(
    super.message, {
    super.serverMessage,
    super.statusCode,
  });
}
