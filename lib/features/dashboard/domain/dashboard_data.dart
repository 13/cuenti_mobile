import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cuentimobile/features/json_converters.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/dashboard/domain/asset_performance.dart';

part 'dashboard_data.freezed.dart';
part 'dashboard_data.g.dart';

@freezed
abstract class DashboardData with _$DashboardData {
  const factory DashboardData({
    @JsonKey(fromJson: jsonToDouble) required double availableCash,
    @JsonKey(fromJson: jsonToDouble) required double portfolioValue,
    @JsonKey(fromJson: jsonToDouble) required double netWorth,
    @Default('EUR') String defaultCurrency,
    @Default([]) List<Account> accounts,
    @Default([]) List<AssetPerformance> assetPerformance,
  }) = _DashboardData;

  const DashboardData._();

  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataFromJson(json);
}
