// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {

 int? get id; String get username; String get email; String get firstName; String get lastName; String get defaultCurrency; bool get darkMode; String get locale; bool get apiEnabled; Set<String> get roles; int? get defaultVehicleCategoryId;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.defaultCurrency, defaultCurrency) || other.defaultCurrency == defaultCurrency)&&(identical(other.darkMode, darkMode) || other.darkMode == darkMode)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.apiEnabled, apiEnabled) || other.apiEnabled == apiEnabled)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.defaultVehicleCategoryId, defaultVehicleCategoryId) || other.defaultVehicleCategoryId == defaultVehicleCategoryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,email,firstName,lastName,defaultCurrency,darkMode,locale,apiEnabled,const DeepCollectionEquality().hash(roles),defaultVehicleCategoryId);

@override
String toString() {
  return 'UserProfile(id: $id, username: $username, email: $email, firstName: $firstName, lastName: $lastName, defaultCurrency: $defaultCurrency, darkMode: $darkMode, locale: $locale, apiEnabled: $apiEnabled, roles: $roles, defaultVehicleCategoryId: $defaultVehicleCategoryId)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 int? id, String username, String email, String firstName, String lastName, String defaultCurrency, bool darkMode, String locale, bool apiEnabled, Set<String> roles, int? defaultVehicleCategoryId
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? username = null,Object? email = null,Object? firstName = null,Object? lastName = null,Object? defaultCurrency = null,Object? darkMode = null,Object? locale = null,Object? apiEnabled = null,Object? roles = null,Object? defaultVehicleCategoryId = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,defaultCurrency: null == defaultCurrency ? _self.defaultCurrency : defaultCurrency // ignore: cast_nullable_to_non_nullable
as String,darkMode: null == darkMode ? _self.darkMode : darkMode // ignore: cast_nullable_to_non_nullable
as bool,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,apiEnabled: null == apiEnabled ? _self.apiEnabled : apiEnabled // ignore: cast_nullable_to_non_nullable
as bool,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as Set<String>,defaultVehicleCategoryId: freezed == defaultVehicleCategoryId ? _self.defaultVehicleCategoryId : defaultVehicleCategoryId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String username,  String email,  String firstName,  String lastName,  String defaultCurrency,  bool darkMode,  String locale,  bool apiEnabled,  Set<String> roles,  int? defaultVehicleCategoryId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.username,_that.email,_that.firstName,_that.lastName,_that.defaultCurrency,_that.darkMode,_that.locale,_that.apiEnabled,_that.roles,_that.defaultVehicleCategoryId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String username,  String email,  String firstName,  String lastName,  String defaultCurrency,  bool darkMode,  String locale,  bool apiEnabled,  Set<String> roles,  int? defaultVehicleCategoryId)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.username,_that.email,_that.firstName,_that.lastName,_that.defaultCurrency,_that.darkMode,_that.locale,_that.apiEnabled,_that.roles,_that.defaultVehicleCategoryId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String username,  String email,  String firstName,  String lastName,  String defaultCurrency,  bool darkMode,  String locale,  bool apiEnabled,  Set<String> roles,  int? defaultVehicleCategoryId)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.username,_that.email,_that.firstName,_that.lastName,_that.defaultCurrency,_that.darkMode,_that.locale,_that.apiEnabled,_that.roles,_that.defaultVehicleCategoryId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfile extends UserProfile {
  const _UserProfile({this.id, this.username = '', this.email = '', this.firstName = '', this.lastName = '', this.defaultCurrency = 'EUR', this.darkMode = true, this.locale = 'de-DE', this.apiEnabled = false, final  Set<String> roles = const <String>{}, this.defaultVehicleCategoryId}): _roles = roles,super._();
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

@override final  int? id;
@override@JsonKey() final  String username;
@override@JsonKey() final  String email;
@override@JsonKey() final  String firstName;
@override@JsonKey() final  String lastName;
@override@JsonKey() final  String defaultCurrency;
@override@JsonKey() final  bool darkMode;
@override@JsonKey() final  String locale;
@override@JsonKey() final  bool apiEnabled;
 final  Set<String> _roles;
@override@JsonKey() Set<String> get roles {
  if (_roles is EqualUnmodifiableSetView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_roles);
}

@override final  int? defaultVehicleCategoryId;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.defaultCurrency, defaultCurrency) || other.defaultCurrency == defaultCurrency)&&(identical(other.darkMode, darkMode) || other.darkMode == darkMode)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.apiEnabled, apiEnabled) || other.apiEnabled == apiEnabled)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.defaultVehicleCategoryId, defaultVehicleCategoryId) || other.defaultVehicleCategoryId == defaultVehicleCategoryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,email,firstName,lastName,defaultCurrency,darkMode,locale,apiEnabled,const DeepCollectionEquality().hash(_roles),defaultVehicleCategoryId);

@override
String toString() {
  return 'UserProfile(id: $id, username: $username, email: $email, firstName: $firstName, lastName: $lastName, defaultCurrency: $defaultCurrency, darkMode: $darkMode, locale: $locale, apiEnabled: $apiEnabled, roles: $roles, defaultVehicleCategoryId: $defaultVehicleCategoryId)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 int? id, String username, String email, String firstName, String lastName, String defaultCurrency, bool darkMode, String locale, bool apiEnabled, Set<String> roles, int? defaultVehicleCategoryId
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? username = null,Object? email = null,Object? firstName = null,Object? lastName = null,Object? defaultCurrency = null,Object? darkMode = null,Object? locale = null,Object? apiEnabled = null,Object? roles = null,Object? defaultVehicleCategoryId = freezed,}) {
  return _then(_UserProfile(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,defaultCurrency: null == defaultCurrency ? _self.defaultCurrency : defaultCurrency // ignore: cast_nullable_to_non_nullable
as String,darkMode: null == darkMode ? _self.darkMode : darkMode // ignore: cast_nullable_to_non_nullable
as bool,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,apiEnabled: null == apiEnabled ? _self.apiEnabled : apiEnabled // ignore: cast_nullable_to_non_nullable
as bool,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as Set<String>,defaultVehicleCategoryId: freezed == defaultVehicleCategoryId ? _self.defaultVehicleCategoryId : defaultVehicleCategoryId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
