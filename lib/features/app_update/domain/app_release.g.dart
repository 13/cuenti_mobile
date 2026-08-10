// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_release.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReleaseAsset _$ReleaseAssetFromJson(Map<String, dynamic> json) =>
    _ReleaseAsset(
      name: json['name'] as String? ?? '',
      browserDownloadUrl: json['browser_download_url'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ReleaseAssetToJson(_ReleaseAsset instance) =>
    <String, dynamic>{
      'name': instance.name,
      'browser_download_url': instance.browserDownloadUrl,
      'size': instance.size,
    };

_AppRelease _$AppReleaseFromJson(Map<String, dynamic> json) => _AppRelease(
  tagName: json['tag_name'] as String? ?? '',
  body: json['body'] as String?,
  assets:
      (json['assets'] as List<dynamic>?)
          ?.map((e) => ReleaseAsset.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$AppReleaseToJson(_AppRelease instance) =>
    <String, dynamic>{
      'tag_name': instance.tagName,
      'body': instance.body,
      'assets': instance.assets,
    };
