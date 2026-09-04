// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingTransaction {

 String get localId; PendingOperation get operation;@JsonKey(toJson: _transactionToJson, fromJson: _transactionFromJson) Transaction get transaction; DateTime get queuedAt;/// The server's own words, once it has refused this entry. Null while
/// the entry is merely waiting.
 String? get rejection;
/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingTransactionCopyWith<PendingTransaction> get copyWith => _$PendingTransactionCopyWithImpl<PendingTransaction>(this as PendingTransaction, _$identity);

  /// Serializes this PendingTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PendingTransaction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingTransaction&&(identical(other.localId, _this.localId) || other.localId == _this.localId)&&(identical(other.operation, _this.operation) || other.operation == _this.operation)&&(identical(other.transaction, _this.transaction) || other.transaction == _this.transaction)&&(identical(other.queuedAt, _this.queuedAt) || other.queuedAt == _this.queuedAt)&&(identical(other.rejection, _this.rejection) || other.rejection == _this.rejection));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PendingTransaction;
  return Object.hash(runtimeType,_this.localId,_this.operation,_this.transaction,_this.queuedAt,_this.rejection);
}

@override
String toString() {
  final _this = this as PendingTransaction;
  return 'PendingTransaction(localId: ${_this.localId}, operation: ${_this.operation}, transaction: ${_this.transaction}, queuedAt: ${_this.queuedAt}, rejection: ${_this.rejection})';
}


}

/// @nodoc
abstract mixin class $PendingTransactionCopyWith<$Res>  {
  factory $PendingTransactionCopyWith(PendingTransaction value, $Res Function(PendingTransaction) _then) = _$PendingTransactionCopyWithImpl;
@useResult
$Res call({
 String localId, PendingOperation operation,@JsonKey(toJson: _transactionToJson, fromJson: _transactionFromJson) Transaction transaction, DateTime queuedAt, String? rejection
});


$TransactionCopyWith<$Res> get transaction;

}
/// @nodoc
class _$PendingTransactionCopyWithImpl<$Res>
    implements $PendingTransactionCopyWith<$Res> {
  _$PendingTransactionCopyWithImpl(this._self, this._then);

  final PendingTransaction _self;
  final $Res Function(PendingTransaction) _then;

/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? localId = null,Object? operation = null,Object? transaction = null,Object? queuedAt = null,Object? rejection = freezed,}) {
  return _then(PendingTransaction(
localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as PendingOperation,transaction: null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as Transaction,queuedAt: null == queuedAt ? _self.queuedAt : queuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,rejection: freezed == rejection ? _self.rejection : rejection // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionCopyWith<$Res> get transaction {
  
  return $TransactionCopyWith<$Res>(_self.transaction, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}
}


/// Adds pattern-matching-related methods to [PendingTransaction].
extension PendingTransactionPatterns on PendingTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingTransaction value)  $default,){
final _that = this;
switch (_that) {
case _PendingTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _PendingTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String localId,  PendingOperation operation, @JsonKey(toJson: _transactionToJson, fromJson: _transactionFromJson)  Transaction transaction,  DateTime queuedAt,  String? rejection)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingTransaction() when $default != null:
return $default(_that.localId,_that.operation,_that.transaction,_that.queuedAt,_that.rejection);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String localId,  PendingOperation operation, @JsonKey(toJson: _transactionToJson, fromJson: _transactionFromJson)  Transaction transaction,  DateTime queuedAt,  String? rejection)  $default,) {final _that = this;
switch (_that) {
case _PendingTransaction():
return $default(_that.localId,_that.operation,_that.transaction,_that.queuedAt,_that.rejection);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String localId,  PendingOperation operation, @JsonKey(toJson: _transactionToJson, fromJson: _transactionFromJson)  Transaction transaction,  DateTime queuedAt,  String? rejection)?  $default,) {final _that = this;
switch (_that) {
case _PendingTransaction() when $default != null:
return $default(_that.localId,_that.operation,_that.transaction,_that.queuedAt,_that.rejection);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingTransaction extends PendingTransaction {
  const _PendingTransaction({required this.localId, required this.operation, @JsonKey(toJson: _transactionToJson, fromJson: _transactionFromJson) required this.transaction, required this.queuedAt, this.rejection}): super._();
  factory _PendingTransaction.fromJson(Map<String, dynamic> json) => _$PendingTransactionFromJson(json);

@override final  String localId;
@override final  PendingOperation operation;
@override@JsonKey(toJson: _transactionToJson, fromJson: _transactionFromJson) final  Transaction transaction;
@override final  DateTime queuedAt;
/// The server's own words, once it has refused this entry. Null while
/// the entry is merely waiting.
@override final  String? rejection;

/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingTransactionCopyWith<_PendingTransaction> get copyWith => __$PendingTransactionCopyWithImpl<_PendingTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingTransaction&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.transaction, transaction) || other.transaction == transaction)&&(identical(other.queuedAt, queuedAt) || other.queuedAt == queuedAt)&&(identical(other.rejection, rejection) || other.rejection == rejection));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,localId,operation,transaction,queuedAt,rejection);
}

@override
String toString() {
    return 'PendingTransaction(localId: $localId, operation: $operation, transaction: $transaction, queuedAt: $queuedAt, rejection: $rejection)';
}


}

/// @nodoc
abstract mixin class _$PendingTransactionCopyWith<$Res> implements $PendingTransactionCopyWith<$Res> {
  factory _$PendingTransactionCopyWith(_PendingTransaction value, $Res Function(_PendingTransaction) _then) = __$PendingTransactionCopyWithImpl;
@override @useResult
$Res call({
 String localId, PendingOperation operation,@JsonKey(toJson: _transactionToJson, fromJson: _transactionFromJson) Transaction transaction, DateTime queuedAt, String? rejection
});


@override $TransactionCopyWith<$Res> get transaction;

}
/// @nodoc
class __$PendingTransactionCopyWithImpl<$Res>
    implements _$PendingTransactionCopyWith<$Res> {
  __$PendingTransactionCopyWithImpl(this._self, this._then);

  final _PendingTransaction _self;
  final $Res Function(_PendingTransaction) _then;

/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? localId = null,Object? operation = null,Object? transaction = null,Object? queuedAt = null,Object? rejection = freezed,}) {
  return _then(_PendingTransaction(
localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as PendingOperation,transaction: null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as Transaction,queuedAt: null == queuedAt ? _self.queuedAt : queuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,rejection: freezed == rejection ? _self.rejection : rejection // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionCopyWith<$Res> get transaction {
  
  return $TransactionCopyWith<$Res>(_self.transaction, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}
}

// dart format on
