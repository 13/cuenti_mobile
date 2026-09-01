import 'package:cuentimobile/features/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset_performance.freezed.dart';
part 'asset_performance.g.dart';

@freezed
abstract class AssetPerformance with _$AssetPerformance {
  const factory AssetPerformance({
    @JsonKey(fromJson: jsonToDouble) required double totalUnits, @JsonKey(fromJson: jsonToDouble) required double totalCost, @JsonKey(fromJson: jsonToDouble) required double currentValue, @JsonKey(fromJson: jsonToDouble) required double currentPrice, @JsonKey(fromJson: jsonToDouble) required double gainLoss, @JsonKey(fromJson: jsonToDouble) required double gainLossPercent, @Default('') String assetName,
    @Default('') String assetSymbol,
  }) = _AssetPerformance;

  const AssetPerformance._();

  factory AssetPerformance.fromJson(Map<String, dynamic> json) =>
      _$AssetPerformanceFromJson(json);
}
