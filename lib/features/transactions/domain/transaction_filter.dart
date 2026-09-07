import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_filter.freezed.dart';

/// Server-side query filter for paged transaction fetches. Equality
/// (freezed-generated) is what keys the `transactionsControllerProvider`
/// family — a new filter value creates a distinct provider instance.
@freezed
abstract class TransactionFilter with _$TransactionFilter {
  const factory TransactionFilter({
    int? accountId,
    String? type, // EXPENSE | INCOME | TRANSFER
    int? categoryId,
    DateTime? start, // date-only; sent as yyyy-MM-dd
    DateTime? end,
    String? search,
  }) = _TransactionFilter;
}

extension TransactionFilterMatch on TransactionFilter {
  /// Whether [t] belongs in a list showing this filter, decided on the
  /// device rather than at the server.
  ///
  /// Two callers need this and neither can ask the server: a queued create
  /// the server has never seen, and -- offline -- a filtered list cut
  /// locally out of an unfiltered one already in cache. Both are better off
  /// agreeing on one rule than drifting apart.
  ///
  /// Where this and the server could disagree it is on [search], taken here
  /// as a case-insensitive substring of the payee or the memo -- narrower
  /// than the server may be, and narrow in the safe direction: a row hidden
  /// from a search is still on the list with no search at all.
  bool matches(Transaction t) {
    final accountId = this.accountId;
    if (accountId != null &&
        t.fromAccountId != accountId &&
        t.toAccountId != accountId) {
      return false;
    }
    if (type != null && t.type != type) return false;
    if (categoryId != null && t.categoryId != categoryId) return false;
    // start/end are date-only on the wire, so the comparison is too --
    // an entry made at 18:00 is inside a range ending that same day.
    DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
    final day = dayOf(t.transactionDate);
    final start = this.start;
    if (start != null && day.isBefore(dayOf(start))) return false;
    final end = this.end;
    if (end != null && day.isAfter(dayOf(end))) return false;
    final search = this.search;
    if (search != null && search.isNotEmpty) {
      final needle = search.toLowerCase();
      final found = [
        t.payee,
        t.memo,
      ].whereType<String>().any((s) => s.toLowerCase().contains(needle));
      if (!found) return false;
    }
    return true;
  }
}
