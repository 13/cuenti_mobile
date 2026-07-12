import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

const kAccountTypes = [
  'BANK', 'CASH', 'ASSET', 'CREDIT_CARD', 'LIABILITY', 'CURRENT', 'SAVINGS',
];

@freezed
abstract class Account with _$Account {
  const factory Account({
    int? id,
    @Default('') String accountName,
    String? accountNumber,
    @Default('BANK') String accountType,
    String? accountGroup,
    String? institution,
    @Default('EUR') String currency,
    @Default(0) double startBalance,
    @Default(0) double balance,
    @Default(0) int sortOrder,
    @Default(false) bool excludeFromSummary,
    @Default(false) bool excludeFromReports,
  }) = _Account;

  const Account._();

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  String get displayType => switch (accountType) {
        'BANK' => 'Bank',
        'CASH' => 'Cash',
        'ASSET' => 'Asset',
        'CREDIT_CARD' => 'Credit Card',
        'LIABILITY' => 'Liability',
        'CURRENT' => 'Current Account',
        'SAVINGS' => 'Savings Account',
        _ => accountType,
      };
}
