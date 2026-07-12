// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatisticsData _$StatisticsDataFromJson(Map<String, dynamic> json) =>
    _StatisticsData(
      totalIncome: jsonToDouble(json['totalIncome']),
      totalExpense: jsonToDouble(json['totalExpense']),
      balance: jsonToDouble(json['balance']),
      currency: json['currency'] as String? ?? 'EUR',
      incomeByCategory: json['incomeByCategory'] == null
          ? const {}
          : jsonToDoubleMap(json['incomeByCategory']),
      expenseByCategory: json['expenseByCategory'] == null
          ? const {}
          : jsonToDoubleMap(json['expenseByCategory']),
      monthlyIncome: json['monthlyIncome'] == null
          ? const {}
          : jsonToDoubleMap(json['monthlyIncome']),
      monthlyExpense: json['monthlyExpense'] == null
          ? const {}
          : jsonToDoubleMap(json['monthlyExpense']),
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$StatisticsDataToJson(_StatisticsData instance) =>
    <String, dynamic>{
      'totalIncome': instance.totalIncome,
      'totalExpense': instance.totalExpense,
      'balance': instance.balance,
      'currency': instance.currency,
      'incomeByCategory': instance.incomeByCategory,
      'expenseByCategory': instance.expenseByCategory,
      'monthlyIncome': instance.monthlyIncome,
      'monthlyExpense': instance.monthlyExpense,
      'transactionCount': instance.transactionCount,
    };
