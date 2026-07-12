// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forecast_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MonthForecast {

 String get month;@JsonKey(fromJson: jsonToDouble) double get income;@JsonKey(fromJson: jsonToDouble) double get expense;@JsonKey(fromJson: jsonToDouble) double get net;
/// Create a copy of MonthForecast
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthForecastCopyWith<MonthForecast> get copyWith => _$MonthForecastCopyWithImpl<MonthForecast>(this as MonthForecast, _$identity);

  /// Serializes this MonthForecast to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthForecast&&(identical(other.month, month) || other.month == month)&&(identical(other.income, income) || other.income == income)&&(identical(other.expense, expense) || other.expense == expense)&&(identical(other.net, net) || other.net == net));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,income,expense,net);

@override
String toString() {
  return 'MonthForecast(month: $month, income: $income, expense: $expense, net: $net)';
}


}

/// @nodoc
abstract mixin class $MonthForecastCopyWith<$Res>  {
  factory $MonthForecastCopyWith(MonthForecast value, $Res Function(MonthForecast) _then) = _$MonthForecastCopyWithImpl;
@useResult
$Res call({
 String month,@JsonKey(fromJson: jsonToDouble) double income,@JsonKey(fromJson: jsonToDouble) double expense,@JsonKey(fromJson: jsonToDouble) double net
});




}
/// @nodoc
class _$MonthForecastCopyWithImpl<$Res>
    implements $MonthForecastCopyWith<$Res> {
  _$MonthForecastCopyWithImpl(this._self, this._then);

  final MonthForecast _self;
  final $Res Function(MonthForecast) _then;

/// Create a copy of MonthForecast
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? income = null,Object? expense = null,Object? net = null,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,income: null == income ? _self.income : income // ignore: cast_nullable_to_non_nullable
as double,expense: null == expense ? _self.expense : expense // ignore: cast_nullable_to_non_nullable
as double,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthForecast].
extension MonthForecastPatterns on MonthForecast {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthForecast value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthForecast() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthForecast value)  $default,){
final _that = this;
switch (_that) {
case _MonthForecast():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthForecast value)?  $default,){
final _that = this;
switch (_that) {
case _MonthForecast() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String month, @JsonKey(fromJson: jsonToDouble)  double income, @JsonKey(fromJson: jsonToDouble)  double expense, @JsonKey(fromJson: jsonToDouble)  double net)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthForecast() when $default != null:
return $default(_that.month,_that.income,_that.expense,_that.net);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String month, @JsonKey(fromJson: jsonToDouble)  double income, @JsonKey(fromJson: jsonToDouble)  double expense, @JsonKey(fromJson: jsonToDouble)  double net)  $default,) {final _that = this;
switch (_that) {
case _MonthForecast():
return $default(_that.month,_that.income,_that.expense,_that.net);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String month, @JsonKey(fromJson: jsonToDouble)  double income, @JsonKey(fromJson: jsonToDouble)  double expense, @JsonKey(fromJson: jsonToDouble)  double net)?  $default,) {final _that = this;
switch (_that) {
case _MonthForecast() when $default != null:
return $default(_that.month,_that.income,_that.expense,_that.net);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthForecast implements MonthForecast {
  const _MonthForecast({required this.month, @JsonKey(fromJson: jsonToDouble) this.income = 0, @JsonKey(fromJson: jsonToDouble) this.expense = 0, @JsonKey(fromJson: jsonToDouble) this.net = 0});
  factory _MonthForecast.fromJson(Map<String, dynamic> json) => _$MonthForecastFromJson(json);

@override final  String month;
@override@JsonKey(fromJson: jsonToDouble) final  double income;
@override@JsonKey(fromJson: jsonToDouble) final  double expense;
@override@JsonKey(fromJson: jsonToDouble) final  double net;

/// Create a copy of MonthForecast
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthForecastCopyWith<_MonthForecast> get copyWith => __$MonthForecastCopyWithImpl<_MonthForecast>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthForecastToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthForecast&&(identical(other.month, month) || other.month == month)&&(identical(other.income, income) || other.income == income)&&(identical(other.expense, expense) || other.expense == expense)&&(identical(other.net, net) || other.net == net));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,income,expense,net);

@override
String toString() {
  return 'MonthForecast(month: $month, income: $income, expense: $expense, net: $net)';
}


}

/// @nodoc
abstract mixin class _$MonthForecastCopyWith<$Res> implements $MonthForecastCopyWith<$Res> {
  factory _$MonthForecastCopyWith(_MonthForecast value, $Res Function(_MonthForecast) _then) = __$MonthForecastCopyWithImpl;
@override @useResult
$Res call({
 String month,@JsonKey(fromJson: jsonToDouble) double income,@JsonKey(fromJson: jsonToDouble) double expense,@JsonKey(fromJson: jsonToDouble) double net
});




}
/// @nodoc
class __$MonthForecastCopyWithImpl<$Res>
    implements _$MonthForecastCopyWith<$Res> {
  __$MonthForecastCopyWithImpl(this._self, this._then);

  final _MonthForecast _self;
  final $Res Function(_MonthForecast) _then;

/// Create a copy of MonthForecast
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? income = null,Object? expense = null,Object? net = null,}) {
  return _then(_MonthForecast(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,income: null == income ? _self.income : income // ignore: cast_nullable_to_non_nullable
as double,expense: null == expense ? _self.expense : expense // ignore: cast_nullable_to_non_nullable
as double,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ForecastData {

 int get year; List<MonthForecast> get months;@JsonKey(fromJson: jsonToDouble) double get totalIncome;@JsonKey(fromJson: jsonToDouble) double get totalExpense;@JsonKey(fromJson: jsonToDouble) double get netForecast; String get currency;
/// Create a copy of ForecastData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForecastDataCopyWith<ForecastData> get copyWith => _$ForecastDataCopyWithImpl<ForecastData>(this as ForecastData, _$identity);

  /// Serializes this ForecastData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForecastData&&(identical(other.year, year) || other.year == year)&&const DeepCollectionEquality().equals(other.months, months)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.netForecast, netForecast) || other.netForecast == netForecast)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,const DeepCollectionEquality().hash(months),totalIncome,totalExpense,netForecast,currency);

@override
String toString() {
  return 'ForecastData(year: $year, months: $months, totalIncome: $totalIncome, totalExpense: $totalExpense, netForecast: $netForecast, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $ForecastDataCopyWith<$Res>  {
  factory $ForecastDataCopyWith(ForecastData value, $Res Function(ForecastData) _then) = _$ForecastDataCopyWithImpl;
@useResult
$Res call({
 int year, List<MonthForecast> months,@JsonKey(fromJson: jsonToDouble) double totalIncome,@JsonKey(fromJson: jsonToDouble) double totalExpense,@JsonKey(fromJson: jsonToDouble) double netForecast, String currency
});




}
/// @nodoc
class _$ForecastDataCopyWithImpl<$Res>
    implements $ForecastDataCopyWith<$Res> {
  _$ForecastDataCopyWithImpl(this._self, this._then);

  final ForecastData _self;
  final $Res Function(ForecastData) _then;

/// Create a copy of ForecastData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? year = null,Object? months = null,Object? totalIncome = null,Object? totalExpense = null,Object? netForecast = null,Object? currency = null,}) {
  return _then(_self.copyWith(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,months: null == months ? _self.months : months // ignore: cast_nullable_to_non_nullable
as List<MonthForecast>,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as double,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as double,netForecast: null == netForecast ? _self.netForecast : netForecast // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ForecastData].
extension ForecastDataPatterns on ForecastData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ForecastData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ForecastData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ForecastData value)  $default,){
final _that = this;
switch (_that) {
case _ForecastData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ForecastData value)?  $default,){
final _that = this;
switch (_that) {
case _ForecastData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int year,  List<MonthForecast> months, @JsonKey(fromJson: jsonToDouble)  double totalIncome, @JsonKey(fromJson: jsonToDouble)  double totalExpense, @JsonKey(fromJson: jsonToDouble)  double netForecast,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ForecastData() when $default != null:
return $default(_that.year,_that.months,_that.totalIncome,_that.totalExpense,_that.netForecast,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int year,  List<MonthForecast> months, @JsonKey(fromJson: jsonToDouble)  double totalIncome, @JsonKey(fromJson: jsonToDouble)  double totalExpense, @JsonKey(fromJson: jsonToDouble)  double netForecast,  String currency)  $default,) {final _that = this;
switch (_that) {
case _ForecastData():
return $default(_that.year,_that.months,_that.totalIncome,_that.totalExpense,_that.netForecast,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int year,  List<MonthForecast> months, @JsonKey(fromJson: jsonToDouble)  double totalIncome, @JsonKey(fromJson: jsonToDouble)  double totalExpense, @JsonKey(fromJson: jsonToDouble)  double netForecast,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _ForecastData() when $default != null:
return $default(_that.year,_that.months,_that.totalIncome,_that.totalExpense,_that.netForecast,_that.currency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ForecastData implements ForecastData {
  const _ForecastData({required this.year, final  List<MonthForecast> months = const [], @JsonKey(fromJson: jsonToDouble) this.totalIncome = 0, @JsonKey(fromJson: jsonToDouble) this.totalExpense = 0, @JsonKey(fromJson: jsonToDouble) this.netForecast = 0, this.currency = 'EUR'}): _months = months;
  factory _ForecastData.fromJson(Map<String, dynamic> json) => _$ForecastDataFromJson(json);

@override final  int year;
 final  List<MonthForecast> _months;
@override@JsonKey() List<MonthForecast> get months {
  if (_months is EqualUnmodifiableListView) return _months;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_months);
}

@override@JsonKey(fromJson: jsonToDouble) final  double totalIncome;
@override@JsonKey(fromJson: jsonToDouble) final  double totalExpense;
@override@JsonKey(fromJson: jsonToDouble) final  double netForecast;
@override@JsonKey() final  String currency;

/// Create a copy of ForecastData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ForecastDataCopyWith<_ForecastData> get copyWith => __$ForecastDataCopyWithImpl<_ForecastData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ForecastDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ForecastData&&(identical(other.year, year) || other.year == year)&&const DeepCollectionEquality().equals(other._months, _months)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.netForecast, netForecast) || other.netForecast == netForecast)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,const DeepCollectionEquality().hash(_months),totalIncome,totalExpense,netForecast,currency);

@override
String toString() {
  return 'ForecastData(year: $year, months: $months, totalIncome: $totalIncome, totalExpense: $totalExpense, netForecast: $netForecast, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$ForecastDataCopyWith<$Res> implements $ForecastDataCopyWith<$Res> {
  factory _$ForecastDataCopyWith(_ForecastData value, $Res Function(_ForecastData) _then) = __$ForecastDataCopyWithImpl;
@override @useResult
$Res call({
 int year, List<MonthForecast> months,@JsonKey(fromJson: jsonToDouble) double totalIncome,@JsonKey(fromJson: jsonToDouble) double totalExpense,@JsonKey(fromJson: jsonToDouble) double netForecast, String currency
});




}
/// @nodoc
class __$ForecastDataCopyWithImpl<$Res>
    implements _$ForecastDataCopyWith<$Res> {
  __$ForecastDataCopyWithImpl(this._self, this._then);

  final _ForecastData _self;
  final $Res Function(_ForecastData) _then;

/// Create a copy of ForecastData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? year = null,Object? months = null,Object? totalIncome = null,Object? totalExpense = null,Object? netForecast = null,Object? currency = null,}) {
  return _then(_ForecastData(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,months: null == months ? _self._months : months // ignore: cast_nullable_to_non_nullable
as List<MonthForecast>,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as double,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as double,netForecast: null == netForecast ? _self.netForecast : netForecast // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
