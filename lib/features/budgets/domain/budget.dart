import 'package:cuentimobile/features/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

@freezed
abstract class Budget with _$Budget {
  const factory Budget({
    required int categoryId, int? id,
    String? categoryName,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double monthlyLimit,
    @Default(true) bool active,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) =>
      _$BudgetFromJson(json);
}
