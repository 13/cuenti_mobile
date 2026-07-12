import 'package:freezed_annotation/freezed_annotation.dart';
import '../../json_converters.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

@freezed
abstract class Budget with _$Budget {
  const factory Budget({
    int? id,
    required int categoryId,
    String? categoryName,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double monthlyLimit,
    @Default(true) bool active,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) =>
      _$BudgetFromJson(json);
}
