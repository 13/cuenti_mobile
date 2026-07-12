import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cuentimobile/features/json_converters.dart';

part 'asset.freezed.dart';
part 'asset.g.dart';

const kAssetTypes = ['STOCK', 'ETF', 'CRYPTO'];

@freezed
abstract class Asset with _$Asset {
  const factory Asset({
    int? id,
    @Default('') String symbol,
    @Default('') String name,
    @Default('STOCK') String type,
    @JsonKey(fromJson: jsonToDoubleN) double? currentPrice,
    String? currency,
    DateTime? lastUpdate,
  }) = _Asset;

  const Asset._();

  factory Asset.fromJson(Map<String, dynamic> json) =>
      _$AssetFromJson(json);
}
