import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';

part 'transaction_page.freezed.dart';
part 'transaction_page.g.dart';

@freezed
abstract class TransactionPage with _$TransactionPage {
  const factory TransactionPage({
    required List<Transaction> content,
    required int page,
    required int size,
    required int totalElements,
    required int totalPages,
  }) = _TransactionPage;

  const TransactionPage._();

  factory TransactionPage.fromJson(Map<String, dynamic> json) =>
      _$TransactionPageFromJson(json);
}
