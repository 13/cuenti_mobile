// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transaction _$TransactionFromJson(Map<String, dynamic> json) => _Transaction(
  id: (json['id'] as num?)?.toInt(),
  type: json['type'] as String? ?? 'EXPENSE',
  fromAccountId: (json['fromAccountId'] as num?)?.toInt(),
  fromAccountName: json['fromAccountName'] as String?,
  toAccountId: (json['toAccountId'] as num?)?.toInt(),
  toAccountName: json['toAccountName'] as String?,
  amount: jsonToDouble(json['amount']),
  transactionDate: DateTime.parse(json['transactionDate'] as String),
  status: json['status'] as String?,
  payee: json['payee'] as String?,
  categoryId: (json['categoryId'] as num?)?.toInt(),
  categoryName: json['categoryName'] as String?,
  memo: json['memo'] as String?,
  tags: json['tags'] as String?,
  number: json['number'] as String?,
  paymentMethod: json['paymentMethod'] as String?,
  assetId: (json['assetId'] as num?)?.toInt(),
  assetName: json['assetName'] as String?,
  units: jsonToDoubleN(json['units']),
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  splits:
      (json['splits'] as List<dynamic>?)
          ?.map((e) => TransactionSplit.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$TransactionToJson(_Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'fromAccountId': instance.fromAccountId,
      'fromAccountName': instance.fromAccountName,
      'toAccountId': instance.toAccountId,
      'toAccountName': instance.toAccountName,
      'amount': instance.amount,
      'transactionDate': instance.transactionDate.toIso8601String(),
      'status': instance.status,
      'payee': instance.payee,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'memo': instance.memo,
      'tags': instance.tags,
      'number': instance.number,
      'paymentMethod': instance.paymentMethod,
      'assetId': instance.assetId,
      'assetName': instance.assetName,
      'units': instance.units,
      'sortOrder': instance.sortOrder,
      'splits': instance.splits,
    };
