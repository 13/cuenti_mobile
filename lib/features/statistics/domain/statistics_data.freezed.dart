// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'statistics_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatisticsData {

@JsonKey(fromJson: jsonToDouble) double get totalIncome;@JsonKey(fromJson: jsonToDouble) double get totalExpense;@JsonKey(fromJson: jsonToDouble) double get balance; String get currency;@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> get incomeByCategory;@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> get expenseByCategory;@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> get monthlyIncome;@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> get monthlyExpense; int get transactionCount;
/// Create a copy of StatisticsData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatisticsDataCopyWith<StatisticsData> get copyWith => _$StatisticsDataCopyWithImpl<StatisticsData>(this as StatisticsData, _$identity);

  /// Serializes this StatisticsData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatisticsData&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.incomeByCategory, incomeByCategory)&&const DeepCollectionEquality().equals(other.expenseByCategory, expenseByCategory)&&const DeepCollectionEquality().equals(other.monthlyIncome, monthlyIncome)&&const DeepCollectionEquality().equals(other.monthlyExpense, monthlyExpense)&&(identical(other.transactionCount, transactionCount) || other.transactionCount == transactionCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalIncome,totalExpense,balance,currency,const DeepCollectionEquality().hash(incomeByCategory),const DeepCollectionEquality().hash(expenseByCategory),const DeepCollectionEquality().hash(monthlyIncome),const DeepCollectionEquality().hash(monthlyExpense),transactionCount);

@override
String toString() {
  return 'StatisticsData(totalIncome: $totalIncome, totalExpense: $totalExpense, balance: $balance, currency: $currency, incomeByCategory: $incomeByCategory, expenseByCategory: $expenseByCategory, monthlyIncome: $monthlyIncome, monthlyExpense: $monthlyExpense, transactionCount: $transactionCount)';
}


}

/// @nodoc
abstract mixin class $StatisticsDataCopyWith<$Res>  {
  factory $StatisticsDataCopyWith(StatisticsData value, $Res Function(StatisticsData) _then) = _$StatisticsDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: jsonToDouble) double totalIncome,@JsonKey(fromJson: jsonToDouble) double totalExpense,@JsonKey(fromJson: jsonToDouble) double balance, String currency,@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> incomeByCategory,@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> expenseByCategory,@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> monthlyIncome,@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> monthlyExpense, int transactionCount
});




}
/// @nodoc
class _$StatisticsDataCopyWithImpl<$Res>
    implements $StatisticsDataCopyWith<$Res> {
  _$StatisticsDataCopyWithImpl(this._self, this._then);

  final StatisticsData _self;
  final $Res Function(StatisticsData) _then;

/// Create a copy of StatisticsData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalIncome = null,Object? totalExpense = null,Object? balance = null,Object? currency = null,Object? incomeByCategory = null,Object? expenseByCategory = null,Object? monthlyIncome = null,Object? monthlyExpense = null,Object? transactionCount = null,}) {
  return _then(_self.copyWith(
totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as double,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as double,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,incomeByCategory: null == incomeByCategory ? _self.incomeByCategory : incomeByCategory // ignore: cast_nullable_to_non_nullable
as Map<String, double>,expenseByCategory: null == expenseByCategory ? _self.expenseByCategory : expenseByCategory // ignore: cast_nullable_to_non_nullable
as Map<String, double>,monthlyIncome: null == monthlyIncome ? _self.monthlyIncome : monthlyIncome // ignore: cast_nullable_to_non_nullable
as Map<String, double>,monthlyExpense: null == monthlyExpense ? _self.monthlyExpense : monthlyExpense // ignore: cast_nullable_to_non_nullable
as Map<String, double>,transactionCount: null == transactionCount ? _self.transactionCount : transactionCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StatisticsData].
extension StatisticsDataPatterns on StatisticsData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatisticsData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatisticsData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatisticsData value)  $default,){
final _that = this;
switch (_that) {
case _StatisticsData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatisticsData value)?  $default,){
final _that = this;
switch (_that) {
case _StatisticsData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: jsonToDouble)  double totalIncome, @JsonKey(fromJson: jsonToDouble)  double totalExpense, @JsonKey(fromJson: jsonToDouble)  double balance,  String currency, @JsonKey(fromJson: jsonToDoubleMap)  Map<String, double> incomeByCategory, @JsonKey(fromJson: jsonToDoubleMap)  Map<String, double> expenseByCategory, @JsonKey(fromJson: jsonToDoubleMap)  Map<String, double> monthlyIncome, @JsonKey(fromJson: jsonToDoubleMap)  Map<String, double> monthlyExpense,  int transactionCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatisticsData() when $default != null:
return $default(_that.totalIncome,_that.totalExpense,_that.balance,_that.currency,_that.incomeByCategory,_that.expenseByCategory,_that.monthlyIncome,_that.monthlyExpense,_that.transactionCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: jsonToDouble)  double totalIncome, @JsonKey(fromJson: jsonToDouble)  double totalExpense, @JsonKey(fromJson: jsonToDouble)  double balance,  String currency, @JsonKey(fromJson: jsonToDoubleMap)  Map<String, double> incomeByCategory, @JsonKey(fromJson: jsonToDoubleMap)  Map<String, double> expenseByCategory, @JsonKey(fromJson: jsonToDoubleMap)  Map<String, double> monthlyIncome, @JsonKey(fromJson: jsonToDoubleMap)  Map<String, double> monthlyExpense,  int transactionCount)  $default,) {final _that = this;
switch (_that) {
case _StatisticsData():
return $default(_that.totalIncome,_that.totalExpense,_that.balance,_that.currency,_that.incomeByCategory,_that.expenseByCategory,_that.monthlyIncome,_that.monthlyExpense,_that.transactionCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: jsonToDouble)  double totalIncome, @JsonKey(fromJson: jsonToDouble)  double totalExpense, @JsonKey(fromJson: jsonToDouble)  double balance,  String currency, @JsonKey(fromJson: jsonToDoubleMap)  Map<String, double> incomeByCategory, @JsonKey(fromJson: jsonToDoubleMap)  Map<String, double> expenseByCategory, @JsonKey(fromJson: jsonToDoubleMap)  Map<String, double> monthlyIncome, @JsonKey(fromJson: jsonToDoubleMap)  Map<String, double> monthlyExpense,  int transactionCount)?  $default,) {final _that = this;
switch (_that) {
case _StatisticsData() when $default != null:
return $default(_that.totalIncome,_that.totalExpense,_that.balance,_that.currency,_that.incomeByCategory,_that.expenseByCategory,_that.monthlyIncome,_that.monthlyExpense,_that.transactionCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatisticsData extends StatisticsData {
  const _StatisticsData({@JsonKey(fromJson: jsonToDouble) required this.totalIncome, @JsonKey(fromJson: jsonToDouble) required this.totalExpense, @JsonKey(fromJson: jsonToDouble) required this.balance, this.currency = 'EUR', @JsonKey(fromJson: jsonToDoubleMap) final  Map<String, double> incomeByCategory = const {}, @JsonKey(fromJson: jsonToDoubleMap) final  Map<String, double> expenseByCategory = const {}, @JsonKey(fromJson: jsonToDoubleMap) final  Map<String, double> monthlyIncome = const {}, @JsonKey(fromJson: jsonToDoubleMap) final  Map<String, double> monthlyExpense = const {}, this.transactionCount = 0}): _incomeByCategory = incomeByCategory,_expenseByCategory = expenseByCategory,_monthlyIncome = monthlyIncome,_monthlyExpense = monthlyExpense,super._();
  factory _StatisticsData.fromJson(Map<String, dynamic> json) => _$StatisticsDataFromJson(json);

@override@JsonKey(fromJson: jsonToDouble) final  double totalIncome;
@override@JsonKey(fromJson: jsonToDouble) final  double totalExpense;
@override@JsonKey(fromJson: jsonToDouble) final  double balance;
@override@JsonKey() final  String currency;
 final  Map<String, double> _incomeByCategory;
@override@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> get incomeByCategory {
  if (_incomeByCategory is EqualUnmodifiableMapView) return _incomeByCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_incomeByCategory);
}

 final  Map<String, double> _expenseByCategory;
@override@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> get expenseByCategory {
  if (_expenseByCategory is EqualUnmodifiableMapView) return _expenseByCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_expenseByCategory);
}

 final  Map<String, double> _monthlyIncome;
@override@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> get monthlyIncome {
  if (_monthlyIncome is EqualUnmodifiableMapView) return _monthlyIncome;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_monthlyIncome);
}

 final  Map<String, double> _monthlyExpense;
@override@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> get monthlyExpense {
  if (_monthlyExpense is EqualUnmodifiableMapView) return _monthlyExpense;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_monthlyExpense);
}

@override@JsonKey() final  int transactionCount;

/// Create a copy of StatisticsData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatisticsDataCopyWith<_StatisticsData> get copyWith => __$StatisticsDataCopyWithImpl<_StatisticsData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatisticsDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatisticsData&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other._incomeByCategory, _incomeByCategory)&&const DeepCollectionEquality().equals(other._expenseByCategory, _expenseByCategory)&&const DeepCollectionEquality().equals(other._monthlyIncome, _monthlyIncome)&&const DeepCollectionEquality().equals(other._monthlyExpense, _monthlyExpense)&&(identical(other.transactionCount, transactionCount) || other.transactionCount == transactionCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalIncome,totalExpense,balance,currency,const DeepCollectionEquality().hash(_incomeByCategory),const DeepCollectionEquality().hash(_expenseByCategory),const DeepCollectionEquality().hash(_monthlyIncome),const DeepCollectionEquality().hash(_monthlyExpense),transactionCount);

@override
String toString() {
  return 'StatisticsData(totalIncome: $totalIncome, totalExpense: $totalExpense, balance: $balance, currency: $currency, incomeByCategory: $incomeByCategory, expenseByCategory: $expenseByCategory, monthlyIncome: $monthlyIncome, monthlyExpense: $monthlyExpense, transactionCount: $transactionCount)';
}


}

/// @nodoc
abstract mixin class _$StatisticsDataCopyWith<$Res> implements $StatisticsDataCopyWith<$Res> {
  factory _$StatisticsDataCopyWith(_StatisticsData value, $Res Function(_StatisticsData) _then) = __$StatisticsDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: jsonToDouble) double totalIncome,@JsonKey(fromJson: jsonToDouble) double totalExpense,@JsonKey(fromJson: jsonToDouble) double balance, String currency,@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> incomeByCategory,@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> expenseByCategory,@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> monthlyIncome,@JsonKey(fromJson: jsonToDoubleMap) Map<String, double> monthlyExpense, int transactionCount
});




}
/// @nodoc
class __$StatisticsDataCopyWithImpl<$Res>
    implements _$StatisticsDataCopyWith<$Res> {
  __$StatisticsDataCopyWithImpl(this._self, this._then);

  final _StatisticsData _self;
  final $Res Function(_StatisticsData) _then;

/// Create a copy of StatisticsData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalIncome = null,Object? totalExpense = null,Object? balance = null,Object? currency = null,Object? incomeByCategory = null,Object? expenseByCategory = null,Object? monthlyIncome = null,Object? monthlyExpense = null,Object? transactionCount = null,}) {
  return _then(_StatisticsData(
totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as double,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as double,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,incomeByCategory: null == incomeByCategory ? _self._incomeByCategory : incomeByCategory // ignore: cast_nullable_to_non_nullable
as Map<String, double>,expenseByCategory: null == expenseByCategory ? _self._expenseByCategory : expenseByCategory // ignore: cast_nullable_to_non_nullable
as Map<String, double>,monthlyIncome: null == monthlyIncome ? _self._monthlyIncome : monthlyIncome // ignore: cast_nullable_to_non_nullable
as Map<String, double>,monthlyExpense: null == monthlyExpense ? _self._monthlyExpense : monthlyExpense // ignore: cast_nullable_to_non_nullable
as Map<String, double>,transactionCount: null == transactionCount ? _self.transactionCount : transactionCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
