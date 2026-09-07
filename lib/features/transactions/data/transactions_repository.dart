import 'dart:math' show min;

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/api_guard.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/api/offline_cache_interceptor.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => TransactionsRepository(
    ref.watch(dioProvider),
    // A closure, not a value: `ApiClient` attaches the interceptor after
    // init() returns, so the one this provider could capture now is almost
    // always null. Do not "simplify" this to
    // `ref.watch(apiClientProvider).offlineCache`.
    offlineCache: () => ref.read(apiClientProvider).offlineCache,
  ),
);

class TransactionsRepository {
  TransactionsRepository(this._dio, {this.offlineCache});
  final Dio _dio;

  /// The read cache, looked up when asked for rather than held, and null
  /// where there is none -- which simply disables the fallback below.
  final OfflineCacheInterceptor? Function()? offlineCache;

  /// How far back through the cached pages [_fromCache] walks. Twenty pages
  /// of fifty is a thousand rows, more than the response cache's entry cap
  /// would ever hold for one query, and a bound so a corrupt envelope
  /// claiming a million pages cannot spin here.
  static const _maxCachedPages = 20;

  /// The query the server is asked for and -- unchanged, key for key -- the
  /// query [_fromCache] hashes to find what was cached. One function,
  /// because a single key's difference would turn every cache lookup into a
  /// silent miss.
  ///
  /// [size] is part of that key too, so the fallback only ever finds pages
  /// fetched at the same page size.
  static Map<String, dynamic> queryFor(
    TransactionFilter filter, {
    required int page,
    required int size,
  }) {
    final df = DateFormat('yyyy-MM-dd');
    return {
      if (filter.accountId != null) 'accountId': filter.accountId,
      if (filter.type != null) 'type': filter.type,
      if (filter.categoryId != null) 'categoryId': filter.categoryId,
      if (filter.start != null) 'start': df.format(filter.start!),
      if (filter.end != null) 'end': df.format(filter.end!),
      if (filter.search != null && filter.search!.isNotEmpty)
        'search': filter.search,
      'page': page,
      'size': size,
    };
  }

  /// Paged fetch using the Phase 1 envelope. Tolerates legacy (pre-pagination)
  /// servers that respond with a plain JSON array instead of the paged
  /// envelope: `res.data` is requested as `dynamic` and branched on shape
  /// rather than statically cast, since a legacy server's plain-array
  /// response would otherwise surface as an unhandled TypeError.
  Future<TransactionPage> getPage({
    TransactionFilter filter = const TransactionFilter(),
    int page = 0,
    int size = 50,
  }) => guardApi(() async {
    try {
      final res = await _dio.get<dynamic>(
        '/transactions',
        queryParameters: queryFor(filter, page: page, size: size),
      );
      return _parseEnvelope(res.data, page: page, size: size);
    } on DioException catch (e) {
      // The cache interceptor has already had its turn and could not help:
      // it replays only an exact key hit, and `?type=TRANSFER` is a
      // different key from the unfiltered list this app actually fetches.
      // Same offline test it applies, deliberately not a looser one.
      if (!OfflineCacheInterceptor.isOfflineFailure(e)) rethrow;
      final local = await _fromCache(filter: filter, page: page, size: size);
      if (local == null) rethrow;
      return local;
    }
  });

  /// A page of transactions cut, on the device, out of a wider list this
  /// device has already been given.
  ///
  /// Every row returned is a row the server handed this client, verbatim.
  /// Nothing is computed, estimated or averaged: the predicate applied is
  /// [TransactionFilterMatch.matches], the same one that decides whether a
  /// queued create belongs in a list, and a filtered list is by construction
  /// a subset of an unfiltered one. That is why this does not contradict the
  /// rule in `offline_cache_interceptor.dart` -- it never substitutes one
  /// endpoint's answer for another's, and it never invents a number.
  ///
  /// Returns null rather than guessing.
  Future<TransactionPage?> _fromCache({
    required TransactionFilter filter,
    required int page,
    required int size,
  }) async {
    final cache = offlineCache?.call();
    if (cache == null) return null;

    // Narrowest first: a list already narrowed by account or date holds less
    // of the corpus but more of the answer, so it runs out later. A set
    // literal, because for an already-unfiltered request the two collapse.
    final bases = {
      filter.copyWith(type: null, search: null),
      const TransactionFilter(),
    };

    for (final base in bases) {
      final rows = <Transaction>[];
      DateTime? oldest;
      var complete = false;
      for (var p = 0; p < _maxCachedPages; p++) {
        final hit = await cache.peek(
          RequestOptions(
            path: '/transactions',
            queryParameters: queryFor(base, page: p, size: size),
          ),
        );
        // A hole ends the walk. Never assembled across one: a list with a
        // gap in the middle reads as data loss, with nothing to say so.
        if (hit == null) break;
        final parsed = _tryParseCached(hit.body, page: p, size: size);
        if (parsed == null) break;
        if (oldest == null || hit.storedAt.isBefore(oldest)) {
          oldest = hit.storedAt;
        }
        rows.addAll(parsed.content);
        if (p + 1 >= parsed.totalPages) {
          complete = true;
          break;
        }
      }
      if (rows.isEmpty) continue;

      final matched = [
        for (final t in rows)
          if (filter.matches(t)) t,
      ]..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      // Nothing matched, out of a corpus we know is only a prefix. That is
      // not "you have no transfers", it is "we do not know" -- and absence
      // is the one claim a truncated prefix cannot support. Try the next
      // base, and failing that let the error show.
      if (matched.isEmpty && !complete) continue;

      final start = page * size;
      final slice = start >= matched.length
          ? const <Transaction>[]
          : matched.sublist(start, min(start + size, matched.length));
      cache.markStale(oldest!);
      return TransactionPage(
        content: slice,
        page: page,
        size: size,
        // What this device holds, not what exists. Where [complete] is false
        // these undercount, deliberately: a total this cannot back with rows
        // would put a "load more" spinner in front of a page that can never
        // arrive.
        totalElements: matched.length,
        totalPages: matched.isEmpty ? 0 : (matched.length + size - 1) ~/ size,
      );
    }
    return null;
  }

  static TransactionPage _parseEnvelope(
    dynamic data, {
    required int page,
    required int size,
  }) {
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
  }

  static TransactionPage? _tryParseCached(
    Object? body, {
    required int page,
    required int size,
  }) {
    try {
      return _parseEnvelope(body, page: page, size: size);
      // A cached body we cannot read is a miss, the same as one that is not
      // there -- never a reason to fail differently. `fromJson` throws
      // TypeError, not Exception, on a shape that has moved on.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  /// [splitsTouched]: the caller explicitly manages splits. When false
  /// (default) the splits key is stripped for backend back-compat (omitted =
  /// unchanged server-side). When true, t.splits is sent verbatim — an empty
  /// list means deliberate remove-all.
  Future<Transaction> save(Transaction t, {bool splitsTouched = false}) =>
      guardApi(() async {
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
              .map(
                (s) => {
                  'categoryId': s.categoryId,
                  'amount': s.amount,
                  if (s.memo != null) 'memo': s.memo,
                },
              )
              .toList();
        }
        final res = t.id != null
            ? await _dio.put<Map<String, dynamic>>(
                '/transactions/${t.id}',
                data: json,
              )
            : await _dio.post<Map<String, dynamic>>(
                '/transactions',
                data: json,
              );
        return Transaction.fromJson(res.data!);
      });

  Future<void> delete(int id) =>
      guardApi(() => _dio.delete<void>('/transactions/$id'));
}
