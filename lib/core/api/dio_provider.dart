import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return const SecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureStorageProvider));
});

final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);
