// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scheduled_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduledTransaction {

@JsonKey(fromJson: jsonToDouble) double get amount; DateTime get nextOccurrence; int? get id; String get type; int? get fromAccountId; String? get fromAccountName; int? get toAccountId; String? get toAccountName; String? get payee; int? get categoryId; String? get categoryName; String? get memo; String? get tags; String? get number; int? get assetId; String? get assetName;@JsonKey(fromJson: jsonToDoubleN) double? get units; String get recurrencePattern; int? get recurrenceValue; bool get enabled;
/// Create a copy of ScheduledTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledTransactionCopyWith<ScheduledTransaction> get copyWith => _$ScheduledTransactionCopyWithImpl<ScheduledTransaction>(this as ScheduledTransaction, _$identity);

  /// Serializes this ScheduledTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ScheduledTransaction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledTransaction&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.nextOccurrence, _this.nextOccurrence) || other.nextOccurrence == _this.nextOccurrence)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.fromAccountId, _this.fromAccountId) || other.fromAccountId == _this.fromAccountId)&&(identical(other.fromAccountName, _this.fromAccountName) || other.fromAccountName == _this.fromAccountName)&&(identical(other.toAccountId, _this.toAccountId) || other.toAccountId == _this.toAccountId)&&(identical(other.toAccountName, _this.toAccountName) || other.toAccountName == _this.toAccountName)&&(identical(other.payee, _this.payee) || other.payee == _this.payee)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.categoryName, _this.categoryName) || other.categoryName == _this.categoryName)&&(identical(other.memo, _this.memo) || other.memo == _this.memo)&&(identical(other.tags, _this.tags) || other.tags == _this.tags)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.assetId, _this.assetId) || other.assetId == _this.assetId)&&(identical(other.assetName, _this.assetName) || other.assetName == _this.assetName)&&(identical(other.units, _this.units) || other.units == _this.units)&&(identical(other.recurrencePattern, _this.recurrencePattern) || other.recurrencePattern == _this.recurrencePattern)&&(identical(other.recurrenceValue, _this.recurrenceValue) || other.recurrenceValue == _this.recurrenceValue)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ScheduledTransaction;
  return Object.hashAll([runtimeType,_this.amount,_this.nextOccurrence,_this.id,_this.type,_this.fromAccountId,_this.fromAccountName,_this.toAccountId,_this.toAccountName,_this.payee,_this.categoryId,_this.categoryName,_this.memo,_this.tags,_this.number,_this.assetId,_this.assetName,_this.units,_this.recurrencePattern,_this.recurrenceValue,_this.enabled]);
}

@override
String toString() {
  final _this = this as ScheduledTransaction;
  return 'ScheduledTransaction(amount: ${_this.amount}, nextOccurrence: ${_this.nextOccurrence}, id: ${_this.id}, type: ${_this.type}, fromAccountId: ${_this.fromAccountId}, fromAccountName: ${_this.fromAccountName}, toAccountId: ${_this.toAccountId}, toAccountName: ${_this.toAccountName}, payee: ${_this.payee}, categoryId: ${_this.categoryId}, categoryName: ${_this.categoryName}, memo: ${_this.memo}, tags: ${_this.tags}, number: ${_this.number}, assetId: ${_this.assetId}, assetName: ${_this.assetName}, units: ${_this.units}, recurrencePattern: ${_this.recurrencePattern}, recurrenceValue: ${_this.recurrenceValue}, enabled: ${_this.enabled})';
}


}

/// @nodoc
abstract mixin class $ScheduledTransactionCopyWith<$Res>  {
  factory $ScheduledTransactionCopyWith(ScheduledTransaction value, $Res Function(ScheduledTransaction) _then) = _$ScheduledTransactionCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: jsonToDouble) double amount, DateTime nextOccurrence, int? id, String type, int? fromAccountId, String? fromAccountName, int? toAccountId, String? toAccountName, String? payee, int? categoryId, String? categoryName, String? memo, String? tags, String? number, int? assetId, String? assetName,@JsonKey(fromJson: jsonToDoubleN) double? units, String recurrencePattern, int? recurrenceValue, bool enabled
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
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? nextOccurrence = null,Object? id = freezed,Object? type = null,Object? fromAccountId = freezed,Object? fromAccountName = freezed,Object? toAccountId = freezed,Object? toAccountName = freezed,Object? payee = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? memo = freezed,Object? tags = freezed,Object? number = freezed,Object? assetId = freezed,Object? assetName = freezed,Object? units = freezed,Object? recurrencePattern = null,Object? recurrenceValue = freezed,Object? enabled = null,}) {
  return _then(ScheduledTransaction(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,nextOccurrence: null == nextOccurrence ? _self.nextOccurrence : nextOccurrence // ignore: cast_nullable_to_non_nullable
as DateTime,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,fromAccountId: freezed == fromAccountId ? _self.fromAccountId : fromAccountId // ignore: cast_nullable_to_non_nullable
as int?,fromAccountName: freezed == fromAccountName ? _self.fromAccountName : fromAccountName // ignore: cast_nullable_to_non_nullable
as String?,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as int?,toAccountName: freezed == toAccountName ? _self.toAccountName : toAccountName // ignore: cast_nullable_to_non_nullable
as String?,payee: freezed == payee ? _self.payee : payee // ignore: cast_nullable_to_non_nullable
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
as int?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: jsonToDouble)  double amount,  DateTime nextOccurrence,  int? id,  String type,  int? fromAccountId,  String? fromAccountName,  int? toAccountId,  String? toAccountName,  String? payee,  int? categoryId,  String? categoryName,  String? memo,  String? tags,  String? number,  int? assetId,  String? assetName, @JsonKey(fromJson: jsonToDoubleN)  double? units,  String recurrencePattern,  int? recurrenceValue,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduledTransaction() when $default != null:
return $default(_that.amount,_that.nextOccurrence,_that.id,_that.type,_that.fromAccountId,_that.fromAccountName,_that.toAccountId,_that.toAccountName,_that.payee,_that.categoryId,_that.categoryName,_that.memo,_that.tags,_that.number,_that.assetId,_that.assetName,_that.units,_that.recurrencePattern,_that.recurrenceValue,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: jsonToDouble)  double amount,  DateTime nextOccurrence,  int? id,  String type,  int? fromAccountId,  String? fromAccountName,  int? toAccountId,  String? toAccountName,  String? payee,  int? categoryId,  String? categoryName,  String? memo,  String? tags,  String? number,  int? assetId,  String? assetName, @JsonKey(fromJson: jsonToDoubleN)  double? units,  String recurrencePattern,  int? recurrenceValue,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _ScheduledTransaction():
return $default(_that.amount,_that.nextOccurrence,_that.id,_that.type,_that.fromAccountId,_that.fromAccountName,_that.toAccountId,_that.toAccountName,_that.payee,_that.categoryId,_that.categoryName,_that.memo,_that.tags,_that.number,_that.assetId,_that.assetName,_that.units,_that.recurrencePattern,_that.recurrenceValue,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: jsonToDouble)  double amount,  DateTime nextOccurrence,  int? id,  String type,  int? fromAccountId,  String? fromAccountName,  int? toAccountId,  String? toAccountName,  String? payee,  int? categoryId,  String? categoryName,  String? memo,  String? tags,  String? number,  int? assetId,  String? assetName, @JsonKey(fromJson: jsonToDoubleN)  double? units,  String recurrencePattern,  int? recurrenceValue,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _ScheduledTransaction() when $default != null:
return $default(_that.amount,_that.nextOccurrence,_that.id,_that.type,_that.fromAccountId,_that.fromAccountName,_that.toAccountId,_that.toAccountName,_that.payee,_that.categoryId,_that.categoryName,_that.memo,_that.tags,_that.number,_that.assetId,_that.assetName,_that.units,_that.recurrencePattern,_that.recurrenceValue,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScheduledTransaction extends ScheduledTransaction {
  const _ScheduledTransaction({@JsonKey(fromJson: jsonToDouble) required this.amount, required this.nextOccurrence, this.id, this.type = 'EXPENSE', this.fromAccountId, this.fromAccountName, this.toAccountId, this.toAccountName, this.payee, this.categoryId, this.categoryName, this.memo, this.tags, this.number, this.assetId, this.assetName, @JsonKey(fromJson: jsonToDoubleN) this.units, this.recurrencePattern = 'MONTHLY', this.recurrenceValue, this.enabled = true}): super._();
  factory _ScheduledTransaction.fromJson(Map<String, dynamic> json) => _$ScheduledTransactionFromJson(json);

@override@JsonKey(fromJson: jsonToDouble) final  double amount;
@override final  DateTime nextOccurrence;
@override final  int? id;
@override@JsonKey() final  String type;
@override final  int? fromAccountId;
@override final  String? fromAccountName;
@override final  int? toAccountId;
@override final  String? toAccountName;
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledTransaction&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.nextOccurrence, nextOccurrence) || other.nextOccurrence == nextOccurrence)&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.fromAccountId, fromAccountId) || other.fromAccountId == fromAccountId)&&(identical(other.fromAccountName, fromAccountName) || other.fromAccountName == fromAccountName)&&(identical(other.toAccountId, toAccountId) || other.toAccountId == toAccountId)&&(identical(other.toAccountName, toAccountName) || other.toAccountName == toAccountName)&&(identical(other.payee, payee) || other.payee == payee)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.number, number) || other.number == number)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.units, units) || other.units == units)&&(identical(other.recurrencePattern, recurrencePattern) || other.recurrencePattern == recurrencePattern)&&(identical(other.recurrenceValue, recurrenceValue) || other.recurrenceValue == recurrenceValue)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,amount,nextOccurrence,id,type,fromAccountId,fromAccountName,toAccountId,toAccountName,payee,categoryId,categoryName,memo,tags,number,assetId,assetName,units,recurrencePattern,recurrenceValue,enabled]);
}

@override
String toString() {
    return 'ScheduledTransaction(amount: $amount, nextOccurrence: $nextOccurrence, id: $id, type: $type, fromAccountId: $fromAccountId, fromAccountName: $fromAccountName, toAccountId: $toAccountId, toAccountName: $toAccountName, payee: $payee, categoryId: $categoryId, categoryName: $categoryName, memo: $memo, tags: $tags, number: $number, assetId: $assetId, assetName: $assetName, units: $units, recurrencePattern: $recurrencePattern, recurrenceValue: $recurrenceValue, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$ScheduledTransactionCopyWith<$Res> implements $ScheduledTransactionCopyWith<$Res> {
  factory _$ScheduledTransactionCopyWith(_ScheduledTransaction value, $Res Function(_ScheduledTransaction) _then) = __$ScheduledTransactionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: jsonToDouble) double amount, DateTime nextOccurrence, int? id, String type, int? fromAccountId, String? fromAccountName, int? toAccountId, String? toAccountName, String? payee, int? categoryId, String? categoryName, String? memo, String? tags, String? number, int? assetId, String? assetName,@JsonKey(fromJson: jsonToDoubleN) double? units, String recurrencePattern, int? recurrenceValue, bool enabled
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
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? nextOccurrence = null,Object? id = freezed,Object? type = null,Object? fromAccountId = freezed,Object? fromAccountName = freezed,Object? toAccountId = freezed,Object? toAccountName = freezed,Object? payee = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? memo = freezed,Object? tags = freezed,Object? number = freezed,Object? assetId = freezed,Object? assetName = freezed,Object? units = freezed,Object? recurrencePattern = null,Object? recurrenceValue = freezed,Object? enabled = null,}) {
  return _then(_ScheduledTransaction(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,nextOccurrence: null == nextOccurrence ? _self.nextOccurrence : nextOccurrence // ignore: cast_nullable_to_non_nullable
as DateTime,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,fromAccountId: freezed == fromAccountId ? _self.fromAccountId : fromAccountId // ignore: cast_nullable_to_non_nullable
as int?,fromAccountName: freezed == fromAccountName ? _self.fromAccountName : fromAccountName // ignore: cast_nullable_to_non_nullable
as String?,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as int?,toAccountName: freezed == toAccountName ? _self.toAccountName : toAccountName // ignore: cast_nullable_to_non_nullable
as String?,payee: freezed == payee ? _self.payee : payee // ignore: cast_nullable_to_non_nullable
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
as int?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
