import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/transaction.dart';
import '../domain/transaction_filter.dart';
import '../domain/transaction_page.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
    (ref) => TransactionsRepository(ref.watch(dioProvider)));

class TransactionsRepository {
  TransactionsRepository(this._dio);
  final Dio _dio;

  /// Paged fetch using the Phase 1 envelope. Tolerates legacy (pre-pagination)
  /// servers that respond with a plain JSON array instead of the paged
  /// envelope: `res.data` is requested as `dynamic` and branched on shape
  /// rather than statically cast, since a legacy server's plain-array
  /// response would otherwise surface as an unhandled TypeError.
  Future<TransactionPage> getPage({
    TransactionFilter filter = const TransactionFilter(),
    int page = 0,
    int size = 50,
  }) =>
      _guard(() async {
        final df = DateFormat('yyyy-MM-dd');
        final res = await _dio.get<dynamic>('/transactions',
            queryParameters: {
              if (filter.accountId != null) 'accountId': filter.accountId,
              if (filter.type != null) 'type': filter.type,
              if (filter.categoryId != null) 'categoryId': filter.categoryId,
              if (filter.start != null) 'start': df.format(filter.start!),
              if (filter.end != null) 'end': df.format(filter.end!),
              if (filter.search != null && filter.search!.isNotEmpty)
                'search': filter.search,
              'page': page,
              'size': size,
            });
        final data = res.data;
        if (data is List) {
          // Legacy server predating the pagination API: a single,
          // already-exhausted page. Filters/search are still sent above but
          // silently ignored by old servers.
          final content = data
              .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList();
          return TransactionPage(
            content: content,
            page: page,
            size: size,
            totalElements: content.length,
            totalPages: 1,
          );
        }
        if (data is Map<String, dynamic>) {
          return TransactionPage.fromJson(data);
        }
        throw const ServerException('Unexpected response from server');
      });

  /// [splitsTouched]: the caller explicitly manages splits. When false
  /// (default) the splits key is stripped for backend back-compat (omitted =
  /// unchanged server-side). When true, t.splits is sent verbatim — an empty
  /// list means deliberate remove-all.
  Future<Transaction> save(Transaction t, {bool splitsTouched = false}) =>
      _guard(() async {
        final json = t.toJson()
          ..remove('id')
          ..remove('fromAccountName')
          ..remove('toAccountName')
          ..remove('categoryName')
          ..remove('assetName')
          ..remove('status');
        json['paymentMethod'] = t.paymentMethod ?? 'NONE';
        if (!splitsTouched) {
          json.remove('splits');
        } else {
          json['splits'] = t.splits
              .map((s) => {
                    'categoryId': s.categoryId,
                    'amount': s.amount,
                    if (s.memo != null) 'memo': s.memo,
                  })
              .toList();
        }
        final res = t.id != null
            ? await _dio.put<Map<String, dynamic>>(
                '/transactions/${t.id}', data: json)
            : await _dio.post<Map<String, dynamic>>('/transactions',
                data: json);
        return Transaction.fromJson(res.data!);
      });

  Future<void> delete(int id) =>
      _guard(() => _dio.delete<void>('/transactions/$id'));
}

/// Shared guard: rethrows DioException as ApiException. Copy this exact
/// helper into each repository file (3 lines; a shared base class would
/// couple repositories for no gain).
Future<T> _guard<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  } on TypeError catch (_) {
    // A malformed/unexpected payload (e.g. a legacy server's response shape
    // changing mid-migration) becomes a visible error card instead of an
    // unhandled error escaping to the UI.
    throw const ServerException('Unexpected response from server');
  }
}
