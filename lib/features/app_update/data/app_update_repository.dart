import 'package:cuentimobile/core/api/api_guard.dart';
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

  Future<AppRelease> getLatestRelease() => guardApi(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      _latestUrl,
      options: Options(
        headers: {'Accept': 'application/vnd.github+json'},
      ),
    );
    return AppRelease.fromJson(res.data!);
  });

  /// The APK basenames a release may carry, newest convention first.
  ///
  /// Builds are named for the app now, but releases up to v2.2.0 shipped
  /// Flutter's default `app-` names, and the copies of this client already
  /// installed out there look for exactly one of these. Accepting both keeps
  /// old releases reachable and lets the new name become the only one later
  /// without stranding anybody mid-migration.
  static const _apkPrefixes = ['cuenti', 'app'];

  /// First split APK matching a supported ABI, in ABI preference order and
  /// then naming preference, else the universal APK, else null.
  ///
  /// ABI beats naming: a correctly-targeted `app-` build is a better install
  /// than a universal `cuenti-` one.
  ReleaseAsset? pickAsset(AppRelease release, List<String> supportedAbis) {
    ReleaseAsset? named(String name) {
      for (final asset in release.assets) {
        if (asset.name == name) return asset;
      }
      return null;
    }

    for (final abi in supportedAbis) {
      for (final prefix in _apkPrefixes) {
        final asset = named('$prefix-$abi-release.apk');
        if (asset != null) return asset;
      }
    }
    for (final prefix in _apkPrefixes) {
      final asset = named('$prefix-release.apk');
      if (asset != null) return asset;
    }
    return null;
  }

  Future<String> downloadApk(
    ReleaseAsset asset,
    String savePath,
    void Function(int received, int total) onProgress,
  ) => guardApi(() async {
    await _dio.download(
      asset.browserDownloadUrl,
      savePath,
      onReceiveProgress: onProgress,
    );
    return savePath;
  });
}
