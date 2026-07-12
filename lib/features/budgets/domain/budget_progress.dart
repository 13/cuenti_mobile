import 'package:freezed_annotation/freezed_annotation.dart';
import '../../json_converters.dart';

part 'budget_progress.freezed.dart';
part 'budget_progress.g.dart';

@freezed
abstract class BudgetProgress with _$BudgetProgress {
  const factory BudgetProgress({
    required int budgetId,
    required int categoryId,
    String? categoryName,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double monthlyLimit,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double spent,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double remaining,
    @Default(true) bool active,
  }) = _BudgetProgress;

  factory BudgetProgress.fromJson(Map<String, dynamic> json) =>
      _$BudgetProgressFromJson(json);
}
