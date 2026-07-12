import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cuentimobile/features/json_converters.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_split.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

const kTransactionTypes = ['EXPENSE', 'INCOME', 'TRANSFER'];

const kPaymentMethods = [
  'NONE', 'DEBIT_CARD', 'CASH', 'BANK_TRANSFER', 'STANDING_ORDER',
  'ELECTRONIC_PAYMENT', 'FI_FEE', 'CARD_TRANSACTION', 'TRADE',
  'TRANSFER', 'REWARD', 'INTEREST',
];

@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    int? id,
    @Default('EXPENSE') String type,
    int? fromAccountId,
    String? fromAccountName,
    int? toAccountId,
    String? toAccountName,
    @JsonKey(fromJson: jsonToDouble) required double amount,
    required DateTime transactionDate,
    String? status,
    String? payee,
    int? categoryId,
    String? categoryName,
    String? memo,
    String? tags,
    String? number,
    String? paymentMethod,
    int? assetId,
    String? assetName,
    @JsonKey(fromJson: jsonToDoubleN) double? units,
    @Default(0) int sortOrder,
    @Default([]) List<TransactionSplit> splits,
  }) = _Transaction;

  const Transaction._();

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
