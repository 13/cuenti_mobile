// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuditState {

 List<AuditEntry> get items; int get nextPage; bool get hasMore; bool get loadingMore; String? get filter;
/// Create a copy of AuditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditStateCopyWith<AuditState> get copyWith => _$AuditStateCopyWithImpl<AuditState>(this as AuditState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditState&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextPage, nextPage) || other.nextPage == nextPage)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.filter, filter) || other.filter == filter));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextPage,hasMore,loadingMore,filter);

@override
String toString() {
  return 'AuditState(items: $items, nextPage: $nextPage, hasMore: $hasMore, loadingMore: $loadingMore, filter: $filter)';
}


}

/// @nodoc
abstract mixin class $AuditStateCopyWith<$Res>  {
  factory $AuditStateCopyWith(AuditState value, $Res Function(AuditState) _then) = _$AuditStateCopyWithImpl;
@useResult
$Res call({
 List<AuditEntry> items, int nextPage, bool hasMore, bool loadingMore, String? filter
});




}
/// @nodoc
class _$AuditStateCopyWithImpl<$Res>
    implements $AuditStateCopyWith<$Res> {
  _$AuditStateCopyWithImpl(this._self, this._then);

  final AuditState _self;
  final $Res Function(AuditState) _then;

/// Create a copy of AuditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextPage = null,Object? hasMore = null,Object? loadingMore = null,Object? filter = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AuditEntry>,nextPage: null == nextPage ? _self.nextPage : nextPage // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,filter: freezed == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditState].
extension AuditStatePatterns on AuditState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditState value)  $default,){
final _that = this;
switch (_that) {
case _AuditState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditState value)?  $default,){
final _that = this;
switch (_that) {
case _AuditState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AuditEntry> items,  int nextPage,  bool hasMore,  bool loadingMore,  String? filter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditState() when $default != null:
return $default(_that.items,_that.nextPage,_that.hasMore,_that.loadingMore,_that.filter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AuditEntry> items,  int nextPage,  bool hasMore,  bool loadingMore,  String? filter)  $default,) {final _that = this;
switch (_that) {
case _AuditState():
return $default(_that.items,_that.nextPage,_that.hasMore,_that.loadingMore,_that.filter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AuditEntry> items,  int nextPage,  bool hasMore,  bool loadingMore,  String? filter)?  $default,) {final _that = this;
switch (_that) {
case _AuditState() when $default != null:
return $default(_that.items,_that.nextPage,_that.hasMore,_that.loadingMore,_that.filter);case _:
  return null;

}
}

}

/// @nodoc


class _AuditState implements AuditState {
  const _AuditState({final  List<AuditEntry> items = const [], this.nextPage = 0, this.hasMore = true, this.loadingMore = false, this.filter}): _items = items;
  

 final  List<AuditEntry> _items;
@override@JsonKey() List<AuditEntry> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int nextPage;
@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  bool loadingMore;
@override final  String? filter;

/// Create a copy of AuditState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditStateCopyWith<_AuditState> get copyWith => __$AuditStateCopyWithImpl<_AuditState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditState&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextPage, nextPage) || other.nextPage == nextPage)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.filter, filter) || other.filter == filter));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextPage,hasMore,loadingMore,filter);

@override
String toString() {
  return 'AuditState(items: $items, nextPage: $nextPage, hasMore: $hasMore, loadingMore: $loadingMore, filter: $filter)';
}


}

/// @nodoc
abstract mixin class _$AuditStateCopyWith<$Res> implements $AuditStateCopyWith<$Res> {
  factory _$AuditStateCopyWith(_AuditState value, $Res Function(_AuditState) _then) = __$AuditStateCopyWithImpl;
@override @useResult
$Res call({
 List<AuditEntry> items, int nextPage, bool hasMore, bool loadingMore, String? filter
});




}
/// @nodoc
class __$AuditStateCopyWithImpl<$Res>
    implements _$AuditStateCopyWith<$Res> {
  __$AuditStateCopyWithImpl(this._self, this._then);

  final _AuditState _self;
  final $Res Function(_AuditState) _then;

/// Create a copy of AuditState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextPage = null,Object? hasMore = null,Object? loadingMore = null,Object? filter = freezed,}) {
  return _then(_AuditState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AuditEntry>,nextPage: null == nextPage ? _self.nextPage : nextPage // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,filter: freezed == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
