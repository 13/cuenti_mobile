import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cuentimobile/features/json_converters.dart';

part 'scheduled_transaction.freezed.dart';
part 'scheduled_transaction.g.dart';

const kRecurrencePatterns = [
  'DAILY', 'WEEKLY', 'BI_WEEKLY', 'MONTHLY', 'MONTHLY_LAST_DAY',
  'YEARLY', 'EVERY_FRIDAY', 'EVERY_SATURDAY', 'EVERY_WEEKDAY',
];

@freezed
abstract class ScheduledTransaction with _$ScheduledTransaction {
  const factory ScheduledTransaction({
    int? id,
    @Default('EXPENSE') String type,
    int? fromAccountId,
    String? fromAccountName,
    int? toAccountId,
    String? toAccountName,
    @JsonKey(fromJson: jsonToDouble) required double amount,
    String? payee,
    int? categoryId,
    String? categoryName,
    String? memo,
    String? tags,
    String? number,
    int? assetId,
    String? assetName,
    @JsonKey(fromJson: jsonToDoubleN) double? units,
    @Default('MONTHLY') String recurrencePattern,
    int? recurrenceValue,
    required DateTime nextOccurrence,
    @Default(true) bool enabled,
  }) = _ScheduledTransaction;

  const ScheduledTransaction._();

  factory ScheduledTransaction.fromJson(Map<String, dynamic> json) =>
      _$ScheduledTransactionFromJson(json);
}
