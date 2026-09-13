import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_release.freezed.dart';
part 'app_release.g.dart';

@freezed
abstract class ReleaseAsset with _$ReleaseAsset {
  const factory ReleaseAsset({
    @Default('') String name,
    @JsonKey(name: 'browser_download_url')
    @Default('')
    String browserDownloadUrl,
    @Default(0) int size,

    /// GitHub's checksum for the asset, e.g. `sha256:<hex>`. Absent on
    /// releases published before GitHub started recording digests.
    String? digest,
  }) = _ReleaseAsset;

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) =>
      _$ReleaseAssetFromJson(json);
}

@freezed
abstract class AppRelease with _$AppRelease {
  const factory AppRelease({
    @JsonKey(name: 'tag_name') @Default('') String tagName,
    String? body,
    @Default([]) List<ReleaseAsset> assets,
  }) = _AppRelease;

  factory AppRelease.fromJson(Map<String, dynamic> json) =>
      _$AppReleaseFromJson(json);
}
