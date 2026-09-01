import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/app_update/domain/app_release.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Deliberately its own Dio: requests go to GitHub, so the backend client
/// with its auth interceptor must not be reused here.
final appUpdateRepositoryProvider = Provider<AppUpdateRepository>(
  (ref) => AppUpdateRepository(Dio()),
);

class AppUpdateRepository {
  AppUpdateRepository(this._dio);
  final Dio _dio;

  static const _latestUrl =
      'https://api.github.com/repos/13/cuenti_mobile/releases/latest';

  Future<AppRelease> getLatestRelease() => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      _latestUrl,
      options: Options(
        headers: {'Accept': 'application/vnd.github+json'},
      ),
    );
    return AppRelease.fromJson(res.data!);
  });

  /// First split APK matching a supported ABI (in ABI preference order),
  /// else the universal APK, else null.
  ReleaseAsset? pickAsset(AppRelease release, List<String> supportedAbis) {
    for (final abi in supportedAbis) {
      for (final asset in release.assets) {
        if (asset.name == 'app-$abi-release.apk') return asset;
      }
    }
    for (final asset in release.assets) {
      if (asset.name == 'app-release.apk') return asset;
    }
    return null;
  }

  Future<String> downloadApk(
    ReleaseAsset asset,
    String savePath,
    void Function(int received, int total) onProgress,
  ) => _guard(() async {
    await _dio.download(
      asset.browserDownloadUrl,
      savePath,
      onReceiveProgress: onProgress,
    );
    return savePath;
  });
}

/// Shared guard: rethrows DioException as ApiException. Copy this exact
/// helper into each repository file (3 lines; a shared base class would
/// couple repositories for no gain).
Future<T> _guard<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}
