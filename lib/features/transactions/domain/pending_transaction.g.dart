// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingTransaction _$PendingTransactionFromJson(Map<String, dynamic> json) =>
    _PendingTransaction(
      localId: json['localId'] as String,
      operation: $enumDecode(_$PendingOperationEnumMap, json['operation']),
      transaction: _transactionFromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      rejection: json['rejection'] as String?,
    );

Map<String, dynamic> _$PendingTransactionToJson(_PendingTransaction instance) =>
    <String, dynamic>{
      'localId': instance.localId,
      'operation': _$PendingOperationEnumMap[instance.operation]!,
      'transaction': _transactionToJson(instance.transaction),
      'queuedAt': instance.queuedAt.toIso8601String(),
      'rejection': instance.rejection,
    };

const _$PendingOperationEnumMap = {
  PendingOperation.create: 'create',
  PendingOperation.update: 'update',
  PendingOperation.delete: 'delete',
};
