import 'package:freezed_annotation/freezed_annotation.dart';

part 'currency.freezed.dart';
part 'currency.g.dart';

@freezed
abstract class Currency with _$Currency {
  const factory Currency({
    int? id,
    @Default('') String code,
    @Default('') String name,
    @Default('') String symbol,
    @Default(',') String decimalChar,
    @Default(2) int fracDigits,
    @Default('.') String groupingChar,
  }) = _Currency;

  const Currency._();

  factory Currency.fromJson(Map<String, dynamic> json) =>
      _$CurrencyFromJson(json);
}
