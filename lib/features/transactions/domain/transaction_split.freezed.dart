// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_split.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransactionSplit {

 int? get id; int? get categoryId; String? get categoryName;@JsonKey(fromJson: jsonToDouble) double get amount; String? get memo;
/// Create a copy of TransactionSplit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionSplitCopyWith<TransactionSplit> get copyWith => _$TransactionSplitCopyWithImpl<TransactionSplit>(this as TransactionSplit, _$identity);

  /// Serializes this TransactionSplit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionSplit&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.memo, memo) || other.memo == memo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,categoryId,categoryName,amount,memo);

@override
String toString() {
  return 'TransactionSplit(id: $id, categoryId: $categoryId, categoryName: $categoryName, amount: $amount, memo: $memo)';
}


}

/// @nodoc
abstract mixin class $TransactionSplitCopyWith<$Res>  {
  factory $TransactionSplitCopyWith(TransactionSplit value, $Res Function(TransactionSplit) _then) = _$TransactionSplitCopyWithImpl;
@useResult
$Res call({
 int? id, int? categoryId, String? categoryName,@JsonKey(fromJson: jsonToDouble) double amount, String? memo
});




}
/// @nodoc
class _$TransactionSplitCopyWithImpl<$Res>
    implements $TransactionSplitCopyWith<$Res> {
  _$TransactionSplitCopyWithImpl(this._self, this._then);

  final TransactionSplit _self;
  final $Res Function(TransactionSplit) _then;

/// Create a copy of TransactionSplit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? amount = null,Object? memo = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionSplit].
extension TransactionSplitPatterns on TransactionSplit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionSplit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionSplit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionSplit value)  $default,){
final _that = this;
switch (_that) {
case _TransactionSplit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionSplit value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionSplit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  int? categoryId,  String? categoryName, @JsonKey(fromJson: jsonToDouble)  double amount,  String? memo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionSplit() when $default != null:
return $default(_that.id,_that.categoryId,_that.categoryName,_that.amount,_that.memo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  int? categoryId,  String? categoryName, @JsonKey(fromJson: jsonToDouble)  double amount,  String? memo)  $default,) {final _that = this;
switch (_that) {
case _TransactionSplit():
return $default(_that.id,_that.categoryId,_that.categoryName,_that.amount,_that.memo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  int? categoryId,  String? categoryName, @JsonKey(fromJson: jsonToDouble)  double amount,  String? memo)?  $default,) {final _that = this;
switch (_that) {
case _TransactionSplit() when $default != null:
return $default(_that.id,_that.categoryId,_that.categoryName,_that.amount,_that.memo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransactionSplit extends TransactionSplit {
  const _TransactionSplit({this.id, this.categoryId, this.categoryName, @JsonKey(fromJson: jsonToDouble) required this.amount, this.memo}): super._();
  factory _TransactionSplit.fromJson(Map<String, dynamic> json) => _$TransactionSplitFromJson(json);

@override final  int? id;
@override final  int? categoryId;
@override final  String? categoryName;
@override@JsonKey(fromJson: jsonToDouble) final  double amount;
@override final  String? memo;

/// Create a copy of TransactionSplit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionSplitCopyWith<_TransactionSplit> get copyWith => __$TransactionSplitCopyWithImpl<_TransactionSplit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionSplitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionSplit&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.memo, memo) || other.memo == memo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,categoryId,categoryName,amount,memo);

@override
String toString() {
  return 'TransactionSplit(id: $id, categoryId: $categoryId, categoryName: $categoryName, amount: $amount, memo: $memo)';
}


}

/// @nodoc
abstract mixin class _$TransactionSplitCopyWith<$Res> implements $TransactionSplitCopyWith<$Res> {
  factory _$TransactionSplitCopyWith(_TransactionSplit value, $Res Function(_TransactionSplit) _then) = __$TransactionSplitCopyWithImpl;
@override @useResult
$Res call({
 int? id, int? categoryId, String? categoryName,@JsonKey(fromJson: jsonToDouble) double amount, String? memo
});




}
/// @nodoc
class __$TransactionSplitCopyWithImpl<$Res>
    implements _$TransactionSplitCopyWith<$Res> {
  __$TransactionSplitCopyWithImpl(this._self, this._then);

  final _TransactionSplit _self;
  final $Res Function(_TransactionSplit) _then;

/// Create a copy of TransactionSplit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? amount = null,Object? memo = freezed,}) {
  return _then(_TransactionSplit(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
