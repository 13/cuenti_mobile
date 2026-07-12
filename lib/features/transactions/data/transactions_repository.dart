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

  /// Paged fetch using the Phase 1 envelope.
  Future<TransactionPage> getPage({
    TransactionFilter filter = const TransactionFilter(),
    int page = 0,
    int size = 50,
  }) =>
      _guard(() async {
        final df = DateFormat('yyyy-MM-dd');
        final res = await _dio.get<Map<String, dynamic>>('/transactions',
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
        return TransactionPage.fromJson(res.data!);
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
  }
}
