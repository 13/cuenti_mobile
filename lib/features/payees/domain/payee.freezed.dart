// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payee.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Payee {

 int? get id; String get name; String? get notes; int? get defaultCategoryId; String? get defaultCategoryName; String? get defaultPaymentMethod;
/// Create a copy of Payee
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayeeCopyWith<Payee> get copyWith => _$PayeeCopyWithImpl<Payee>(this as Payee, _$identity);

  /// Serializes this Payee to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Payee&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.defaultCategoryId, defaultCategoryId) || other.defaultCategoryId == defaultCategoryId)&&(identical(other.defaultCategoryName, defaultCategoryName) || other.defaultCategoryName == defaultCategoryName)&&(identical(other.defaultPaymentMethod, defaultPaymentMethod) || other.defaultPaymentMethod == defaultPaymentMethod));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,notes,defaultCategoryId,defaultCategoryName,defaultPaymentMethod);

@override
String toString() {
  return 'Payee(id: $id, name: $name, notes: $notes, defaultCategoryId: $defaultCategoryId, defaultCategoryName: $defaultCategoryName, defaultPaymentMethod: $defaultPaymentMethod)';
}


}

/// @nodoc
abstract mixin class $PayeeCopyWith<$Res>  {
  factory $PayeeCopyWith(Payee value, $Res Function(Payee) _then) = _$PayeeCopyWithImpl;
@useResult
$Res call({
 int? id, String name, String? notes, int? defaultCategoryId, String? defaultCategoryName, String? defaultPaymentMethod
});




}
/// @nodoc
class _$PayeeCopyWithImpl<$Res>
    implements $PayeeCopyWith<$Res> {
  _$PayeeCopyWithImpl(this._self, this._then);

  final Payee _self;
  final $Res Function(Payee) _then;

/// Create a copy of Payee
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? notes = freezed,Object? defaultCategoryId = freezed,Object? defaultCategoryName = freezed,Object? defaultPaymentMethod = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,defaultCategoryId: freezed == defaultCategoryId ? _self.defaultCategoryId : defaultCategoryId // ignore: cast_nullable_to_non_nullable
as int?,defaultCategoryName: freezed == defaultCategoryName ? _self.defaultCategoryName : defaultCategoryName // ignore: cast_nullable_to_non_nullable
as String?,defaultPaymentMethod: freezed == defaultPaymentMethod ? _self.defaultPaymentMethod : defaultPaymentMethod // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Payee].
extension PayeePatterns on Payee {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Payee value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Payee() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Payee value)  $default,){
final _that = this;
switch (_that) {
case _Payee():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Payee value)?  $default,){
final _that = this;
switch (_that) {
case _Payee() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String name,  String? notes,  int? defaultCategoryId,  String? defaultCategoryName,  String? defaultPaymentMethod)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Payee() when $default != null:
return $default(_that.id,_that.name,_that.notes,_that.defaultCategoryId,_that.defaultCategoryName,_that.defaultPaymentMethod);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String name,  String? notes,  int? defaultCategoryId,  String? defaultCategoryName,  String? defaultPaymentMethod)  $default,) {final _that = this;
switch (_that) {
case _Payee():
return $default(_that.id,_that.name,_that.notes,_that.defaultCategoryId,_that.defaultCategoryName,_that.defaultPaymentMethod);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String name,  String? notes,  int? defaultCategoryId,  String? defaultCategoryName,  String? defaultPaymentMethod)?  $default,) {final _that = this;
switch (_that) {
case _Payee() when $default != null:
return $default(_that.id,_that.name,_that.notes,_that.defaultCategoryId,_that.defaultCategoryName,_that.defaultPaymentMethod);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Payee extends Payee {
  const _Payee({this.id, this.name = '', this.notes, this.defaultCategoryId, this.defaultCategoryName, this.defaultPaymentMethod}): super._();
  factory _Payee.fromJson(Map<String, dynamic> json) => _$PayeeFromJson(json);

@override final  int? id;
@override@JsonKey() final  String name;
@override final  String? notes;
@override final  int? defaultCategoryId;
@override final  String? defaultCategoryName;
@override final  String? defaultPaymentMethod;

/// Create a copy of Payee
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayeeCopyWith<_Payee> get copyWith => __$PayeeCopyWithImpl<_Payee>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayeeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Payee&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.defaultCategoryId, defaultCategoryId) || other.defaultCategoryId == defaultCategoryId)&&(identical(other.defaultCategoryName, defaultCategoryName) || other.defaultCategoryName == defaultCategoryName)&&(identical(other.defaultPaymentMethod, defaultPaymentMethod) || other.defaultPaymentMethod == defaultPaymentMethod));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,notes,defaultCategoryId,defaultCategoryName,defaultPaymentMethod);

@override
String toString() {
  return 'Payee(id: $id, name: $name, notes: $notes, defaultCategoryId: $defaultCategoryId, defaultCategoryName: $defaultCategoryName, defaultPaymentMethod: $defaultPaymentMethod)';
}


}

/// @nodoc
abstract mixin class _$PayeeCopyWith<$Res> implements $PayeeCopyWith<$Res> {
  factory _$PayeeCopyWith(_Payee value, $Res Function(_Payee) _then) = __$PayeeCopyWithImpl;
@override @useResult
$Res call({
 int? id, String name, String? notes, int? defaultCategoryId, String? defaultCategoryName, String? defaultPaymentMethod
});




}
/// @nodoc
class __$PayeeCopyWithImpl<$Res>
    implements _$PayeeCopyWith<$Res> {
  __$PayeeCopyWithImpl(this._self, this._then);

  final _Payee _self;
  final $Res Function(_Payee) _then;

/// Create a copy of Payee
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? notes = freezed,Object? defaultCategoryId = freezed,Object? defaultCategoryName = freezed,Object? defaultPaymentMethod = freezed,}) {
  return _then(_Payee(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,defaultCategoryId: freezed == defaultCategoryId ? _self.defaultCategoryId : defaultCategoryId // ignore: cast_nullable_to_non_nullable
as int?,defaultCategoryName: freezed == defaultCategoryName ? _self.defaultCategoryName : defaultCategoryName // ignore: cast_nullable_to_non_nullable
as String?,defaultPaymentMethod: freezed == defaultPaymentMethod ? _self.defaultPaymentMethod : defaultPaymentMethod // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
