// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_split.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransactionSplit _$TransactionSplitFromJson(Map<String, dynamic> json) =>
    _TransactionSplit(
      amount: jsonToDouble(json['amount']),
      id: (json['id'] as num?)?.toInt(),
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categoryName: json['categoryName'] as String?,
      memo: json['memo'] as String?,
    );

Map<String, dynamic> _$TransactionSplitToJson(_TransactionSplit instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'id': instance.id,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'memo': instance.memo,
    };
