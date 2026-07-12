import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cuentimobile/features/json_converters.dart';

part 'statistics_data.freezed.dart';
part 'statistics_data.g.dart';

@freezed
abstract class StatisticsData with _$StatisticsData {
  const factory StatisticsData({
    @JsonKey(fromJson: jsonToDouble) required double totalIncome,
    @JsonKey(fromJson: jsonToDouble) required double totalExpense,
    @JsonKey(fromJson: jsonToDouble) required double balance,
    @Default('EUR') String currency,
    @JsonKey(fromJson: jsonToDoubleMap) @Default({}) Map<String, double> incomeByCategory,
    @JsonKey(fromJson: jsonToDoubleMap) @Default({}) Map<String, double> expenseByCategory,
    @JsonKey(fromJson: jsonToDoubleMap) @Default({}) Map<String, double> monthlyIncome,
    @JsonKey(fromJson: jsonToDoubleMap) @Default({}) Map<String, double> monthlyExpense,
    @Default(0) int transactionCount,
  }) = _StatisticsData;

  const StatisticsData._();

  factory StatisticsData.fromJson(Map<String, dynamic> json) =>
      _$StatisticsDataFromJson(json);
}
