// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthState {

 UserProfile? get user; bool get registrationEnabled; Color get colorSchemeSeed; bool get biometricEnabled; bool get initialized;
/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthStateCopyWith<AuthState> get copyWith => _$AuthStateCopyWithImpl<AuthState>(this as AuthState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState&&(identical(other.user, user) || other.user == user)&&(identical(other.registrationEnabled, registrationEnabled) || other.registrationEnabled == registrationEnabled)&&(identical(other.colorSchemeSeed, colorSchemeSeed) || other.colorSchemeSeed == colorSchemeSeed)&&(identical(other.biometricEnabled, biometricEnabled) || other.biometricEnabled == biometricEnabled)&&(identical(other.initialized, initialized) || other.initialized == initialized));
}


@override
int get hashCode => Object.hash(runtimeType,user,registrationEnabled,colorSchemeSeed,biometricEnabled,initialized);

@override
String toString() {
  return 'AuthState(user: $user, registrationEnabled: $registrationEnabled, colorSchemeSeed: $colorSchemeSeed, biometricEnabled: $biometricEnabled, initialized: $initialized)';
}


}

/// @nodoc
abstract mixin class $AuthStateCopyWith<$Res>  {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) _then) = _$AuthStateCopyWithImpl;
@useResult
$Res call({
 UserProfile? user, bool registrationEnabled, Color colorSchemeSeed, bool biometricEnabled, bool initialized
});


$UserProfileCopyWith<$Res>? get user;

}
/// @nodoc
class _$AuthStateCopyWithImpl<$Res>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._self, this._then);

  final AuthState _self;
  final $Res Function(AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? user = freezed,Object? registrationEnabled = null,Object? colorSchemeSeed = null,Object? biometricEnabled = null,Object? initialized = null,}) {
  return _then(_self.copyWith(
user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserProfile?,registrationEnabled: null == registrationEnabled ? _self.registrationEnabled : registrationEnabled // ignore: cast_nullable_to_non_nullable
as bool,colorSchemeSeed: null == colorSchemeSeed ? _self.colorSchemeSeed : colorSchemeSeed // ignore: cast_nullable_to_non_nullable
as Color,biometricEnabled: null == biometricEnabled ? _self.biometricEnabled : biometricEnabled // ignore: cast_nullable_to_non_nullable
as bool,initialized: null == initialized ? _self.initialized : initialized // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserProfileCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserProfileCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthState value)  $default,){
final _that = this;
switch (_that) {
case _AuthState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserProfile? user,  bool registrationEnabled,  Color colorSchemeSeed,  bool biometricEnabled,  bool initialized)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthState() when $default != null:
return $default(_that.user,_that.registrationEnabled,_that.colorSchemeSeed,_that.biometricEnabled,_that.initialized);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserProfile? user,  bool registrationEnabled,  Color colorSchemeSeed,  bool biometricEnabled,  bool initialized)  $default,) {final _that = this;
switch (_that) {
case _AuthState():
return $default(_that.user,_that.registrationEnabled,_that.colorSchemeSeed,_that.biometricEnabled,_that.initialized);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserProfile? user,  bool registrationEnabled,  Color colorSchemeSeed,  bool biometricEnabled,  bool initialized)?  $default,) {final _that = this;
switch (_that) {
case _AuthState() when $default != null:
return $default(_that.user,_that.registrationEnabled,_that.colorSchemeSeed,_that.biometricEnabled,_that.initialized);case _:
  return null;

}
}

}

/// @nodoc


class _AuthState extends AuthState {
  const _AuthState({this.user, this.registrationEnabled = true, this.colorSchemeSeed = const Color(0xFF6750A4), this.biometricEnabled = false, this.initialized = false}): super._();
  

@override final  UserProfile? user;
@override@JsonKey() final  bool registrationEnabled;
@override@JsonKey() final  Color colorSchemeSeed;
@override@JsonKey() final  bool biometricEnabled;
@override@JsonKey() final  bool initialized;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthStateCopyWith<_AuthState> get copyWith => __$AuthStateCopyWithImpl<_AuthState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthState&&(identical(other.user, user) || other.user == user)&&(identical(other.registrationEnabled, registrationEnabled) || other.registrationEnabled == registrationEnabled)&&(identical(other.colorSchemeSeed, colorSchemeSeed) || other.colorSchemeSeed == colorSchemeSeed)&&(identical(other.biometricEnabled, biometricEnabled) || other.biometricEnabled == biometricEnabled)&&(identical(other.initialized, initialized) || other.initialized == initialized));
}


@override
int get hashCode => Object.hash(runtimeType,user,registrationEnabled,colorSchemeSeed,biometricEnabled,initialized);

@override
String toString() {
  return 'AuthState(user: $user, registrationEnabled: $registrationEnabled, colorSchemeSeed: $colorSchemeSeed, biometricEnabled: $biometricEnabled, initialized: $initialized)';
}


}

/// @nodoc
abstract mixin class _$AuthStateCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory _$AuthStateCopyWith(_AuthState value, $Res Function(_AuthState) _then) = __$AuthStateCopyWithImpl;
@override @useResult
$Res call({
 UserProfile? user, bool registrationEnabled, Color colorSchemeSeed, bool biometricEnabled, bool initialized
});


@override $UserProfileCopyWith<$Res>? get user;

}
/// @nodoc
class __$AuthStateCopyWithImpl<$Res>
    implements _$AuthStateCopyWith<$Res> {
  __$AuthStateCopyWithImpl(this._self, this._then);

  final _AuthState _self;
  final $Res Function(_AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? user = freezed,Object? registrationEnabled = null,Object? colorSchemeSeed = null,Object? biometricEnabled = null,Object? initialized = null,}) {
  return _then(_AuthState(
user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserProfile?,registrationEnabled: null == registrationEnabled ? _self.registrationEnabled : registrationEnabled // ignore: cast_nullable_to_non_nullable
as bool,colorSchemeSeed: null == colorSchemeSeed ? _self.colorSchemeSeed : colorSchemeSeed // ignore: cast_nullable_to_non_nullable
as Color,biometricEnabled: null == biometricEnabled ? _self.biometricEnabled : biometricEnabled // ignore: cast_nullable_to_non_nullable
as bool,initialized: null == initialized ? _self.initialized : initialized // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserProfileCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserProfileCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
