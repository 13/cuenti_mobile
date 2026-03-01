import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/api_services.dart';
import '../models/models.dart';

/// Generic data provider that handles all CRUD entities.
/// Uses optimistic UI updates — local state is updated immediately,
/// then reverted if the API call fails.
class DataProvider extends ChangeNotifier {
  final ApiClient _client;

  late final AccountApi accountApi;
  late final TransactionApi transactionApi;
  late final CategoryApi categoryApi;
  late final PayeeApi payeeApi;
  late final TagApi tagApi;
  late final AssetApi assetApi;
  late final CurrencyApi currencyApi;
  late final ScheduledTransactionApi scheduledTransactionApi;
  late final DashboardApi dashboardApi;
  late final StatisticsApi statisticsApi;
  late final UserApi userApi;

  // Global saving state for UI to disable buttons
  bool _saving = false;
  bool get saving => _saving;

  // Last error for snackbar display
  String? _lastError;
  String? get lastError => _lastError;
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  DataProvider(this._client) {
    accountApi = AccountApi(_client);
    transactionApi = TransactionApi(_client);
    categoryApi = CategoryApi(_client);
    payeeApi = PayeeApi(_client);
    tagApi = TagApi(_client);
    assetApi = AssetApi(_client);
    currencyApi = CurrencyApi(_client);
    scheduledTransactionApi = ScheduledTransactionApi(_client);
    dashboardApi = DashboardApi(_client);
    statisticsApi = StatisticsApi(_client);
    userApi = UserApi(_client);
  }

  // Accounts
  List<Account> _accounts = [];
  List<Account> get accounts => _accounts;

  Future<void> loadAccounts() async {
    final data = await accountApi.getAccounts();
    _accounts = data.map((e) => Account.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> saveAccount(Map<String, dynamic> data, {int? id}) async {
    _setSaving(true);
    try {
      if (id != null) {
        await accountApi.updateAccount(id, data);
      } else {
        await accountApi.createAccount(data);
      }
      await loadAccounts();
    } catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteAccount(int id) async {
    final backup = List<Account>.from(_accounts);
    _accounts.removeWhere((a) => a.id == id);
    notifyListeners();
    try {
      await accountApi.deleteAccount(id);
      await loadAccounts();
    } catch (e) {
      _accounts = backup;
      notifyListeners();
      _setError(e);
      rethrow;
    }
  }

  // Transactions
  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  Future<void> loadTransactions({int? accountId}) async {
    final data = await transactionApi.getTransactions(accountId: accountId);
    _transactions = data.map((e) => Transaction.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> saveTransaction(Map<String, dynamic> data, {int? id}) async {
    _setSaving(true);
    try {
      if (id != null) {
        await transactionApi.updateTransaction(id, data);
      } else {
        await transactionApi.createTransaction(data);
      }
      // Don't reload transactions here — the calling screen reloads
      // with the correct account filter via its own _load() callback.
      await loadAccounts();
    } catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteTransaction(int id) async {
    final backup = List<Transaction>.from(_transactions);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    try {
      await transactionApi.deleteTransaction(id);
      // Don't reload transactions here — optimistic removal is already applied.
      // The screen can refresh with the correct account filter if needed.
      await loadAccounts();
    } catch (e) {
      _transactions = backup;
      notifyListeners();
      _setError(e);
      rethrow;
    }
  }

  // Categories
  List<Category> _categories = [];
  List<Category> get categories => _categories;

  Future<void> loadCategories() async {
    final data = await categoryApi.getCategories();
    _categories = data.map((e) => Category.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> saveCategory(Map<String, dynamic> data, {int? id}) async {
    _setSaving(true);
    try {
      if (id != null) {
        await categoryApi.updateCategory(id, data);
      } else {
        await categoryApi.createCategory(data);
      }
      await loadCategories();
    } catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteCategory(int id) async {
    final backup = List<Category>.from(_categories);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
    try {
      await categoryApi.deleteCategory(id);
      await loadCategories();
    } catch (e) {
      _categories = backup;
      notifyListeners();
      _setError(e);
      rethrow;
    }
  }

  // Payees
  List<Payee> _payees = [];
  List<Payee> get payees => _payees;

  Future<void> loadPayees() async {
    final data = await payeeApi.getPayees();
    _payees = data.map((e) => Payee.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> savePayee(Map<String, dynamic> data, {int? id}) async {
    _setSaving(true);
    try {
      if (id != null) {
        await payeeApi.updatePayee(id, data);
      } else {
        await payeeApi.createPayee(data);
      }
      await loadPayees();
    } catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deletePayee(int id) async {
    final backup = List<Payee>.from(_payees);
    _payees.removeWhere((p) => p.id == id);
    notifyListeners();
    try {
      await payeeApi.deletePayee(id);
      await loadPayees();
    } catch (e) {
      _payees = backup;
      notifyListeners();
      _setError(e);
      rethrow;
    }
  }

  // Tags
  List<Tag> _tags = [];
  List<Tag> get tags => _tags;

  Future<void> loadTags() async {
    final data = await tagApi.getTags();
    _tags = data.map((e) => Tag.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> saveTag(Map<String, dynamic> data, {int? id}) async {
    _setSaving(true);
    try {
      if (id != null) {
        await tagApi.updateTag(id, data);
      } else {
        await tagApi.createTag(data);
      }
      await loadTags();
    } catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteTag(int id) async {
    final backup = List<Tag>.from(_tags);
    _tags.removeWhere((t) => t.id == id);
    notifyListeners();
    try {
      await tagApi.deleteTag(id);
      await loadTags();
    } catch (e) {
      _tags = backup;
      notifyListeners();
      _setError(e);
      rethrow;
    }
  }

  // Assets
  List<Asset> _assets = [];
  List<Asset> get assets => _assets;

  Future<void> loadAssets() async {
    final data = await assetApi.getAssets();
    _assets = data.map((e) => Asset.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> saveAsset(Map<String, dynamic> data, {int? id}) async {
    _setSaving(true);
    try {
      if (id != null) {
        await assetApi.updateAsset(id, data);
      } else {
        await assetApi.createAsset(data);
      }
      await loadAssets();
    } catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteAsset(int id) async {
    final backup = List<Asset>.from(_assets);
    _assets.removeWhere((a) => a.id == id);
    notifyListeners();
    try {
      await assetApi.deleteAsset(id);
      await loadAssets();
    } catch (e) {
      _assets = backup;
      notifyListeners();
      _setError(e);
      rethrow;
    }
  }

  Future<void> refreshAssetPrice(int id) async {
    _setSaving(true);
    try {
      await assetApi.refreshPrice(id);
      await loadAssets();
    } catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  // Currencies
  List<Currency> _currencies = [];
  List<Currency> get currencies => _currencies;

  Future<void> loadCurrencies() async {
    final data = await currencyApi.getCurrencies();
    _currencies = data.map((e) => Currency.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> saveCurrency(Map<String, dynamic> data, {int? id}) async {
    _setSaving(true);
    try {
      if (id != null) {
        await currencyApi.updateCurrency(id, data);
      } else {
        await currencyApi.createCurrency(data);
      }
      await loadCurrencies();
    } catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteCurrency(int id) async {
    final backup = List<Currency>.from(_currencies);
    _currencies.removeWhere((c) => c.id == id);
    notifyListeners();
    try {
      await currencyApi.deleteCurrency(id);
      await loadCurrencies();
    } catch (e) {
      _currencies = backup;
      notifyListeners();
      _setError(e);
      rethrow;
    }
  }

  // Scheduled Transactions
  List<ScheduledTransaction> _scheduledTransactions = [];
  List<ScheduledTransaction> get scheduledTransactions => _scheduledTransactions;

  Future<void> loadScheduledTransactions() async {
    final data = await scheduledTransactionApi.getScheduledTransactions();
    _scheduledTransactions = data.map((e) => ScheduledTransaction.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> saveScheduledTransaction(Map<String, dynamic> data, {int? id}) async {
    _setSaving(true);
    try {
      if (id != null) {
        await scheduledTransactionApi.update(id, data);
      } else {
        await scheduledTransactionApi.create(data);
      }
      await loadScheduledTransactions();
    } catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteScheduledTransaction(int id) async {
    final backup = List<ScheduledTransaction>.from(_scheduledTransactions);
    _scheduledTransactions.removeWhere((s) => s.id == id);
    notifyListeners();
    try {
      await scheduledTransactionApi.delete(id);
      await loadScheduledTransactions();
    } catch (e) {
      _scheduledTransactions = backup;
      notifyListeners();
      _setError(e);
      rethrow;
    }
  }

  Future<void> postScheduledTransaction(int id) async {
    _setSaving(true);
    try {
      await scheduledTransactionApi.post(id);
      await loadScheduledTransactions();
      await loadTransactions();
      await loadAccounts();
    } catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  Future<void> skipScheduledTransaction(int id) async {
    _setSaving(true);
    try {
      await scheduledTransactionApi.skip(id);
      await loadScheduledTransactions();
    } catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  // Dashboard
  DashboardData? _dashboard;
  DashboardData? get dashboard => _dashboard;

  Future<void> loadDashboard() async {
    final data = await dashboardApi.getDashboard();
    _dashboard = DashboardData.fromJson(data);
    notifyListeners();
  }

  // Statistics
  StatisticsData? _statistics;
  StatisticsData? get statistics => _statistics;

  Future<void> loadStatistics({String? start, String? end}) async {
    final data = await statisticsApi.getStatistics(start: start, end: end);
    _statistics = StatisticsData.fromJson(data);
    notifyListeners();
  }

  // Load all reference data once (call after login)
  Future<void> loadAll() async {
    await Future.wait([
      loadAccounts(),
      loadCategories(),
      loadPayees(),
      loadTags(),
      loadCurrencies(),
      loadAssets(),
    ]);
  }

  // Clear all data on logout
  void clearAll() {
    _accounts = [];
    _transactions = [];
    _categories = [];
    _payees = [];
    _tags = [];
    _assets = [];
    _currencies = [];
    _scheduledTransactions = [];
    _dashboard = null;
    _statistics = null;
    _saving = false;
    _lastError = null;
    notifyListeners();
  }

  // --- Internal helpers ---

  void _setSaving(bool value) {
    _saving = value;
    notifyListeners();
  }

  void _setError(dynamic e) {
    _lastError = _extractError(e);
    notifyListeners();
  }

  String _extractError(dynamic e) {
    if (e is Exception) {
      final str = e.toString();
      if (str.contains('DioException')) {
        if (str.contains('connection refused') || str.contains('ECONNREFUSED')) {
          return 'Cannot connect to server';
        }
        if (str.contains('404')) return 'Not found';
        if (str.contains('409')) return 'Conflict — item may be in use';
        if (str.contains('500')) return 'Server error';
      }
      return str.replaceAll('Exception: ', '');
    }
    return 'An error occurred';
  }
}
