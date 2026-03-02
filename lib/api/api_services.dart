import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _client.dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _client.dio.post('/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });
    return response.data;
  }
}

class AccountApi {
  final ApiClient _client;
  AccountApi(this._client);

  Future<List<dynamic>> getAccounts() async {
    final response = await _client.dio.get('/accounts');
    return response.data;
  }

  Future<Map<String, dynamic>> getAccount(int id) async {
    final response = await _client.dio.get('/accounts/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createAccount(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/accounts', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateAccount(int id, Map<String, dynamic> data) async {
    final response = await _client.dio.put('/accounts/$id', data: data);
    return response.data;
  }

  Future<void> deleteAccount(int id) async {
    await _client.dio.delete('/accounts/$id');
  }

  Future<void> updateSortOrder(List<int> accountIds) async {
    await _client.dio.put('/accounts/sort-order', data: accountIds);
  }
}

class TransactionApi {
  final ApiClient _client;
  TransactionApi(this._client);

  Future<List<dynamic>> getTransactions({int? accountId}) async {
    final params = <String, dynamic>{};
    if (accountId != null) params['accountId'] = accountId;
    final response = await _client.dio.get('/transactions', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/transactions', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateTransaction(int id, Map<String, dynamic> data) async {
    final response = await _client.dio.put('/transactions/$id', data: data);
    return response.data;
  }

  Future<void> deleteTransaction(int id) async {
    await _client.dio.delete('/transactions/$id');
  }
}

class CategoryApi {
  final ApiClient _client;
  CategoryApi(this._client);

  Future<List<dynamic>> getCategories({String? type}) async {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type;
    final response = await _client.dio.get('/categories', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/categories', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateCategory(int id, Map<String, dynamic> data) async {
    final response = await _client.dio.put('/categories/$id', data: data);
    return response.data;
  }

  Future<void> deleteCategory(int id) async {
    await _client.dio.delete('/categories/$id');
  }
}

class PayeeApi {
  final ApiClient _client;
  PayeeApi(this._client);

  Future<List<dynamic>> getPayees({String? search}) async {
    final params = <String, dynamic>{};
    if (search != null) params['search'] = search;
    final response = await _client.dio.get('/payees', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> createPayee(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/payees', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updatePayee(int id, Map<String, dynamic> data) async {
    final response = await _client.dio.put('/payees/$id', data: data);
    return response.data;
  }

  Future<void> deletePayee(int id) async {
    await _client.dio.delete('/payees/$id');
  }
}

class TagApi {
  final ApiClient _client;
  TagApi(this._client);

  Future<List<dynamic>> getTags({String? search}) async {
    final params = <String, dynamic>{};
    if (search != null) params['search'] = search;
    final response = await _client.dio.get('/tags', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> createTag(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/tags', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateTag(int id, Map<String, dynamic> data) async {
    final response = await _client.dio.put('/tags/$id', data: data);
    return response.data;
  }

  Future<void> deleteTag(int id) async {
    await _client.dio.delete('/tags/$id');
  }
}

class AssetApi {
  final ApiClient _client;
  AssetApi(this._client);

  Future<List<dynamic>> getAssets({String? search}) async {
    final params = <String, dynamic>{};
    if (search != null) params['search'] = search;
    final response = await _client.dio.get('/assets', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> createAsset(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/assets', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateAsset(int id, Map<String, dynamic> data) async {
    final response = await _client.dio.put('/assets/$id', data: data);
    return response.data;
  }

  Future<void> deleteAsset(int id) async {
    await _client.dio.delete('/assets/$id');
  }

  Future<Map<String, dynamic>> refreshPrice(int id) async {
    final response = await _client.dio.post('/assets/$id/refresh-price');
    return response.data;
  }
}

class CurrencyApi {
  final ApiClient _client;
  CurrencyApi(this._client);

  Future<List<dynamic>> getCurrencies() async {
    final response = await _client.dio.get('/currencies');
    return response.data;
  }

  Future<Map<String, dynamic>> createCurrency(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/currencies', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateCurrency(int id, Map<String, dynamic> data) async {
    final response = await _client.dio.put('/currencies/$id', data: data);
    return response.data;
  }

  Future<void> deleteCurrency(int id) async {
    await _client.dio.delete('/currencies/$id');
  }
}

class ScheduledTransactionApi {
  final ApiClient _client;
  ScheduledTransactionApi(this._client);

  Future<List<dynamic>> getScheduledTransactions() async {
    final response = await _client.dio.get('/scheduled-transactions');
    return response.data;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/scheduled-transactions', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final response = await _client.dio.put('/scheduled-transactions/$id', data: data);
    return response.data;
  }

  Future<void> delete(int id) async {
    await _client.dio.delete('/scheduled-transactions/$id');
  }

  Future<void> post(int id) async {
    await _client.dio.post('/scheduled-transactions/$id/post');
  }

  Future<void> skip(int id) async {
    await _client.dio.post('/scheduled-transactions/$id/skip');
  }
}

class DashboardApi {
  final ApiClient _client;
  DashboardApi(this._client);

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _client.dio.get('/dashboard');
    return response.data;
  }
}

class StatisticsApi {
  final ApiClient _client;
  StatisticsApi(this._client);

  Future<Map<String, dynamic>> getStatistics({String? start, String? end, int? accountId}) async {
    final params = <String, dynamic>{};
    if (start != null) params['start'] = start;
    if (end != null) params['end'] = end;
    if (accountId != null) params['accountId'] = accountId;
    final response = await _client.dio.get('/statistics', queryParameters: params);
    return response.data;
  }
}

class UserApi {
  final ApiClient _client;
  UserApi(this._client);

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.dio.get('/user/profile');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _client.dio.put('/user/profile', data: data);
    return response.data;
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    await _client.dio.put('/user/password', data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> prefs) async {
    final response = await _client.dio.put('/user/preferences', data: prefs);
    return response.data;
  }

  // Admin
  Future<List<dynamic>> getAllUsers() async {
    final response = await _client.dio.get('/user/admin/users');
    return response.data;
  }

  Future<void> setUserEnabled(int id, bool enabled) async {
    await _client.dio.put('/user/admin/users/$id/enabled', data: {'enabled': enabled});
  }

  Future<void> deleteUser(int id) async {
    await _client.dio.delete('/user/admin/users/$id');
  }

  Future<Map<String, dynamic>> getAdminSettings() async {
    final response = await _client.dio.get('/user/admin/settings');
    return response.data;
  }

  Future<void> updateAdminSettings(Map<String, dynamic> settings) async {
    await _client.dio.put('/user/admin/settings', data: settings);
  }
}
