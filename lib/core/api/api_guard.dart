import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:dio/dio.dart';

/// Runs a repository call and turns transport and payload failures into the
/// [ApiException] family the UI knows how to render.
///
/// This lived as a copy-pasted `_guard` in every repository, on the
/// reasoning that a shared base class would couple them for no gain. That
/// was true of a base class but not of a function: nothing here couples one
/// repository to another, while the copies had already drifted -- seventeen
/// identical, one that had learned to handle malformed payloads and could
/// not share the lesson, and auth, which mapped DioException by hand in
/// every method and so never gained the payload handling at all.
Future<T> guardApi<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
    // A malformed or unexpected payload (a legacy server's response shape
    // changing mid-migration, say) becomes a visible error card instead of
    // an unhandled Error escaping to the UI. Deliberately catching an Error
    // subclass: the fault is the server's contract, not this client.
    // ignore: avoid_catching_errors
  } on TypeError catch (_) {
    throw const ServerException('Unexpected response from server');
  }
}
