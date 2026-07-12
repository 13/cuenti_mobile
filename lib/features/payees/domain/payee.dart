import 'package:freezed_annotation/freezed_annotation.dart';

part 'payee.freezed.dart';
part 'payee.g.dart';

@freezed
abstract class Payee with _$Payee {
  const factory Payee({
    int? id,
    @Default('') String name,
    String? notes,
    int? defaultCategoryId,
    String? defaultCategoryName,
    String? defaultPaymentMethod,
  }) = _Payee;

  const Payee._();

  factory Payee.fromJson(Map<String, dynamic> json) =>
      _$PayeeFromJson(json);
}
