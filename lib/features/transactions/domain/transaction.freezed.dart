// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Transaction {

 int? get id; String get type; int? get fromAccountId; String? get fromAccountName; int? get toAccountId; String? get toAccountName;@JsonKey(fromJson: jsonToDouble) double get amount; DateTime get transactionDate; String? get status; String? get payee; int? get categoryId; String? get categoryName; String? get memo; String? get tags; String? get number; String? get paymentMethod; int? get assetId; String? get assetName;@JsonKey(fromJson: jsonToDoubleN) double? get units; int get sortOrder; List<TransactionSplit> get splits;
/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionCopyWith<Transaction> get copyWith => _$TransactionCopyWithImpl<Transaction>(this as Transaction, _$identity);

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.fromAccountId, fromAccountId) || other.fromAccountId == fromAccountId)&&(identical(other.fromAccountName, fromAccountName) || other.fromAccountName == fromAccountName)&&(identical(other.toAccountId, toAccountId) || other.toAccountId == toAccountId)&&(identical(other.toAccountName, toAccountName) || other.toAccountName == toAccountName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.payee, payee) || other.payee == payee)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.number, number) || other.number == number)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.units, units) || other.units == units)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other.splits, splits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,type,fromAccountId,fromAccountName,toAccountId,toAccountName,amount,transactionDate,status,payee,categoryId,categoryName,memo,tags,number,paymentMethod,assetId,assetName,units,sortOrder,const DeepCollectionEquality().hash(splits)]);

@override
String toString() {
  return 'Transaction(id: $id, type: $type, fromAccountId: $fromAccountId, fromAccountName: $fromAccountName, toAccountId: $toAccountId, toAccountName: $toAccountName, amount: $amount, transactionDate: $transactionDate, status: $status, payee: $payee, categoryId: $categoryId, categoryName: $categoryName, memo: $memo, tags: $tags, number: $number, paymentMethod: $paymentMethod, assetId: $assetId, assetName: $assetName, units: $units, sortOrder: $sortOrder, splits: $splits)';
}


}

/// @nodoc
abstract mixin class $TransactionCopyWith<$Res>  {
  factory $TransactionCopyWith(Transaction value, $Res Function(Transaction) _then) = _$TransactionCopyWithImpl;
@useResult
$Res call({
 int? id, String type, int? fromAccountId, String? fromAccountName, int? toAccountId, String? toAccountName,@JsonKey(fromJson: jsonToDouble) double amount, DateTime transactionDate, String? status, String? payee, int? categoryId, String? categoryName, String? memo, String? tags, String? number, String? paymentMethod, int? assetId, String? assetName,@JsonKey(fromJson: jsonToDoubleN) double? units, int sortOrder, List<TransactionSplit> splits
});




}
/// @nodoc
class _$TransactionCopyWithImpl<$Res>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._self, this._then);

  final Transaction _self;
  final $Res Function(Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? type = null,Object? fromAccountId = freezed,Object? fromAccountName = freezed,Object? toAccountId = freezed,Object? toAccountName = freezed,Object? amount = null,Object? transactionDate = null,Object? status = freezed,Object? payee = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? memo = freezed,Object? tags = freezed,Object? number = freezed,Object? paymentMethod = freezed,Object? assetId = freezed,Object? assetName = freezed,Object? units = freezed,Object? sortOrder = null,Object? splits = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,fromAccountId: freezed == fromAccountId ? _self.fromAccountId : fromAccountId // ignore: cast_nullable_to_non_nullable
as int?,fromAccountName: freezed == fromAccountName ? _self.fromAccountName : fromAccountName // ignore: cast_nullable_to_non_nullable
as String?,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as int?,toAccountName: freezed == toAccountName ? _self.toAccountName : toAccountName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,payee: freezed == payee ? _self.payee : payee // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,assetId: freezed == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as int?,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,units: freezed == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as double?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,splits: null == splits ? _self.splits : splits // ignore: cast_nullable_to_non_nullable
as List<TransactionSplit>,
  ));
}

}


/// Adds pattern-matching-related methods to [Transaction].
extension TransactionPatterns on Transaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transaction value)  $default,){
final _that = this;
switch (_that) {
case _Transaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transaction value)?  $default,){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String type,  int? fromAccountId,  String? fromAccountName,  int? toAccountId,  String? toAccountName, @JsonKey(fromJson: jsonToDouble)  double amount,  DateTime transactionDate,  String? status,  String? payee,  int? categoryId,  String? categoryName,  String? memo,  String? tags,  String? number,  String? paymentMethod,  int? assetId,  String? assetName, @JsonKey(fromJson: jsonToDoubleN)  double? units,  int sortOrder,  List<TransactionSplit> splits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.type,_that.fromAccountId,_that.fromAccountName,_that.toAccountId,_that.toAccountName,_that.amount,_that.transactionDate,_that.status,_that.payee,_that.categoryId,_that.categoryName,_that.memo,_that.tags,_that.number,_that.paymentMethod,_that.assetId,_that.assetName,_that.units,_that.sortOrder,_that.splits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String type,  int? fromAccountId,  String? fromAccountName,  int? toAccountId,  String? toAccountName, @JsonKey(fromJson: jsonToDouble)  double amount,  DateTime transactionDate,  String? status,  String? payee,  int? categoryId,  String? categoryName,  String? memo,  String? tags,  String? number,  String? paymentMethod,  int? assetId,  String? assetName, @JsonKey(fromJson: jsonToDoubleN)  double? units,  int sortOrder,  List<TransactionSplit> splits)  $default,) {final _that = this;
switch (_that) {
case _Transaction():
return $default(_that.id,_that.type,_that.fromAccountId,_that.fromAccountName,_that.toAccountId,_that.toAccountName,_that.amount,_that.transactionDate,_that.status,_that.payee,_that.categoryId,_that.categoryName,_that.memo,_that.tags,_that.number,_that.paymentMethod,_that.assetId,_that.assetName,_that.units,_that.sortOrder,_that.splits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String type,  int? fromAccountId,  String? fromAccountName,  int? toAccountId,  String? toAccountName, @JsonKey(fromJson: jsonToDouble)  double amount,  DateTime transactionDate,  String? status,  String? payee,  int? categoryId,  String? categoryName,  String? memo,  String? tags,  String? number,  String? paymentMethod,  int? assetId,  String? assetName, @JsonKey(fromJson: jsonToDoubleN)  double? units,  int sortOrder,  List<TransactionSplit> splits)?  $default,) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.type,_that.fromAccountId,_that.fromAccountName,_that.toAccountId,_that.toAccountName,_that.amount,_that.transactionDate,_that.status,_that.payee,_that.categoryId,_that.categoryName,_that.memo,_that.tags,_that.number,_that.paymentMethod,_that.assetId,_that.assetName,_that.units,_that.sortOrder,_that.splits);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Transaction extends Transaction {
  const _Transaction({this.id, this.type = 'EXPENSE', this.fromAccountId, this.fromAccountName, this.toAccountId, this.toAccountName, @JsonKey(fromJson: jsonToDouble) required this.amount, required this.transactionDate, this.status, this.payee, this.categoryId, this.categoryName, this.memo, this.tags, this.number, this.paymentMethod, this.assetId, this.assetName, @JsonKey(fromJson: jsonToDoubleN) this.units, this.sortOrder = 0, final  List<TransactionSplit> splits = const []}): _splits = splits,super._();
  factory _Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

@override final  int? id;
@override@JsonKey() final  String type;
@override final  int? fromAccountId;
@override final  String? fromAccountName;
@override final  int? toAccountId;
@override final  String? toAccountName;
@override@JsonKey(fromJson: jsonToDouble) final  double amount;
@override final  DateTime transactionDate;
@override final  String? status;
@override final  String? payee;
@override final  int? categoryId;
@override final  String? categoryName;
@override final  String? memo;
@override final  String? tags;
@override final  String? number;
@override final  String? paymentMethod;
@override final  int? assetId;
@override final  String? assetName;
@override@JsonKey(fromJson: jsonToDoubleN) final  double? units;
@override@JsonKey() final  int sortOrder;
 final  List<TransactionSplit> _splits;
@override@JsonKey() List<TransactionSplit> get splits {
  if (_splits is EqualUnmodifiableListView) return _splits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_splits);
}


/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionCopyWith<_Transaction> get copyWith => __$TransactionCopyWithImpl<_Transaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.fromAccountId, fromAccountId) || other.fromAccountId == fromAccountId)&&(identical(other.fromAccountName, fromAccountName) || other.fromAccountName == fromAccountName)&&(identical(other.toAccountId, toAccountId) || other.toAccountId == toAccountId)&&(identical(other.toAccountName, toAccountName) || other.toAccountName == toAccountName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.payee, payee) || other.payee == payee)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.number, number) || other.number == number)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.units, units) || other.units == units)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other._splits, _splits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,type,fromAccountId,fromAccountName,toAccountId,toAccountName,amount,transactionDate,status,payee,categoryId,categoryName,memo,tags,number,paymentMethod,assetId,assetName,units,sortOrder,const DeepCollectionEquality().hash(_splits)]);

@override
String toString() {
  return 'Transaction(id: $id, type: $type, fromAccountId: $fromAccountId, fromAccountName: $fromAccountName, toAccountId: $toAccountId, toAccountName: $toAccountName, amount: $amount, transactionDate: $transactionDate, status: $status, payee: $payee, categoryId: $categoryId, categoryName: $categoryName, memo: $memo, tags: $tags, number: $number, paymentMethod: $paymentMethod, assetId: $assetId, assetName: $assetName, units: $units, sortOrder: $sortOrder, splits: $splits)';
}


}

/// @nodoc
abstract mixin class _$TransactionCopyWith<$Res> implements $TransactionCopyWith<$Res> {
  factory _$TransactionCopyWith(_Transaction value, $Res Function(_Transaction) _then) = __$TransactionCopyWithImpl;
@override @useResult
$Res call({
 int? id, String type, int? fromAccountId, String? fromAccountName, int? toAccountId, String? toAccountName,@JsonKey(fromJson: jsonToDouble) double amount, DateTime transactionDate, String? status, String? payee, int? categoryId, String? categoryName, String? memo, String? tags, String? number, String? paymentMethod, int? assetId, String? assetName,@JsonKey(fromJson: jsonToDoubleN) double? units, int sortOrder, List<TransactionSplit> splits
});




}
/// @nodoc
class __$TransactionCopyWithImpl<$Res>
    implements _$TransactionCopyWith<$Res> {
  __$TransactionCopyWithImpl(this._self, this._then);

  final _Transaction _self;
  final $Res Function(_Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? type = null,Object? fromAccountId = freezed,Object? fromAccountName = freezed,Object? toAccountId = freezed,Object? toAccountName = freezed,Object? amount = null,Object? transactionDate = null,Object? status = freezed,Object? payee = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? memo = freezed,Object? tags = freezed,Object? number = freezed,Object? paymentMethod = freezed,Object? assetId = freezed,Object? assetName = freezed,Object? units = freezed,Object? sortOrder = null,Object? splits = null,}) {
  return _then(_Transaction(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,fromAccountId: freezed == fromAccountId ? _self.fromAccountId : fromAccountId // ignore: cast_nullable_to_non_nullable
as int?,fromAccountName: freezed == fromAccountName ? _self.fromAccountName : fromAccountName // ignore: cast_nullable_to_non_nullable
as String?,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as int?,toAccountName: freezed == toAccountName ? _self.toAccountName : toAccountName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,payee: freezed == payee ? _self.payee : payee // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,assetId: freezed == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as int?,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,units: freezed == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as double?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,splits: null == splits ? _self._splits : splits // ignore: cast_nullable_to_non_nullable
as List<TransactionSplit>,
  ));
}


}

// dart format on
