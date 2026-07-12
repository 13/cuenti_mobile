import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cuentimobile/features/json_converters.dart';

part 'transaction_split.freezed.dart';
part 'transaction_split.g.dart';

@freezed
abstract class TransactionSplit with _$TransactionSplit {
  const factory TransactionSplit({
    int? id,
    int? categoryId,
    String? categoryName,
    @JsonKey(fromJson: jsonToDouble) required double amount,
    String? memo,
  }) = _TransactionSplit;

  const TransactionSplit._();

  factory TransactionSplit.fromJson(Map<String, dynamic> json) =>
      _$TransactionSplitFromJson(json);
}
