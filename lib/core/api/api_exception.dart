import 'package:dio/dio.dart';

/// Typed API error. Repositories throw only this; DioException never
/// escapes the data layer.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

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
              serverMessage ?? 'API access is not enabled');
        }
        if (status >= 400 && status < 500) {
          return ValidationException(serverMessage ?? 'Invalid request');
        }
        return ServerException(serverMessage ?? 'Server error ($status)');
      case DioExceptionType.badCertificate:
        return const NetworkException(
            'SSL certificate error. Install the server certificate on your device.');
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return UnknownApiException(e.message ?? 'An error occurred');
    }
  }

  @override
  String toString() => message;
}

final class NetworkException extends ApiException {
  const NetworkException(super.message);
}

final class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message);
}

final class ValidationException extends ApiException {
  const ValidationException(super.message);
}

final class ServerException extends ApiException {
  const ServerException(super.message);
}

final class UnknownApiException extends ApiException {
  const UnknownApiException(super.message);
}
