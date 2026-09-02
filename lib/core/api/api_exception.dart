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
        final serverMessage = switch (body) {
          {'error': final String msg} => msg,
          final String s when s.isNotEmpty => s,
          _ => null,
        };
        if (status == 401) {
          return UnauthorizedException(serverMessage ?? 'Not authenticated');
        }
        if (status == 403) {
          return UnauthorizedException(
            serverMessage ?? 'API access is not enabled',
          );
        }
        if (status >= 400 && status < 500) {
          return ValidationException(serverMessage ?? 'Invalid request');
        }
        return ServerException(serverMessage ?? 'Server error ($status)');
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
  /// server's own language, so it is shown as-is rather than translated.
  final String? serverMessage;

  final int? statusCode;

  /// The message to put in front of the user.
  ///
  /// A server that explained itself is quoted verbatim -- it knows why it
  /// refused and this client does not. Only the fallbacks, written here, are
  /// translated.
  String localizedMessage(L l) {
    final fromServer = serverMessage;
    if (fromServer != null && fromServer.isNotEmpty) return fromServer;
    return switch (this) {
      NetworkException() =>
        message == _certificateMessage ? l.errorCertificate : l.errorNetwork,
      UnauthorizedException() => switch (this) {
        _ when message == invalidCredentialsMessage =>
          l.errorInvalidCredentials,
        _ when statusCode == 403 => l.errorApiDisabled,
        _ => l.errorNotAuthenticated,
      },
      ValidationException() => l.errorInvalidRequest,
      ServerException() =>
        statusCode == null
            ? l.errorUnexpectedResponse
            : l.errorServer('$statusCode'),
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
