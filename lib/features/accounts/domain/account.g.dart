// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Account _$AccountFromJson(Map<String, dynamic> json) => _Account(
  id: (json['id'] as num?)?.toInt(),
  accountName: json['accountName'] as String? ?? '',
  accountNumber: json['accountNumber'] as String?,
  accountType: json['accountType'] as String? ?? 'BANK',
  accountGroup: json['accountGroup'] as String?,
  institution: json['institution'] as String?,
  currency: json['currency'] as String? ?? 'EUR',
  startBalance: (json['startBalance'] as num?)?.toDouble() ?? 0,
  balance: (json['balance'] as num?)?.toDouble() ?? 0,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  excludeFromSummary: json['excludeFromSummary'] as bool? ?? false,
  excludeFromReports: json['excludeFromReports'] as bool? ?? false,
);

Map<String, dynamic> _$AccountToJson(_Account instance) => <String, dynamic>{
  'id': instance.id,
  'accountName': instance.accountName,
  'accountNumber': instance.accountNumber,
  'accountType': instance.accountType,
  'accountGroup': instance.accountGroup,
  'institution': instance.institution,
  'currency': instance.currency,
  'startBalance': instance.startBalance,
  'balance': instance.balance,
  'sortOrder': instance.sortOrder,
  'excludeFromSummary': instance.excludeFromSummary,
  'excludeFromReports': instance.excludeFromReports,
};
