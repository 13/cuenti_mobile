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
