import 'dart:convert';
import 'dart:io';

import 'package:cuentimobile/features/categories/domain/category.dart';

/// A response captured from a real Cuenti server, so tests can be held to
/// the shapes it actually sends rather than the ones a model class allows.
///
/// This exists because a fixture written from the model always agrees with
/// the model. The category drill-down was built against categories named by
/// their leaf, shipped in v2.4.0, and stayed broken through v2.7.0 while
/// eighteen tests passed over it -- because this backend names a category by
/// its path and nothing in the suite said so.
Map<String, dynamic> realTransactionEnvelope() =>
    jsonDecode(File('test/fixtures/real_tx_envelope.json').readAsStringSync())
        as Map<String, dynamic>;

/// The distinct, non-null `categoryName` values the captured response holds
/// -- full paths such as `Wohnen:Miete`.
List<String> realCategoryNames() {
  final rows = (realTransactionEnvelope()['content'] as List)
      .cast<Map<String, dynamic>>();
  return {
    for (final row in rows)
      if (row['categoryName'] != null) row['categoryName'] as String,
  }.toList()..sort();
}

/// The category list a server holding [realCategoryNames] would return:
/// every path split into its parts, parents before children, each carrying
/// the `fullName` the real endpoint sends alongside its bare `name`.
List<Category> categoriesForRealNames({String type = 'EXPENSE'}) {
  final ids = <String, int>{};
  final out = <Category>[];
  for (final path in realCategoryNames()) {
    final parts = path.split(':');
    for (var depth = 0; depth < parts.length; depth++) {
      final full = parts.take(depth + 1).join(':');
      if (ids.containsKey(full)) continue;
      final id = ids.length + 1;
      ids[full] = id;
      out.add(
        Category(
          id: id,
          name: parts[depth],
          fullName: full,
          type: type,
          parentId: depth == 0 ? null : ids[parts.take(depth).join(':')],
        ),
      );
    }
  }
  return out;
}
