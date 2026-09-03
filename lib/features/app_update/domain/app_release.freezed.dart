// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_release.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReleaseAsset {

 String get name;@JsonKey(name: 'browser_download_url') String get browserDownloadUrl; int get size;
/// Create a copy of ReleaseAsset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReleaseAssetCopyWith<ReleaseAsset> get copyWith => _$ReleaseAssetCopyWithImpl<ReleaseAsset>(this as ReleaseAsset, _$identity);

  /// Serializes this ReleaseAsset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReleaseAsset;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReleaseAsset&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.browserDownloadUrl, _this.browserDownloadUrl) || other.browserDownloadUrl == _this.browserDownloadUrl)&&(identical(other.size, _this.size) || other.size == _this.size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReleaseAsset;
  return Object.hash(runtimeType,_this.name,_this.browserDownloadUrl,_this.size);
}

@override
String toString() {
  final _this = this as ReleaseAsset;
  return 'ReleaseAsset(name: ${_this.name}, browserDownloadUrl: ${_this.browserDownloadUrl}, size: ${_this.size})';
}


}

/// @nodoc
abstract mixin class $ReleaseAssetCopyWith<$Res>  {
  factory $ReleaseAssetCopyWith(ReleaseAsset value, $Res Function(ReleaseAsset) _then) = _$ReleaseAssetCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(name: 'browser_download_url') String browserDownloadUrl, int size
});




}
/// @nodoc
class _$ReleaseAssetCopyWithImpl<$Res>
    implements $ReleaseAssetCopyWith<$Res> {
  _$ReleaseAssetCopyWithImpl(this._self, this._then);

  final ReleaseAsset _self;
  final $Res Function(ReleaseAsset) _then;

/// Create a copy of ReleaseAsset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? browserDownloadUrl = null,Object? size = null,}) {
  return _then(ReleaseAsset(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,browserDownloadUrl: null == browserDownloadUrl ? _self.browserDownloadUrl : browserDownloadUrl // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReleaseAsset].
extension ReleaseAssetPatterns on ReleaseAsset {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReleaseAsset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReleaseAsset() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReleaseAsset value)  $default,){
final _that = this;
switch (_that) {
case _ReleaseAsset():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReleaseAsset value)?  $default,){
final _that = this;
switch (_that) {
case _ReleaseAsset() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'browser_download_url')  String browserDownloadUrl,  int size)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReleaseAsset() when $default != null:
return $default(_that.name,_that.browserDownloadUrl,_that.size);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'browser_download_url')  String browserDownloadUrl,  int size)  $default,) {final _that = this;
switch (_that) {
case _ReleaseAsset():
return $default(_that.name,_that.browserDownloadUrl,_that.size);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @JsonKey(name: 'browser_download_url')  String browserDownloadUrl,  int size)?  $default,) {final _that = this;
switch (_that) {
case _ReleaseAsset() when $default != null:
return $default(_that.name,_that.browserDownloadUrl,_that.size);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReleaseAsset implements ReleaseAsset {
  const _ReleaseAsset({this.name = '', @JsonKey(name: 'browser_download_url') this.browserDownloadUrl = '', this.size = 0});
  factory _ReleaseAsset.fromJson(Map<String, dynamic> json) => _$ReleaseAssetFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey(name: 'browser_download_url') final  String browserDownloadUrl;
@override@JsonKey() final  int size;

/// Create a copy of ReleaseAsset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReleaseAssetCopyWith<_ReleaseAsset> get copyWith => __$ReleaseAssetCopyWithImpl<_ReleaseAsset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReleaseAssetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReleaseAsset&&(identical(other.name, name) || other.name == name)&&(identical(other.browserDownloadUrl, browserDownloadUrl) || other.browserDownloadUrl == browserDownloadUrl)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,browserDownloadUrl,size);
}

@override
String toString() {
    return 'ReleaseAsset(name: $name, browserDownloadUrl: $browserDownloadUrl, size: $size)';
}


}

/// @nodoc
abstract mixin class _$ReleaseAssetCopyWith<$Res> implements $ReleaseAssetCopyWith<$Res> {
  factory _$ReleaseAssetCopyWith(_ReleaseAsset value, $Res Function(_ReleaseAsset) _then) = __$ReleaseAssetCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(name: 'browser_download_url') String browserDownloadUrl, int size
});




}
/// @nodoc
class __$ReleaseAssetCopyWithImpl<$Res>
    implements _$ReleaseAssetCopyWith<$Res> {
  __$ReleaseAssetCopyWithImpl(this._self, this._then);

  final _ReleaseAsset _self;
  final $Res Function(_ReleaseAsset) _then;

/// Create a copy of ReleaseAsset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? browserDownloadUrl = null,Object? size = null,}) {
  return _then(_ReleaseAsset(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,browserDownloadUrl: null == browserDownloadUrl ? _self.browserDownloadUrl : browserDownloadUrl // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AppRelease {

@JsonKey(name: 'tag_name') String get tagName; String? get body; List<ReleaseAsset> get assets;
/// Create a copy of AppRelease
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppReleaseCopyWith<AppRelease> get copyWith => _$AppReleaseCopyWithImpl<AppRelease>(this as AppRelease, _$identity);

  /// Serializes this AppRelease to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AppRelease;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppRelease&&(identical(other.tagName, _this.tagName) || other.tagName == _this.tagName)&&(identical(other.body, _this.body) || other.body == _this.body)&&const DeepCollectionEquality().equals(other.assets, _this.assets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppRelease;
  return Object.hash(runtimeType,_this.tagName,_this.body,const DeepCollectionEquality().hash(_this.assets));
}

@override
String toString() {
  final _this = this as AppRelease;
  return 'AppRelease(tagName: ${_this.tagName}, body: ${_this.body}, assets: ${_this.assets})';
}


}

/// @nodoc
abstract mixin class $AppReleaseCopyWith<$Res>  {
  factory $AppReleaseCopyWith(AppRelease value, $Res Function(AppRelease) _then) = _$AppReleaseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'tag_name') String tagName, String? body, List<ReleaseAsset> assets
});




}
/// @nodoc
class _$AppReleaseCopyWithImpl<$Res>
    implements $AppReleaseCopyWith<$Res> {
  _$AppReleaseCopyWithImpl(this._self, this._then);

  final AppRelease _self;
  final $Res Function(AppRelease) _then;

/// Create a copy of AppRelease
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tagName = null,Object? body = freezed,Object? assets = null,}) {
  return _then(AppRelease(
tagName: null == tagName ? _self.tagName : tagName // ignore: cast_nullable_to_non_nullable
as String,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,assets: null == assets ? _self.assets : assets // ignore: cast_nullable_to_non_nullable
as List<ReleaseAsset>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppRelease].
extension AppReleasePatterns on AppRelease {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppRelease value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppRelease() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppRelease value)  $default,){
final _that = this;
switch (_that) {
case _AppRelease():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppRelease value)?  $default,){
final _that = this;
switch (_that) {
case _AppRelease() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'tag_name')  String tagName,  String? body,  List<ReleaseAsset> assets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppRelease() when $default != null:
return $default(_that.tagName,_that.body,_that.assets);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'tag_name')  String tagName,  String? body,  List<ReleaseAsset> assets)  $default,) {final _that = this;
switch (_that) {
case _AppRelease():
return $default(_that.tagName,_that.body,_that.assets);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'tag_name')  String tagName,  String? body,  List<ReleaseAsset> assets)?  $default,) {final _that = this;
switch (_that) {
case _AppRelease() when $default != null:
return $default(_that.tagName,_that.body,_that.assets);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppRelease implements AppRelease {
  const _AppRelease({@JsonKey(name: 'tag_name') this.tagName = '', this.body,  List<ReleaseAsset> assets = const []}): _assets = assets;
  factory _AppRelease.fromJson(Map<String, dynamic> json) => _$AppReleaseFromJson(json);

@override@JsonKey(name: 'tag_name') final  String tagName;
@override final  String? body;
 final  List<ReleaseAsset> _assets;
@override@JsonKey() List<ReleaseAsset> get assets {
  if (_assets is EqualUnmodifiableListView) return _assets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assets);
}


/// Create a copy of AppRelease
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppReleaseCopyWith<_AppRelease> get copyWith => __$AppReleaseCopyWithImpl<_AppRelease>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppReleaseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppRelease&&(identical(other.tagName, tagName) || other.tagName == tagName)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.assets, _assets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,tagName,body,const DeepCollectionEquality().hash(_assets));
}

@override
String toString() {
    return 'AppRelease(tagName: $tagName, body: $body, assets: $assets)';
}


}

/// @nodoc
abstract mixin class _$AppReleaseCopyWith<$Res> implements $AppReleaseCopyWith<$Res> {
  factory _$AppReleaseCopyWith(_AppRelease value, $Res Function(_AppRelease) _then) = __$AppReleaseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'tag_name') String tagName, String? body, List<ReleaseAsset> assets
});




}
/// @nodoc
class __$AppReleaseCopyWithImpl<$Res>
    implements _$AppReleaseCopyWith<$Res> {
  __$AppReleaseCopyWithImpl(this._self, this._then);

  final _AppRelease _self;
  final $Res Function(_AppRelease) _then;

/// Create a copy of AppRelease
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tagName = null,Object? body = freezed,Object? assets = null,}) {
  return _then(_AppRelease(
tagName: null == tagName ? _self.tagName : tagName // ignore: cast_nullable_to_non_nullable
as String,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,assets: null == assets ? _self._assets : assets // ignore: cast_nullable_to_non_nullable
as List<ReleaseAsset>,
  ));
}


}

// dart format on
