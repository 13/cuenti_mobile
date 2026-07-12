import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cuentimobile/features/json_converters.dart';

part 'forecast_data.freezed.dart';
part 'forecast_data.g.dart';

@freezed
abstract class MonthForecast with _$MonthForecast {
  const factory MonthForecast({
    required String month, // "YYYY-MM"
    @JsonKey(fromJson: jsonToDouble) @Default(0) double income,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double expense,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double net,
  }) = _MonthForecast;
  factory MonthForecast.fromJson(Map<String, dynamic> json) =>
      _$MonthForecastFromJson(json);
}

@freezed
abstract class ForecastData with _$ForecastData {
  const factory ForecastData({
    required int year,
    @Default([]) List<MonthForecast> months,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double totalIncome,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double totalExpense,
    @JsonKey(fromJson: jsonToDouble) @Default(0) double netForecast,
    @Default('EUR') String currency,
  }) = _ForecastData;
  factory ForecastData.fromJson(Map<String, dynamic> json) =>
      _$ForecastDataFromJson(json);
}
