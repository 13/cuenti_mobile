import 'package:flutter/widgets.dart';

/// Mutable, in-progress row of the splits editor. Backed by
/// [TextEditingController]s so field widgets keep their own cursor and
/// selection state across rebuilds; converted to a TransactionSplit only on
/// save.
class SplitDraft {
  SplitDraft({this.categoryId, String amount = '', String memo = ''})
    : amount = TextEditingController(text: amount),
      memo = TextEditingController(text: memo);

  int? categoryId;
  final TextEditingController amount;
  final TextEditingController memo;

  void dispose() {
    amount.dispose();
    memo.dispose();
  }
}
