// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Account {

 int? get id; String get accountName; String? get accountNumber; String get accountType; String? get accountGroup; String? get institution; String get currency; double get startBalance; double get balance; int get sortOrder; bool get excludeFromSummary; bool get excludeFromReports;
/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountCopyWith<Account> get copyWith => _$AccountCopyWithImpl<Account>(this as Account, _$identity);

  /// Serializes this Account to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Account&&(identical(other.id, id) || other.id == id)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.accountGroup, accountGroup) || other.accountGroup == accountGroup)&&(identical(other.institution, institution) || other.institution == institution)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.startBalance, startBalance) || other.startBalance == startBalance)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.excludeFromSummary, excludeFromSummary) || other.excludeFromSummary == excludeFromSummary)&&(identical(other.excludeFromReports, excludeFromReports) || other.excludeFromReports == excludeFromReports));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,accountName,accountNumber,accountType,accountGroup,institution,currency,startBalance,balance,sortOrder,excludeFromSummary,excludeFromReports);

@override
String toString() {
  return 'Account(id: $id, accountName: $accountName, accountNumber: $accountNumber, accountType: $accountType, accountGroup: $accountGroup, institution: $institution, currency: $currency, startBalance: $startBalance, balance: $balance, sortOrder: $sortOrder, excludeFromSummary: $excludeFromSummary, excludeFromReports: $excludeFromReports)';
}


}

/// @nodoc
abstract mixin class $AccountCopyWith<$Res>  {
  factory $AccountCopyWith(Account value, $Res Function(Account) _then) = _$AccountCopyWithImpl;
@useResult
$Res call({
 int? id, String accountName, String? accountNumber, String accountType, String? accountGroup, String? institution, String currency, double startBalance, double balance, int sortOrder, bool excludeFromSummary, bool excludeFromReports
});




}
/// @nodoc
class _$AccountCopyWithImpl<$Res>
    implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._self, this._then);

  final Account _self;
  final $Res Function(Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? accountName = null,Object? accountNumber = freezed,Object? accountType = null,Object? accountGroup = freezed,Object? institution = freezed,Object? currency = null,Object? startBalance = null,Object? balance = null,Object? sortOrder = null,Object? excludeFromSummary = null,Object? excludeFromReports = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,accountNumber: freezed == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String?,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,accountGroup: freezed == accountGroup ? _self.accountGroup : accountGroup // ignore: cast_nullable_to_non_nullable
as String?,institution: freezed == institution ? _self.institution : institution // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,startBalance: null == startBalance ? _self.startBalance : startBalance // ignore: cast_nullable_to_non_nullable
as double,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,excludeFromSummary: null == excludeFromSummary ? _self.excludeFromSummary : excludeFromSummary // ignore: cast_nullable_to_non_nullable
as bool,excludeFromReports: null == excludeFromReports ? _self.excludeFromReports : excludeFromReports // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Account].
extension AccountPatterns on Account {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Account value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Account value)  $default,){
final _that = this;
switch (_that) {
case _Account():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Account value)?  $default,){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String accountName,  String? accountNumber,  String accountType,  String? accountGroup,  String? institution,  String currency,  double startBalance,  double balance,  int sortOrder,  bool excludeFromSummary,  bool excludeFromReports)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.accountName,_that.accountNumber,_that.accountType,_that.accountGroup,_that.institution,_that.currency,_that.startBalance,_that.balance,_that.sortOrder,_that.excludeFromSummary,_that.excludeFromReports);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String accountName,  String? accountNumber,  String accountType,  String? accountGroup,  String? institution,  String currency,  double startBalance,  double balance,  int sortOrder,  bool excludeFromSummary,  bool excludeFromReports)  $default,) {final _that = this;
switch (_that) {
case _Account():
return $default(_that.id,_that.accountName,_that.accountNumber,_that.accountType,_that.accountGroup,_that.institution,_that.currency,_that.startBalance,_that.balance,_that.sortOrder,_that.excludeFromSummary,_that.excludeFromReports);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String accountName,  String? accountNumber,  String accountType,  String? accountGroup,  String? institution,  String currency,  double startBalance,  double balance,  int sortOrder,  bool excludeFromSummary,  bool excludeFromReports)?  $default,) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.accountName,_that.accountNumber,_that.accountType,_that.accountGroup,_that.institution,_that.currency,_that.startBalance,_that.balance,_that.sortOrder,_that.excludeFromSummary,_that.excludeFromReports);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Account extends Account {
  const _Account({this.id, this.accountName = '', this.accountNumber, this.accountType = 'BANK', this.accountGroup, this.institution, this.currency = 'EUR', this.startBalance = 0, this.balance = 0, this.sortOrder = 0, this.excludeFromSummary = false, this.excludeFromReports = false}): super._();
  factory _Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);

@override final  int? id;
@override@JsonKey() final  String accountName;
@override final  String? accountNumber;
@override@JsonKey() final  String accountType;
@override final  String? accountGroup;
@override final  String? institution;
@override@JsonKey() final  String currency;
@override@JsonKey() final  double startBalance;
@override@JsonKey() final  double balance;
@override@JsonKey() final  int sortOrder;
@override@JsonKey() final  bool excludeFromSummary;
@override@JsonKey() final  bool excludeFromReports;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountCopyWith<_Account> get copyWith => __$AccountCopyWithImpl<_Account>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Account&&(identical(other.id, id) || other.id == id)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.accountGroup, accountGroup) || other.accountGroup == accountGroup)&&(identical(other.institution, institution) || other.institution == institution)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.startBalance, startBalance) || other.startBalance == startBalance)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.excludeFromSummary, excludeFromSummary) || other.excludeFromSummary == excludeFromSummary)&&(identical(other.excludeFromReports, excludeFromReports) || other.excludeFromReports == excludeFromReports));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,accountName,accountNumber,accountType,accountGroup,institution,currency,startBalance,balance,sortOrder,excludeFromSummary,excludeFromReports);

@override
String toString() {
  return 'Account(id: $id, accountName: $accountName, accountNumber: $accountNumber, accountType: $accountType, accountGroup: $accountGroup, institution: $institution, currency: $currency, startBalance: $startBalance, balance: $balance, sortOrder: $sortOrder, excludeFromSummary: $excludeFromSummary, excludeFromReports: $excludeFromReports)';
}


}

/// @nodoc
abstract mixin class _$AccountCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$AccountCopyWith(_Account value, $Res Function(_Account) _then) = __$AccountCopyWithImpl;
@override @useResult
$Res call({
 int? id, String accountName, String? accountNumber, String accountType, String? accountGroup, String? institution, String currency, double startBalance, double balance, int sortOrder, bool excludeFromSummary, bool excludeFromReports
});




}
/// @nodoc
class __$AccountCopyWithImpl<$Res>
    implements _$AccountCopyWith<$Res> {
  __$AccountCopyWithImpl(this._self, this._then);

  final _Account _self;
  final $Res Function(_Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? accountName = null,Object? accountNumber = freezed,Object? accountType = null,Object? accountGroup = freezed,Object? institution = freezed,Object? currency = null,Object? startBalance = null,Object? balance = null,Object? sortOrder = null,Object? excludeFromSummary = null,Object? excludeFromReports = null,}) {
  return _then(_Account(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,accountNumber: freezed == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String?,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,accountGroup: freezed == accountGroup ? _self.accountGroup : accountGroup // ignore: cast_nullable_to_non_nullable
as String?,institution: freezed == institution ? _self.institution : institution // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,startBalance: null == startBalance ? _self.startBalance : startBalance // ignore: cast_nullable_to_non_nullable
as double,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,excludeFromSummary: null == excludeFromSummary ? _self.excludeFromSummary : excludeFromSummary // ignore: cast_nullable_to_non_nullable
as bool,excludeFromReports: null == excludeFromReports ? _self.excludeFromReports : excludeFromReports // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
