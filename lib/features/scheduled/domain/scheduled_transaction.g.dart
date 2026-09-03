// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduledTransaction _$ScheduledTransactionFromJson(
  Map<String, dynamic> json,
) => _ScheduledTransaction(
  amount: jsonToDouble(json['amount']),
  nextOccurrence: DateTime.parse(json['nextOccurrence'] as String),
  id: (json['id'] as num?)?.toInt(),
  type: json['type'] as String? ?? 'EXPENSE',
  fromAccountId: (json['fromAccountId'] as num?)?.toInt(),
  fromAccountName: json['fromAccountName'] as String?,
  toAccountId: (json['toAccountId'] as num?)?.toInt(),
  toAccountName: json['toAccountName'] as String?,
  payee: json['payee'] as String?,
  categoryId: (json['categoryId'] as num?)?.toInt(),
  categoryName: json['categoryName'] as String?,
  memo: json['memo'] as String?,
  tags: json['tags'] as String?,
  number: json['number'] as String?,
  assetId: (json['assetId'] as num?)?.toInt(),
  assetName: json['assetName'] as String?,
  units: jsonToDoubleN(json['units']),
  recurrencePattern: json['recurrencePattern'] as String? ?? 'MONTHLY',
  recurrenceValue: (json['recurrenceValue'] as num?)?.toInt(),
  enabled: json['enabled'] as bool? ?? true,
);

Map<String, dynamic> _$ScheduledTransactionToJson(
  _ScheduledTransaction instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'nextOccurrence': instance.nextOccurrence.toIso8601String(),
  'id': instance.id,
  'type': instance.type,
  'fromAccountId': instance.fromAccountId,
  'fromAccountName': instance.fromAccountName,
  'toAccountId': instance.toAccountId,
  'toAccountName': instance.toAccountName,
  'payee': instance.payee,
  'categoryId': instance.categoryId,
  'categoryName': instance.categoryName,
  'memo': instance.memo,
  'tags': instance.tags,
  'number': instance.number,
  'assetId': instance.assetId,
  'assetName': instance.assetName,
  'units': instance.units,
  'recurrencePattern': instance.recurrencePattern,
  'recurrenceValue': instance.recurrenceValue,
  'enabled': instance.enabled,
};
