class Account {
  final int? id;
  final String accountName;
  final String? accountNumber;
  final String accountType;
  final String? accountGroup;
  final String? institution;
  final String currency;
  final double startBalance;
  final double balance;
  final int sortOrder;
  final bool excludeFromSummary;
  final bool excludeFromReports;

  Account({
    this.id,
    required this.accountName,
    this.accountNumber,
    required this.accountType,
    this.accountGroup,
    this.institution,
    this.currency = 'EUR',
    this.startBalance = 0,
    this.balance = 0,
    this.sortOrder = 0,
    this.excludeFromSummary = false,
    this.excludeFromReports = false,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      accountName: json['accountName'] ?? '',
      accountNumber: json['accountNumber'],
      accountType: json['accountType'] ?? 'BANK',
      accountGroup: json['accountGroup'],
      institution: json['institution'],
      currency: json['currency'] ?? 'EUR',
      startBalance: (json['startBalance'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      sortOrder: json['sortOrder'] ?? 0,
      excludeFromSummary: json['excludeFromSummary'] ?? false,
      excludeFromReports: json['excludeFromReports'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'accountName': accountName,
    'accountNumber': accountNumber,
    'accountType': accountType,
    'accountGroup': accountGroup,
    'institution': institution,
    'currency': currency,
    'startBalance': startBalance,
    'balance': balance,
    'sortOrder': sortOrder,
    'excludeFromSummary': excludeFromSummary,
    'excludeFromReports': excludeFromReports,
  };

  static const List<String> accountTypes = [
    'BANK', 'CASH', 'ASSET', 'CREDIT_CARD', 'LIABILITY', 'CURRENT', 'SAVINGS'
  ];

  String get displayType {
    switch (accountType) {
      case 'BANK': return 'Bank';
      case 'CASH': return 'Cash';
      case 'ASSET': return 'Asset';
      case 'CREDIT_CARD': return 'Credit Card';
      case 'LIABILITY': return 'Liability';
      case 'CURRENT': return 'Current Account';
      case 'SAVINGS': return 'Savings Account';
      default: return accountType;
    }
  }
}

class Transaction {
  final int? id;
  final String type;
  final int? fromAccountId;
  final String? fromAccountName;
  final int? toAccountId;
  final String? toAccountName;
  final double amount;
  final DateTime transactionDate;
  final String? status;
  final String? payee;
  final int? categoryId;
  final String? categoryName;
  final String? memo;
  final String? tags;
  final String? number;
  final String? paymentMethod;
  final int? assetId;
  final String? assetName;
  final double? units;
  final int sortOrder;

  Transaction({
    this.id,
    required this.type,
    this.fromAccountId,
    this.fromAccountName,
    this.toAccountId,
    this.toAccountName,
    required this.amount,
    required this.transactionDate,
    this.status,
    this.payee,
    this.categoryId,
    this.categoryName,
    this.memo,
    this.tags,
    this.number,
    this.paymentMethod,
    this.assetId,
    this.assetName,
    this.units,
    this.sortOrder = 0,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'] ?? 'EXPENSE',
      fromAccountId: json['fromAccountId'],
      fromAccountName: json['fromAccountName'],
      toAccountId: json['toAccountId'],
      toAccountName: json['toAccountName'],
      amount: (json['amount'] ?? 0).toDouble(),
      transactionDate: json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'])
          : DateTime.now(),
      status: json['status'],
      payee: json['payee'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      memo: json['memo'],
      tags: json['tags'],
      number: json['number'],
      paymentMethod: json['paymentMethod'],
      assetId: json['assetId'],
      assetName: json['assetName'],
      units: json['units']?.toDouble(),
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'fromAccountId': fromAccountId,
    'toAccountId': toAccountId,
    'amount': amount,
    'transactionDate': transactionDate.toIso8601String(),
    'payee': payee,
    'categoryId': categoryId,
    'memo': memo,
    'tags': tags,
    'number': number,
    'paymentMethod': paymentMethod ?? 'NONE',
    'assetId': assetId,
    'units': units,
    'sortOrder': sortOrder,
  };

  static const List<String> types = ['EXPENSE', 'INCOME', 'TRANSFER'];

  static const List<String> paymentMethods = [
    'NONE', 'DEBIT_CARD', 'CASH', 'BANK_TRANSFER', 'STANDING_ORDER',
    'ELECTRONIC_PAYMENT', 'FI_FEE', 'CARD_TRANSACTION', 'TRADE',
    'TRANSFER', 'REWARD', 'INTEREST',
  ];
}

class Category {
  final int? id;
  final String name;
  final String? fullName;
  final String type;
  final int? parentId;
  final String? parentName;

  Category({
    this.id,
    required this.name,
    this.fullName,
    required this.type,
    this.parentId,
    this.parentName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      fullName: json['fullName'],
      type: json['type'] ?? 'EXPENSE',
      parentId: json['parentId'],
      parentName: json['parentName'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'parentId': parentId,
  };
}

class Payee {
  final int? id;
  final String name;
  final String? notes;
  final int? defaultCategoryId;
  final String? defaultCategoryName;
  final String? defaultPaymentMethod;

  Payee({
    this.id,
    required this.name,
    this.notes,
    this.defaultCategoryId,
    this.defaultCategoryName,
    this.defaultPaymentMethod,
  });

  factory Payee.fromJson(Map<String, dynamic> json) {
    return Payee(
      id: json['id'],
      name: json['name'] ?? '',
      notes: json['notes'],
      defaultCategoryId: json['defaultCategoryId'],
      defaultCategoryName: json['defaultCategoryName'],
      defaultPaymentMethod: json['defaultPaymentMethod'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'notes': notes,
    'defaultCategoryId': defaultCategoryId,
    'defaultPaymentMethod': defaultPaymentMethod ?? 'NONE',
  };
}

class Tag {
  final int? id;
  final String name;

  Tag({this.id, required this.name});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(id: json['id'], name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() => {'name': name};
}

class Asset {
  final int? id;
  final String symbol;
  final String name;
  final String type;
  final double? currentPrice;
  final String? currency;
  final DateTime? lastUpdate;

  Asset({
    this.id,
    required this.symbol,
    required this.name,
    required this.type,
    this.currentPrice,
    this.currency,
    this.lastUpdate,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'STOCK',
      currentPrice: json['currentPrice']?.toDouble(),
      currency: json['currency'],
      lastUpdate: json['lastUpdate'] != null ? DateTime.parse(json['lastUpdate']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'type': type,
    'currency': currency,
  };

  static const List<String> assetTypes = ['STOCK', 'ETF', 'CRYPTO'];
}

class Currency {
  final int? id;
  final String code;
  final String name;
  final String symbol;
  final String decimalChar;
  final int fracDigits;
  final String groupingChar;

  Currency({
    this.id,
    required this.code,
    required this.name,
    required this.symbol,
    this.decimalChar = ',',
    this.fracDigits = 2,
    this.groupingChar = '.',
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'],
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      decimalChar: json['decimalChar'] ?? ',',
      fracDigits: json['fracDigits'] ?? 2,
      groupingChar: json['groupingChar'] ?? '.',
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'symbol': symbol,
    'decimalChar': decimalChar,
    'fracDigits': fracDigits,
    'groupingChar': groupingChar,
  };
}

class ScheduledTransaction {
  final int? id;
  final String type;
  final int? fromAccountId;
  final String? fromAccountName;
  final int? toAccountId;
  final String? toAccountName;
  final double amount;
  final String? payee;
  final int? categoryId;
  final String? categoryName;
  final String? memo;
  final String? tags;
  final String? number;
  final int? assetId;
  final String? assetName;
  final double? units;
  final String recurrencePattern;
  final int? recurrenceValue;
  final DateTime nextOccurrence;
  final bool enabled;

  ScheduledTransaction({
    this.id,
    required this.type,
    this.fromAccountId,
    this.fromAccountName,
    this.toAccountId,
    this.toAccountName,
    required this.amount,
    this.payee,
    this.categoryId,
    this.categoryName,
    this.memo,
    this.tags,
    this.number,
    this.assetId,
    this.assetName,
    this.units,
    required this.recurrencePattern,
    this.recurrenceValue,
    required this.nextOccurrence,
    this.enabled = true,
  });

  factory ScheduledTransaction.fromJson(Map<String, dynamic> json) {
    return ScheduledTransaction(
      id: json['id'],
      type: json['type'] ?? 'EXPENSE',
      fromAccountId: json['fromAccountId'],
      fromAccountName: json['fromAccountName'],
      toAccountId: json['toAccountId'],
      toAccountName: json['toAccountName'],
      amount: (json['amount'] ?? 0).toDouble(),
      payee: json['payee'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      memo: json['memo'],
      tags: json['tags'],
      number: json['number'],
      assetId: json['assetId'],
      assetName: json['assetName'],
      units: json['units']?.toDouble(),
      recurrencePattern: json['recurrencePattern'] ?? 'MONTHLY',
      recurrenceValue: json['recurrenceValue'],
      nextOccurrence: json['nextOccurrence'] != null
          ? DateTime.parse(json['nextOccurrence'])
          : DateTime.now(),
      enabled: json['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'fromAccountId': fromAccountId,
    'toAccountId': toAccountId,
    'amount': amount,
    'payee': payee,
    'categoryId': categoryId,
    'memo': memo,
    'tags': tags,
    'number': number,
    'assetId': assetId,
    'units': units,
    'recurrencePattern': recurrencePattern,
    'recurrenceValue': recurrenceValue,
    'nextOccurrence': nextOccurrence.toIso8601String(),
    'enabled': enabled,
  };

  static const List<String> patterns = [
    'DAILY', 'WEEKLY', 'BI_WEEKLY', 'MONTHLY', 'MONTHLY_LAST_DAY',
    'YEARLY', 'EVERY_FRIDAY', 'EVERY_SATURDAY', 'EVERY_WEEKDAY',
  ];
}

class UserProfile {
  final int? id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String defaultCurrency;
  final bool darkMode;
  final String locale;
  final bool apiEnabled;
  final Set<String> roles;

  UserProfile({
    this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.defaultCurrency = 'EUR',
    this.darkMode = true,
    this.locale = 'de-DE',
    this.apiEnabled = false,
    this.roles = const {},
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      defaultCurrency: json['defaultCurrency'] ?? 'EUR',
      darkMode: json['darkMode'] ?? true,
      locale: json['locale'] ?? 'de-DE',
      apiEnabled: json['apiEnabled'] ?? false,
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toSet() ?? {},
    );
  }

  bool get isAdmin => roles.contains('ROLE_ADMIN');
}

class DashboardData {
  final double availableCash;
  final double portfolioValue;
  final double netWorth;
  final String defaultCurrency;
  final List<Account> accounts;
  final List<AssetPerformance> assetPerformance;

  DashboardData({
    required this.availableCash,
    required this.portfolioValue,
    required this.netWorth,
    required this.defaultCurrency,
    required this.accounts,
    required this.assetPerformance,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      availableCash: (json['availableCash'] ?? 0).toDouble(),
      portfolioValue: (json['portfolioValue'] ?? 0).toDouble(),
      netWorth: (json['netWorth'] ?? 0).toDouble(),
      defaultCurrency: json['defaultCurrency'] ?? 'EUR',
      accounts: (json['accounts'] as List?)
          ?.map((e) => Account.fromJson(e))
          .toList() ?? [],
      assetPerformance: (json['assetPerformance'] as List?)
          ?.map((e) => AssetPerformance.fromJson(e))
          .toList() ?? [],
    );
  }
}

class AssetPerformance {
  final String assetName;
  final String assetSymbol;
  final double totalUnits;
  final double totalCost;
  final double currentValue;
  final double currentPrice;
  final double gainLoss;
  final double gainLossPercent;

  AssetPerformance({
    required this.assetName,
    required this.assetSymbol,
    required this.totalUnits,
    required this.totalCost,
    required this.currentValue,
    required this.currentPrice,
    required this.gainLoss,
    required this.gainLossPercent,
  });

  factory AssetPerformance.fromJson(Map<String, dynamic> json) {
    return AssetPerformance(
      assetName: json['assetName'] ?? '',
      assetSymbol: json['assetSymbol'] ?? '',
      totalUnits: (json['totalUnits'] ?? 0).toDouble(),
      totalCost: (json['totalCost'] ?? 0).toDouble(),
      currentValue: (json['currentValue'] ?? 0).toDouble(),
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      gainLoss: (json['gainLoss'] ?? 0).toDouble(),
      gainLossPercent: (json['gainLossPercent'] ?? 0).toDouble(),
    );
  }
}

class StatisticsData {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final String currency;
  final Map<String, double> incomeByCategory;
  final Map<String, double> expenseByCategory;
  final Map<String, double> monthlyIncome;
  final Map<String, double> monthlyExpense;
  final int transactionCount;

  StatisticsData({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.currency,
    required this.incomeByCategory,
    required this.expenseByCategory,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.transactionCount,
  });

  factory StatisticsData.fromJson(Map<String, dynamic> json) {
    return StatisticsData(
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpense: (json['totalExpense'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      incomeByCategory: _parseMap(json['incomeByCategory']),
      expenseByCategory: _parseMap(json['expenseByCategory']),
      monthlyIncome: _parseMap(json['monthlyIncome']),
      monthlyExpense: _parseMap(json['monthlyExpense']),
      transactionCount: json['transactionCount'] ?? 0,
    );
  }

  static Map<String, double> _parseMap(dynamic map) {
    if (map == null) return {};
    return (map as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v ?? 0).toDouble()));
  }
}
