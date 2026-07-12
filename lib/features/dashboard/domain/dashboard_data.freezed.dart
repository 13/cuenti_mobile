// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DashboardData {

@JsonKey(fromJson: jsonToDouble) double get availableCash;@JsonKey(fromJson: jsonToDouble) double get portfolioValue;@JsonKey(fromJson: jsonToDouble) double get netWorth; String get defaultCurrency; List<Account> get accounts; List<AssetPerformance> get assetPerformance;
/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardDataCopyWith<DashboardData> get copyWith => _$DashboardDataCopyWithImpl<DashboardData>(this as DashboardData, _$identity);

  /// Serializes this DashboardData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardData&&(identical(other.availableCash, availableCash) || other.availableCash == availableCash)&&(identical(other.portfolioValue, portfolioValue) || other.portfolioValue == portfolioValue)&&(identical(other.netWorth, netWorth) || other.netWorth == netWorth)&&(identical(other.defaultCurrency, defaultCurrency) || other.defaultCurrency == defaultCurrency)&&const DeepCollectionEquality().equals(other.accounts, accounts)&&const DeepCollectionEquality().equals(other.assetPerformance, assetPerformance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,availableCash,portfolioValue,netWorth,defaultCurrency,const DeepCollectionEquality().hash(accounts),const DeepCollectionEquality().hash(assetPerformance));

@override
String toString() {
  return 'DashboardData(availableCash: $availableCash, portfolioValue: $portfolioValue, netWorth: $netWorth, defaultCurrency: $defaultCurrency, accounts: $accounts, assetPerformance: $assetPerformance)';
}


}

/// @nodoc
abstract mixin class $DashboardDataCopyWith<$Res>  {
  factory $DashboardDataCopyWith(DashboardData value, $Res Function(DashboardData) _then) = _$DashboardDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: jsonToDouble) double availableCash,@JsonKey(fromJson: jsonToDouble) double portfolioValue,@JsonKey(fromJson: jsonToDouble) double netWorth, String defaultCurrency, List<Account> accounts, List<AssetPerformance> assetPerformance
});




}
/// @nodoc
class _$DashboardDataCopyWithImpl<$Res>
    implements $DashboardDataCopyWith<$Res> {
  _$DashboardDataCopyWithImpl(this._self, this._then);

  final DashboardData _self;
  final $Res Function(DashboardData) _then;

/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? availableCash = null,Object? portfolioValue = null,Object? netWorth = null,Object? defaultCurrency = null,Object? accounts = null,Object? assetPerformance = null,}) {
  return _then(_self.copyWith(
availableCash: null == availableCash ? _self.availableCash : availableCash // ignore: cast_nullable_to_non_nullable
as double,portfolioValue: null == portfolioValue ? _self.portfolioValue : portfolioValue // ignore: cast_nullable_to_non_nullable
as double,netWorth: null == netWorth ? _self.netWorth : netWorth // ignore: cast_nullable_to_non_nullable
as double,defaultCurrency: null == defaultCurrency ? _self.defaultCurrency : defaultCurrency // ignore: cast_nullable_to_non_nullable
as String,accounts: null == accounts ? _self.accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<Account>,assetPerformance: null == assetPerformance ? _self.assetPerformance : assetPerformance // ignore: cast_nullable_to_non_nullable
as List<AssetPerformance>,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardData].
extension DashboardDataPatterns on DashboardData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardData value)  $default,){
final _that = this;
switch (_that) {
case _DashboardData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardData value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: jsonToDouble)  double availableCash, @JsonKey(fromJson: jsonToDouble)  double portfolioValue, @JsonKey(fromJson: jsonToDouble)  double netWorth,  String defaultCurrency,  List<Account> accounts,  List<AssetPerformance> assetPerformance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardData() when $default != null:
return $default(_that.availableCash,_that.portfolioValue,_that.netWorth,_that.defaultCurrency,_that.accounts,_that.assetPerformance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: jsonToDouble)  double availableCash, @JsonKey(fromJson: jsonToDouble)  double portfolioValue, @JsonKey(fromJson: jsonToDouble)  double netWorth,  String defaultCurrency,  List<Account> accounts,  List<AssetPerformance> assetPerformance)  $default,) {final _that = this;
switch (_that) {
case _DashboardData():
return $default(_that.availableCash,_that.portfolioValue,_that.netWorth,_that.defaultCurrency,_that.accounts,_that.assetPerformance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: jsonToDouble)  double availableCash, @JsonKey(fromJson: jsonToDouble)  double portfolioValue, @JsonKey(fromJson: jsonToDouble)  double netWorth,  String defaultCurrency,  List<Account> accounts,  List<AssetPerformance> assetPerformance)?  $default,) {final _that = this;
switch (_that) {
case _DashboardData() when $default != null:
return $default(_that.availableCash,_that.portfolioValue,_that.netWorth,_that.defaultCurrency,_that.accounts,_that.assetPerformance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardData extends DashboardData {
  const _DashboardData({@JsonKey(fromJson: jsonToDouble) required this.availableCash, @JsonKey(fromJson: jsonToDouble) required this.portfolioValue, @JsonKey(fromJson: jsonToDouble) required this.netWorth, this.defaultCurrency = 'EUR', final  List<Account> accounts = const [], final  List<AssetPerformance> assetPerformance = const []}): _accounts = accounts,_assetPerformance = assetPerformance,super._();
  factory _DashboardData.fromJson(Map<String, dynamic> json) => _$DashboardDataFromJson(json);

@override@JsonKey(fromJson: jsonToDouble) final  double availableCash;
@override@JsonKey(fromJson: jsonToDouble) final  double portfolioValue;
@override@JsonKey(fromJson: jsonToDouble) final  double netWorth;
@override@JsonKey() final  String defaultCurrency;
 final  List<Account> _accounts;
@override@JsonKey() List<Account> get accounts {
  if (_accounts is EqualUnmodifiableListView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accounts);
}

 final  List<AssetPerformance> _assetPerformance;
@override@JsonKey() List<AssetPerformance> get assetPerformance {
  if (_assetPerformance is EqualUnmodifiableListView) return _assetPerformance;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assetPerformance);
}


/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardDataCopyWith<_DashboardData> get copyWith => __$DashboardDataCopyWithImpl<_DashboardData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardData&&(identical(other.availableCash, availableCash) || other.availableCash == availableCash)&&(identical(other.portfolioValue, portfolioValue) || other.portfolioValue == portfolioValue)&&(identical(other.netWorth, netWorth) || other.netWorth == netWorth)&&(identical(other.defaultCurrency, defaultCurrency) || other.defaultCurrency == defaultCurrency)&&const DeepCollectionEquality().equals(other._accounts, _accounts)&&const DeepCollectionEquality().equals(other._assetPerformance, _assetPerformance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,availableCash,portfolioValue,netWorth,defaultCurrency,const DeepCollectionEquality().hash(_accounts),const DeepCollectionEquality().hash(_assetPerformance));

@override
String toString() {
  return 'DashboardData(availableCash: $availableCash, portfolioValue: $portfolioValue, netWorth: $netWorth, defaultCurrency: $defaultCurrency, accounts: $accounts, assetPerformance: $assetPerformance)';
}


}

/// @nodoc
abstract mixin class _$DashboardDataCopyWith<$Res> implements $DashboardDataCopyWith<$Res> {
  factory _$DashboardDataCopyWith(_DashboardData value, $Res Function(_DashboardData) _then) = __$DashboardDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: jsonToDouble) double availableCash,@JsonKey(fromJson: jsonToDouble) double portfolioValue,@JsonKey(fromJson: jsonToDouble) double netWorth, String defaultCurrency, List<Account> accounts, List<AssetPerformance> assetPerformance
});




}
/// @nodoc
class __$DashboardDataCopyWithImpl<$Res>
    implements _$DashboardDataCopyWith<$Res> {
  __$DashboardDataCopyWithImpl(this._self, this._then);

  final _DashboardData _self;
  final $Res Function(_DashboardData) _then;

/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? availableCash = null,Object? portfolioValue = null,Object? netWorth = null,Object? defaultCurrency = null,Object? accounts = null,Object? assetPerformance = null,}) {
  return _then(_DashboardData(
availableCash: null == availableCash ? _self.availableCash : availableCash // ignore: cast_nullable_to_non_nullable
as double,portfolioValue: null == portfolioValue ? _self.portfolioValue : portfolioValue // ignore: cast_nullable_to_non_nullable
as double,netWorth: null == netWorth ? _self.netWorth : netWorth // ignore: cast_nullable_to_non_nullable
as double,defaultCurrency: null == defaultCurrency ? _self.defaultCurrency : defaultCurrency // ignore: cast_nullable_to_non_nullable
as String,accounts: null == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<Account>,assetPerformance: null == assetPerformance ? _self._assetPerformance : assetPerformance // ignore: cast_nullable_to_non_nullable
as List<AssetPerformance>,
  ));
}


}

// dart format on
