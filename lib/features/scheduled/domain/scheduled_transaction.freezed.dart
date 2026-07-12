// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scheduled_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduledTransaction {

 int? get id; String get type; int? get fromAccountId; String? get fromAccountName; int? get toAccountId; String? get toAccountName;@JsonKey(fromJson: jsonToDouble) double get amount; String? get payee; int? get categoryId; String? get categoryName; String? get memo; String? get tags; String? get number; int? get assetId; String? get assetName;@JsonKey(fromJson: jsonToDoubleN) double? get units; String get recurrencePattern; int? get recurrenceValue; DateTime get nextOccurrence; bool get enabled;
/// Create a copy of ScheduledTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledTransactionCopyWith<ScheduledTransaction> get copyWith => _$ScheduledTransactionCopyWithImpl<ScheduledTransaction>(this as ScheduledTransaction, _$identity);

  /// Serializes this ScheduledTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.fromAccountId, fromAccountId) || other.fromAccountId == fromAccountId)&&(identical(other.fromAccountName, fromAccountName) || other.fromAccountName == fromAccountName)&&(identical(other.toAccountId, toAccountId) || other.toAccountId == toAccountId)&&(identical(other.toAccountName, toAccountName) || other.toAccountName == toAccountName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.payee, payee) || other.payee == payee)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.number, number) || other.number == number)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.units, units) || other.units == units)&&(identical(other.recurrencePattern, recurrencePattern) || other.recurrencePattern == recurrencePattern)&&(identical(other.recurrenceValue, recurrenceValue) || other.recurrenceValue == recurrenceValue)&&(identical(other.nextOccurrence, nextOccurrence) || other.nextOccurrence == nextOccurrence)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,type,fromAccountId,fromAccountName,toAccountId,toAccountName,amount,payee,categoryId,categoryName,memo,tags,number,assetId,assetName,units,recurrencePattern,recurrenceValue,nextOccurrence,enabled]);

@override
String toString() {
  return 'ScheduledTransaction(id: $id, type: $type, fromAccountId: $fromAccountId, fromAccountName: $fromAccountName, toAccountId: $toAccountId, toAccountName: $toAccountName, amount: $amount, payee: $payee, categoryId: $categoryId, categoryName: $categoryName, memo: $memo, tags: $tags, number: $number, assetId: $assetId, assetName: $assetName, units: $units, recurrencePattern: $recurrencePattern, recurrenceValue: $recurrenceValue, nextOccurrence: $nextOccurrence, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $ScheduledTransactionCopyWith<$Res>  {
  factory $ScheduledTransactionCopyWith(ScheduledTransaction value, $Res Function(ScheduledTransaction) _then) = _$ScheduledTransactionCopyWithImpl;
@useResult
$Res call({
 int? id, String type, int? fromAccountId, String? fromAccountName, int? toAccountId, String? toAccountName,@JsonKey(fromJson: jsonToDouble) double amount, String? payee, int? categoryId, String? categoryName, String? memo, String? tags, String? number, int? assetId, String? assetName,@JsonKey(fromJson: jsonToDoubleN) double? units, String recurrencePattern, int? recurrenceValue, DateTime nextOccurrence, bool enabled
});




}
/// @nodoc
class _$ScheduledTransactionCopyWithImpl<$Res>
    implements $ScheduledTransactionCopyWith<$Res> {
  _$ScheduledTransactionCopyWithImpl(this._self, this._then);

  final ScheduledTransaction _self;
  final $Res Function(ScheduledTransaction) _then;

/// Create a copy of ScheduledTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? type = null,Object? fromAccountId = freezed,Object? fromAccountName = freezed,Object? toAccountId = freezed,Object? toAccountName = freezed,Object? amount = null,Object? payee = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? memo = freezed,Object? tags = freezed,Object? number = freezed,Object? assetId = freezed,Object? assetName = freezed,Object? units = freezed,Object? recurrencePattern = null,Object? recurrenceValue = freezed,Object? nextOccurrence = null,Object? enabled = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,fromAccountId: freezed == fromAccountId ? _self.fromAccountId : fromAccountId // ignore: cast_nullable_to_non_nullable
as int?,fromAccountName: freezed == fromAccountName ? _self.fromAccountName : fromAccountName // ignore: cast_nullable_to_non_nullable
as String?,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as int?,toAccountName: freezed == toAccountName ? _self.toAccountName : toAccountName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,payee: freezed == payee ? _self.payee : payee // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String?,assetId: freezed == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as int?,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,units: freezed == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as double?,recurrencePattern: null == recurrencePattern ? _self.recurrencePattern : recurrencePattern // ignore: cast_nullable_to_non_nullable
as String,recurrenceValue: freezed == recurrenceValue ? _self.recurrenceValue : recurrenceValue // ignore: cast_nullable_to_non_nullable
as int?,nextOccurrence: null == nextOccurrence ? _self.nextOccurrence : nextOccurrence // ignore: cast_nullable_to_non_nullable
as DateTime,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduledTransaction].
extension ScheduledTransactionPatterns on ScheduledTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledTransaction value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String type,  int? fromAccountId,  String? fromAccountName,  int? toAccountId,  String? toAccountName, @JsonKey(fromJson: jsonToDouble)  double amount,  String? payee,  int? categoryId,  String? categoryName,  String? memo,  String? tags,  String? number,  int? assetId,  String? assetName, @JsonKey(fromJson: jsonToDoubleN)  double? units,  String recurrencePattern,  int? recurrenceValue,  DateTime nextOccurrence,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduledTransaction() when $default != null:
return $default(_that.id,_that.type,_that.fromAccountId,_that.fromAccountName,_that.toAccountId,_that.toAccountName,_that.amount,_that.payee,_that.categoryId,_that.categoryName,_that.memo,_that.tags,_that.number,_that.assetId,_that.assetName,_that.units,_that.recurrencePattern,_that.recurrenceValue,_that.nextOccurrence,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String type,  int? fromAccountId,  String? fromAccountName,  int? toAccountId,  String? toAccountName, @JsonKey(fromJson: jsonToDouble)  double amount,  String? payee,  int? categoryId,  String? categoryName,  String? memo,  String? tags,  String? number,  int? assetId,  String? assetName, @JsonKey(fromJson: jsonToDoubleN)  double? units,  String recurrencePattern,  int? recurrenceValue,  DateTime nextOccurrence,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _ScheduledTransaction():
return $default(_that.id,_that.type,_that.fromAccountId,_that.fromAccountName,_that.toAccountId,_that.toAccountName,_that.amount,_that.payee,_that.categoryId,_that.categoryName,_that.memo,_that.tags,_that.number,_that.assetId,_that.assetName,_that.units,_that.recurrencePattern,_that.recurrenceValue,_that.nextOccurrence,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String type,  int? fromAccountId,  String? fromAccountName,  int? toAccountId,  String? toAccountName, @JsonKey(fromJson: jsonToDouble)  double amount,  String? payee,  int? categoryId,  String? categoryName,  String? memo,  String? tags,  String? number,  int? assetId,  String? assetName, @JsonKey(fromJson: jsonToDoubleN)  double? units,  String recurrencePattern,  int? recurrenceValue,  DateTime nextOccurrence,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _ScheduledTransaction() when $default != null:
return $default(_that.id,_that.type,_that.fromAccountId,_that.fromAccountName,_that.toAccountId,_that.toAccountName,_that.amount,_that.payee,_that.categoryId,_that.categoryName,_that.memo,_that.tags,_that.number,_that.assetId,_that.assetName,_that.units,_that.recurrencePattern,_that.recurrenceValue,_that.nextOccurrence,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScheduledTransaction extends ScheduledTransaction {
  const _ScheduledTransaction({this.id, this.type = 'EXPENSE', this.fromAccountId, this.fromAccountName, this.toAccountId, this.toAccountName, @JsonKey(fromJson: jsonToDouble) required this.amount, this.payee, this.categoryId, this.categoryName, this.memo, this.tags, this.number, this.assetId, this.assetName, @JsonKey(fromJson: jsonToDoubleN) this.units, this.recurrencePattern = 'MONTHLY', this.recurrenceValue, required this.nextOccurrence, this.enabled = true}): super._();
  factory _ScheduledTransaction.fromJson(Map<String, dynamic> json) => _$ScheduledTransactionFromJson(json);

@override final  int? id;
@override@JsonKey() final  String type;
@override final  int? fromAccountId;
@override final  String? fromAccountName;
@override final  int? toAccountId;
@override final  String? toAccountName;
@override@JsonKey(fromJson: jsonToDouble) final  double amount;
@override final  String? payee;
@override final  int? categoryId;
@override final  String? categoryName;
@override final  String? memo;
@override final  String? tags;
@override final  String? number;
@override final  int? assetId;
@override final  String? assetName;
@override@JsonKey(fromJson: jsonToDoubleN) final  double? units;
@override@JsonKey() final  String recurrencePattern;
@override final  int? recurrenceValue;
@override final  DateTime nextOccurrence;
@override@JsonKey() final  bool enabled;

/// Create a copy of ScheduledTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledTransactionCopyWith<_ScheduledTransaction> get copyWith => __$ScheduledTransactionCopyWithImpl<_ScheduledTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduledTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.fromAccountId, fromAccountId) || other.fromAccountId == fromAccountId)&&(identical(other.fromAccountName, fromAccountName) || other.fromAccountName == fromAccountName)&&(identical(other.toAccountId, toAccountId) || other.toAccountId == toAccountId)&&(identical(other.toAccountName, toAccountName) || other.toAccountName == toAccountName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.payee, payee) || other.payee == payee)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.number, number) || other.number == number)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.units, units) || other.units == units)&&(identical(other.recurrencePattern, recurrencePattern) || other.recurrencePattern == recurrencePattern)&&(identical(other.recurrenceValue, recurrenceValue) || other.recurrenceValue == recurrenceValue)&&(identical(other.nextOccurrence, nextOccurrence) || other.nextOccurrence == nextOccurrence)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,type,fromAccountId,fromAccountName,toAccountId,toAccountName,amount,payee,categoryId,categoryName,memo,tags,number,assetId,assetName,units,recurrencePattern,recurrenceValue,nextOccurrence,enabled]);

@override
String toString() {
  return 'ScheduledTransaction(id: $id, type: $type, fromAccountId: $fromAccountId, fromAccountName: $fromAccountName, toAccountId: $toAccountId, toAccountName: $toAccountName, amount: $amount, payee: $payee, categoryId: $categoryId, categoryName: $categoryName, memo: $memo, tags: $tags, number: $number, assetId: $assetId, assetName: $assetName, units: $units, recurrencePattern: $recurrencePattern, recurrenceValue: $recurrenceValue, nextOccurrence: $nextOccurrence, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$ScheduledTransactionCopyWith<$Res> implements $ScheduledTransactionCopyWith<$Res> {
  factory _$ScheduledTransactionCopyWith(_ScheduledTransaction value, $Res Function(_ScheduledTransaction) _then) = __$ScheduledTransactionCopyWithImpl;
@override @useResult
$Res call({
 int? id, String type, int? fromAccountId, String? fromAccountName, int? toAccountId, String? toAccountName,@JsonKey(fromJson: jsonToDouble) double amount, String? payee, int? categoryId, String? categoryName, String? memo, String? tags, String? number, int? assetId, String? assetName,@JsonKey(fromJson: jsonToDoubleN) double? units, String recurrencePattern, int? recurrenceValue, DateTime nextOccurrence, bool enabled
});




}
/// @nodoc
class __$ScheduledTransactionCopyWithImpl<$Res>
    implements _$ScheduledTransactionCopyWith<$Res> {
  __$ScheduledTransactionCopyWithImpl(this._self, this._then);

  final _ScheduledTransaction _self;
  final $Res Function(_ScheduledTransaction) _then;

/// Create a copy of ScheduledTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? type = null,Object? fromAccountId = freezed,Object? fromAccountName = freezed,Object? toAccountId = freezed,Object? toAccountName = freezed,Object? amount = null,Object? payee = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? memo = freezed,Object? tags = freezed,Object? number = freezed,Object? assetId = freezed,Object? assetName = freezed,Object? units = freezed,Object? recurrencePattern = null,Object? recurrenceValue = freezed,Object? nextOccurrence = null,Object? enabled = null,}) {
  return _then(_ScheduledTransaction(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,fromAccountId: freezed == fromAccountId ? _self.fromAccountId : fromAccountId // ignore: cast_nullable_to_non_nullable
as int?,fromAccountName: freezed == fromAccountName ? _self.fromAccountName : fromAccountName // ignore: cast_nullable_to_non_nullable
as String?,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as int?,toAccountName: freezed == toAccountName ? _self.toAccountName : toAccountName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,payee: freezed == payee ? _self.payee : payee // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String?,assetId: freezed == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as int?,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,units: freezed == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as double?,recurrencePattern: null == recurrencePattern ? _self.recurrencePattern : recurrencePattern // ignore: cast_nullable_to_non_nullable
as String,recurrenceValue: freezed == recurrenceValue ? _self.recurrenceValue : recurrenceValue // ignore: cast_nullable_to_non_nullable
as int?,nextOccurrence: null == nextOccurrence ? _self.nextOccurrence : nextOccurrence // ignore: cast_nullable_to_non_nullable
as DateTime,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
