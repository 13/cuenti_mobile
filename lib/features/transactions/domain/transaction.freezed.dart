// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Transaction {

@JsonKey(fromJson: jsonToDouble) double get amount; DateTime get transactionDate; int? get id; String get type; int? get fromAccountId; String? get fromAccountName; int? get toAccountId; String? get toAccountName; String? get status; String? get payee; int? get categoryId; String? get categoryName; String? get memo; String? get tags; String? get number; String? get paymentMethod; int? get assetId; String? get assetName;@JsonKey(fromJson: jsonToDoubleN) double? get units; int get sortOrder; List<TransactionSplit> get splits;
/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionCopyWith<Transaction> get copyWith => _$TransactionCopyWithImpl<Transaction>(this as Transaction, _$identity);

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Transaction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transaction&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.transactionDate, _this.transactionDate) || other.transactionDate == _this.transactionDate)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.fromAccountId, _this.fromAccountId) || other.fromAccountId == _this.fromAccountId)&&(identical(other.fromAccountName, _this.fromAccountName) || other.fromAccountName == _this.fromAccountName)&&(identical(other.toAccountId, _this.toAccountId) || other.toAccountId == _this.toAccountId)&&(identical(other.toAccountName, _this.toAccountName) || other.toAccountName == _this.toAccountName)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.payee, _this.payee) || other.payee == _this.payee)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.categoryName, _this.categoryName) || other.categoryName == _this.categoryName)&&(identical(other.memo, _this.memo) || other.memo == _this.memo)&&(identical(other.tags, _this.tags) || other.tags == _this.tags)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.paymentMethod, _this.paymentMethod) || other.paymentMethod == _this.paymentMethod)&&(identical(other.assetId, _this.assetId) || other.assetId == _this.assetId)&&(identical(other.assetName, _this.assetName) || other.assetName == _this.assetName)&&(identical(other.units, _this.units) || other.units == _this.units)&&(identical(other.sortOrder, _this.sortOrder) || other.sortOrder == _this.sortOrder)&&const DeepCollectionEquality().equals(other.splits, _this.splits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Transaction;
  return Object.hashAll([runtimeType,_this.amount,_this.transactionDate,_this.id,_this.type,_this.fromAccountId,_this.fromAccountName,_this.toAccountId,_this.toAccountName,_this.status,_this.payee,_this.categoryId,_this.categoryName,_this.memo,_this.tags,_this.number,_this.paymentMethod,_this.assetId,_this.assetName,_this.units,_this.sortOrder,const DeepCollectionEquality().hash(_this.splits)]);
}

@override
String toString() {
  final _this = this as Transaction;
  return 'Transaction(amount: ${_this.amount}, transactionDate: ${_this.transactionDate}, id: ${_this.id}, type: ${_this.type}, fromAccountId: ${_this.fromAccountId}, fromAccountName: ${_this.fromAccountName}, toAccountId: ${_this.toAccountId}, toAccountName: ${_this.toAccountName}, status: ${_this.status}, payee: ${_this.payee}, categoryId: ${_this.categoryId}, categoryName: ${_this.categoryName}, memo: ${_this.memo}, tags: ${_this.tags}, number: ${_this.number}, paymentMethod: ${_this.paymentMethod}, assetId: ${_this.assetId}, assetName: ${_this.assetName}, units: ${_this.units}, sortOrder: ${_this.sortOrder}, splits: ${_this.splits})';
}


}

/// @nodoc
abstract mixin class $TransactionCopyWith<$Res>  {
  factory $TransactionCopyWith(Transaction value, $Res Function(Transaction) _then) = _$TransactionCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: jsonToDouble) double amount, DateTime transactionDate, int? id, String type, int? fromAccountId, String? fromAccountName, int? toAccountId, String? toAccountName, String? status, String? payee, int? categoryId, String? categoryName, String? memo, String? tags, String? number, String? paymentMethod, int? assetId, String? assetName,@JsonKey(fromJson: jsonToDoubleN) double? units, int sortOrder, List<TransactionSplit> splits
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
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? transactionDate = null,Object? id = freezed,Object? type = null,Object? fromAccountId = freezed,Object? fromAccountName = freezed,Object? toAccountId = freezed,Object? toAccountName = freezed,Object? status = freezed,Object? payee = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? memo = freezed,Object? tags = freezed,Object? number = freezed,Object? paymentMethod = freezed,Object? assetId = freezed,Object? assetName = freezed,Object? units = freezed,Object? sortOrder = null,Object? splits = null,}) {
  return _then(Transaction(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,fromAccountId: freezed == fromAccountId ? _self.fromAccountId : fromAccountId // ignore: cast_nullable_to_non_nullable
as int?,fromAccountName: freezed == fromAccountName ? _self.fromAccountName : fromAccountName // ignore: cast_nullable_to_non_nullable
as String?,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as int?,toAccountName: freezed == toAccountName ? _self.toAccountName : toAccountName // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: jsonToDouble)  double amount,  DateTime transactionDate,  int? id,  String type,  int? fromAccountId,  String? fromAccountName,  int? toAccountId,  String? toAccountName,  String? status,  String? payee,  int? categoryId,  String? categoryName,  String? memo,  String? tags,  String? number,  String? paymentMethod,  int? assetId,  String? assetName, @JsonKey(fromJson: jsonToDoubleN)  double? units,  int sortOrder,  List<TransactionSplit> splits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.amount,_that.transactionDate,_that.id,_that.type,_that.fromAccountId,_that.fromAccountName,_that.toAccountId,_that.toAccountName,_that.status,_that.payee,_that.categoryId,_that.categoryName,_that.memo,_that.tags,_that.number,_that.paymentMethod,_that.assetId,_that.assetName,_that.units,_that.sortOrder,_that.splits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: jsonToDouble)  double amount,  DateTime transactionDate,  int? id,  String type,  int? fromAccountId,  String? fromAccountName,  int? toAccountId,  String? toAccountName,  String? status,  String? payee,  int? categoryId,  String? categoryName,  String? memo,  String? tags,  String? number,  String? paymentMethod,  int? assetId,  String? assetName, @JsonKey(fromJson: jsonToDoubleN)  double? units,  int sortOrder,  List<TransactionSplit> splits)  $default,) {final _that = this;
switch (_that) {
case _Transaction():
return $default(_that.amount,_that.transactionDate,_that.id,_that.type,_that.fromAccountId,_that.fromAccountName,_that.toAccountId,_that.toAccountName,_that.status,_that.payee,_that.categoryId,_that.categoryName,_that.memo,_that.tags,_that.number,_that.paymentMethod,_that.assetId,_that.assetName,_that.units,_that.sortOrder,_that.splits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: jsonToDouble)  double amount,  DateTime transactionDate,  int? id,  String type,  int? fromAccountId,  String? fromAccountName,  int? toAccountId,  String? toAccountName,  String? status,  String? payee,  int? categoryId,  String? categoryName,  String? memo,  String? tags,  String? number,  String? paymentMethod,  int? assetId,  String? assetName, @JsonKey(fromJson: jsonToDoubleN)  double? units,  int sortOrder,  List<TransactionSplit> splits)?  $default,) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.amount,_that.transactionDate,_that.id,_that.type,_that.fromAccountId,_that.fromAccountName,_that.toAccountId,_that.toAccountName,_that.status,_that.payee,_that.categoryId,_that.categoryName,_that.memo,_that.tags,_that.number,_that.paymentMethod,_that.assetId,_that.assetName,_that.units,_that.sortOrder,_that.splits);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Transaction extends Transaction {
  const _Transaction({@JsonKey(fromJson: jsonToDouble) required this.amount, required this.transactionDate, this.id, this.type = 'EXPENSE', this.fromAccountId, this.fromAccountName, this.toAccountId, this.toAccountName, this.status, this.payee, this.categoryId, this.categoryName, this.memo, this.tags, this.number, this.paymentMethod, this.assetId, this.assetName, @JsonKey(fromJson: jsonToDoubleN) this.units, this.sortOrder = 0,  List<TransactionSplit> splits = const []}): _splits = splits,super._();
  factory _Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

@override@JsonKey(fromJson: jsonToDouble) final  double amount;
@override final  DateTime transactionDate;
@override final  int? id;
@override@JsonKey() final  String type;
@override final  int? fromAccountId;
@override final  String? fromAccountName;
@override final  int? toAccountId;
@override final  String? toAccountName;
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transaction&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.fromAccountId, fromAccountId) || other.fromAccountId == fromAccountId)&&(identical(other.fromAccountName, fromAccountName) || other.fromAccountName == fromAccountName)&&(identical(other.toAccountId, toAccountId) || other.toAccountId == toAccountId)&&(identical(other.toAccountName, toAccountName) || other.toAccountName == toAccountName)&&(identical(other.status, status) || other.status == status)&&(identical(other.payee, payee) || other.payee == payee)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.number, number) || other.number == number)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.units, units) || other.units == units)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other.splits, _splits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,amount,transactionDate,id,type,fromAccountId,fromAccountName,toAccountId,toAccountName,status,payee,categoryId,categoryName,memo,tags,number,paymentMethod,assetId,assetName,units,sortOrder,const DeepCollectionEquality().hash(_splits)]);
}

@override
String toString() {
    return 'Transaction(amount: $amount, transactionDate: $transactionDate, id: $id, type: $type, fromAccountId: $fromAccountId, fromAccountName: $fromAccountName, toAccountId: $toAccountId, toAccountName: $toAccountName, status: $status, payee: $payee, categoryId: $categoryId, categoryName: $categoryName, memo: $memo, tags: $tags, number: $number, paymentMethod: $paymentMethod, assetId: $assetId, assetName: $assetName, units: $units, sortOrder: $sortOrder, splits: $splits)';
}


}

/// @nodoc
abstract mixin class _$TransactionCopyWith<$Res> implements $TransactionCopyWith<$Res> {
  factory _$TransactionCopyWith(_Transaction value, $Res Function(_Transaction) _then) = __$TransactionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: jsonToDouble) double amount, DateTime transactionDate, int? id, String type, int? fromAccountId, String? fromAccountName, int? toAccountId, String? toAccountName, String? status, String? payee, int? categoryId, String? categoryName, String? memo, String? tags, String? number, String? paymentMethod, int? assetId, String? assetName,@JsonKey(fromJson: jsonToDoubleN) double? units, int sortOrder, List<TransactionSplit> splits
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
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? transactionDate = null,Object? id = freezed,Object? type = null,Object? fromAccountId = freezed,Object? fromAccountName = freezed,Object? toAccountId = freezed,Object? toAccountName = freezed,Object? status = freezed,Object? payee = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? memo = freezed,Object? tags = freezed,Object? number = freezed,Object? paymentMethod = freezed,Object? assetId = freezed,Object? assetName = freezed,Object? units = freezed,Object? sortOrder = null,Object? splits = null,}) {
  return _then(_Transaction(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,fromAccountId: freezed == fromAccountId ? _self.fromAccountId : fromAccountId // ignore: cast_nullable_to_non_nullable
as int?,fromAccountName: freezed == fromAccountName ? _self.fromAccountName : fromAccountName // ignore: cast_nullable_to_non_nullable
as String?,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as int?,toAccountName: freezed == toAccountName ? _self.toAccountName : toAccountName // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
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
