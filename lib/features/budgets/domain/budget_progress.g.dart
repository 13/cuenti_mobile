// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BudgetProgress _$BudgetProgressFromJson(Map<String, dynamic> json) =>
    _BudgetProgress(
      budgetId: (json['budgetId'] as num).toInt(),
      categoryId: (json['categoryId'] as num).toInt(),
      categoryName: json['categoryName'] as String?,
      monthlyLimit: json['monthlyLimit'] == null
          ? 0
          : jsonToDouble(json['monthlyLimit']),
      spent: json['spent'] == null ? 0 : jsonToDouble(json['spent']),
      remaining: json['remaining'] == null
          ? 0
          : jsonToDouble(json['remaining']),
      active: json['active'] as bool? ?? true,
    );

Map<String, dynamic> _$BudgetProgressToJson(_BudgetProgress instance) =>
    <String, dynamic>{
      'budgetId': instance.budgetId,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'monthlyLimit': instance.monthlyLimit,
      'spent': instance.spent,
      'remaining': instance.remaining,
      'active': instance.active,
    };
