import 'dart:convert';

import 'package:intl/intl.dart';

import 'transaction_filter.dart';

/// Serializes TransactionFilter into the opaque `params` string stored by
/// the saved-views API. Versioned envelope: {"v":1,"accountId":…,…}.
/// [decode] never throws: it returns null for anything it doesn't
/// understand (e.g. params written by the web app, or a v1 envelope with
/// wrong-typed or malformed fields).
abstract final class TransactionFilterCodec {
  static String encode(TransactionFilter f) => jsonEncode({
        'v': 1,
        if (f.accountId != null) 'accountId': f.accountId,
        if (f.type != null) 'type': f.type,
        if (f.categoryId != null) 'categoryId': f.categoryId,
        if (f.start != null)
          'start': DateFormat('yyyy-MM-dd').format(f.start!),
        if (f.end != null) 'end': DateFormat('yyyy-MM-dd').format(f.end!),
        if (f.search != null && f.search!.isNotEmpty) 'search': f.search,
      });

  static TransactionFilter? decode(String? params) {
    if (params == null || params.isEmpty) return null;
    try {
      final decoded = jsonDecode(params);
      if (decoded is! Map<String, dynamic> || decoded['v'] != 1) return null;
      return TransactionFilter(
        accountId: decoded['accountId'] as int?,
        type: decoded['type'] as String?,
        categoryId: decoded['categoryId'] as int?,
        start: decoded['start'] != null
            ? DateTime.parse(decoded['start'] as String)
            : null,
        end: decoded['end'] != null
            ? DateTime.parse(decoded['end'] as String)
            : null,
        search: decoded['search'] as String?,
      );
      // Defensive parser: any failure (bad JSON, wrong-typed fields, bad
      // dates) means the params weren't written by this codec.
    } catch (_) {
      return null;
    }
  }
}
