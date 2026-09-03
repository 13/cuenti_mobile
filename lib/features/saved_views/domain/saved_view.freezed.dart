// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_view.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SavedView {

 String get name; int? get id; String? get params; DateTime? get createdAt;
/// Create a copy of SavedView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedViewCopyWith<SavedView> get copyWith => _$SavedViewCopyWithImpl<SavedView>(this as SavedView, _$identity);

  /// Serializes this SavedView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedView&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id)&&(identical(other.params, params) || other.params == params)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,id,params,createdAt);

@override
String toString() {
  return 'SavedView(name: $name, id: $id, params: $params, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SavedViewCopyWith<$Res>  {
  factory $SavedViewCopyWith(SavedView value, $Res Function(SavedView) _then) = _$SavedViewCopyWithImpl;
@useResult
$Res call({
 String name, int? id, String? params, DateTime? createdAt
});




}
/// @nodoc
class _$SavedViewCopyWithImpl<$Res>
    implements $SavedViewCopyWith<$Res> {
  _$SavedViewCopyWithImpl(this._self, this._then);

  final SavedView _self;
  final $Res Function(SavedView) _then;

/// Create a copy of SavedView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? id = freezed,Object? params = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,params: freezed == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedView].
extension SavedViewPatterns on SavedView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedView value)  $default,){
final _that = this;
switch (_that) {
case _SavedView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedView value)?  $default,){
final _that = this;
switch (_that) {
case _SavedView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int? id,  String? params,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedView() when $default != null:
return $default(_that.name,_that.id,_that.params,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int? id,  String? params,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _SavedView():
return $default(_that.name,_that.id,_that.params,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int? id,  String? params,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SavedView() when $default != null:
return $default(_that.name,_that.id,_that.params,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedView implements SavedView {
  const _SavedView({required this.name, this.id, this.params, this.createdAt});
  factory _SavedView.fromJson(Map<String, dynamic> json) => _$SavedViewFromJson(json);

@override final  String name;
@override final  int? id;
@override final  String? params;
@override final  DateTime? createdAt;

/// Create a copy of SavedView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedViewCopyWith<_SavedView> get copyWith => __$SavedViewCopyWithImpl<_SavedView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedView&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id)&&(identical(other.params, params) || other.params == params)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,id,params,createdAt);

@override
String toString() {
  return 'SavedView(name: $name, id: $id, params: $params, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SavedViewCopyWith<$Res> implements $SavedViewCopyWith<$Res> {
  factory _$SavedViewCopyWith(_SavedView value, $Res Function(_SavedView) _then) = __$SavedViewCopyWithImpl;
@override @useResult
$Res call({
 String name, int? id, String? params, DateTime? createdAt
});




}
/// @nodoc
class __$SavedViewCopyWithImpl<$Res>
    implements _$SavedViewCopyWith<$Res> {
  __$SavedViewCopyWithImpl(this._self, this._then);

  final _SavedView _self;
  final $Res Function(_SavedView) _then;

/// Create a copy of SavedView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? id = freezed,Object? params = freezed,Object? createdAt = freezed,}) {
  return _then(_SavedView(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,params: freezed == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
