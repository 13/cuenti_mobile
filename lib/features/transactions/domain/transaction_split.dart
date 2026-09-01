import 'package:cuentimobile/features/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_split.freezed.dart';
part 'transaction_split.g.dart';

@freezed
abstract class TransactionSplit with _$TransactionSplit {
  const factory TransactionSplit({
    @JsonKey(fromJson: jsonToDouble) required double amount,
    int? id,
    int? categoryId,
    String? categoryName,
    String? memo,
  }) = _TransactionSplit;

  const TransactionSplit._();

  factory TransactionSplit.fromJson(Map<String, dynamic> json) =>
      _$TransactionSplitFromJson(json);
}
