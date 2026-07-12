// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Budget _$BudgetFromJson(Map<String, dynamic> json) => _Budget(
  id: (json['id'] as num?)?.toInt(),
  categoryId: (json['categoryId'] as num).toInt(),
  categoryName: json['categoryName'] as String?,
  monthlyLimit: json['monthlyLimit'] == null
      ? 0
      : jsonToDouble(json['monthlyLimit']),
  active: json['active'] as bool? ?? true,
);

Map<String, dynamic> _$BudgetToJson(_Budget instance) => <String, dynamic>{
  'id': instance.id,
  'categoryId': instance.categoryId,
  'categoryName': instance.categoryName,
  'monthlyLimit': instance.monthlyLimit,
  'active': instance.active,
};
