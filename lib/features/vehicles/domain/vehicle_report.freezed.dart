// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FuelEntry {

 DateTime get date;@JsonKey(fromJson: jsonToDoubleN) double? get odometer;@JsonKey(fromJson: jsonToDoubleN) double? get liters;@JsonKey(fromJson: jsonToDoubleN) double? get amount; String? get currency; String? get station; String? get memo; bool get fullTank;@JsonKey(fromJson: jsonToDoubleN) double? get distance;@JsonKey(fromJson: jsonToDoubleN) double? get pricePerLiter;@JsonKey(fromJson: jsonToDoubleN) double? get consumption;
/// Create a copy of FuelEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FuelEntryCopyWith<FuelEntry> get copyWith => _$FuelEntryCopyWithImpl<FuelEntry>(this as FuelEntry, _$identity);

  /// Serializes this FuelEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FuelEntry&&(identical(other.date, date) || other.date == date)&&(identical(other.odometer, odometer) || other.odometer == odometer)&&(identical(other.liters, liters) || other.liters == liters)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.station, station) || other.station == station)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.fullTank, fullTank) || other.fullTank == fullTank)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.pricePerLiter, pricePerLiter) || other.pricePerLiter == pricePerLiter)&&(identical(other.consumption, consumption) || other.consumption == consumption));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,odometer,liters,amount,currency,station,memo,fullTank,distance,pricePerLiter,consumption);

@override
String toString() {
  return 'FuelEntry(date: $date, odometer: $odometer, liters: $liters, amount: $amount, currency: $currency, station: $station, memo: $memo, fullTank: $fullTank, distance: $distance, pricePerLiter: $pricePerLiter, consumption: $consumption)';
}


}

/// @nodoc
abstract mixin class $FuelEntryCopyWith<$Res>  {
  factory $FuelEntryCopyWith(FuelEntry value, $Res Function(FuelEntry) _then) = _$FuelEntryCopyWithImpl;
@useResult
$Res call({
 DateTime date,@JsonKey(fromJson: jsonToDoubleN) double? odometer,@JsonKey(fromJson: jsonToDoubleN) double? liters,@JsonKey(fromJson: jsonToDoubleN) double? amount, String? currency, String? station, String? memo, bool fullTank,@JsonKey(fromJson: jsonToDoubleN) double? distance,@JsonKey(fromJson: jsonToDoubleN) double? pricePerLiter,@JsonKey(fromJson: jsonToDoubleN) double? consumption
});




}
/// @nodoc
class _$FuelEntryCopyWithImpl<$Res>
    implements $FuelEntryCopyWith<$Res> {
  _$FuelEntryCopyWithImpl(this._self, this._then);

  final FuelEntry _self;
  final $Res Function(FuelEntry) _then;

/// Create a copy of FuelEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? odometer = freezed,Object? liters = freezed,Object? amount = freezed,Object? currency = freezed,Object? station = freezed,Object? memo = freezed,Object? fullTank = null,Object? distance = freezed,Object? pricePerLiter = freezed,Object? consumption = freezed,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,odometer: freezed == odometer ? _self.odometer : odometer // ignore: cast_nullable_to_non_nullable
as double?,liters: freezed == liters ? _self.liters : liters // ignore: cast_nullable_to_non_nullable
as double?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,station: freezed == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as String?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,fullTank: null == fullTank ? _self.fullTank : fullTank // ignore: cast_nullable_to_non_nullable
as bool,distance: freezed == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double?,pricePerLiter: freezed == pricePerLiter ? _self.pricePerLiter : pricePerLiter // ignore: cast_nullable_to_non_nullable
as double?,consumption: freezed == consumption ? _self.consumption : consumption // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [FuelEntry].
extension FuelEntryPatterns on FuelEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FuelEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FuelEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FuelEntry value)  $default,){
final _that = this;
switch (_that) {
case _FuelEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FuelEntry value)?  $default,){
final _that = this;
switch (_that) {
case _FuelEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date, @JsonKey(fromJson: jsonToDoubleN)  double? odometer, @JsonKey(fromJson: jsonToDoubleN)  double? liters, @JsonKey(fromJson: jsonToDoubleN)  double? amount,  String? currency,  String? station,  String? memo,  bool fullTank, @JsonKey(fromJson: jsonToDoubleN)  double? distance, @JsonKey(fromJson: jsonToDoubleN)  double? pricePerLiter, @JsonKey(fromJson: jsonToDoubleN)  double? consumption)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FuelEntry() when $default != null:
return $default(_that.date,_that.odometer,_that.liters,_that.amount,_that.currency,_that.station,_that.memo,_that.fullTank,_that.distance,_that.pricePerLiter,_that.consumption);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date, @JsonKey(fromJson: jsonToDoubleN)  double? odometer, @JsonKey(fromJson: jsonToDoubleN)  double? liters, @JsonKey(fromJson: jsonToDoubleN)  double? amount,  String? currency,  String? station,  String? memo,  bool fullTank, @JsonKey(fromJson: jsonToDoubleN)  double? distance, @JsonKey(fromJson: jsonToDoubleN)  double? pricePerLiter, @JsonKey(fromJson: jsonToDoubleN)  double? consumption)  $default,) {final _that = this;
switch (_that) {
case _FuelEntry():
return $default(_that.date,_that.odometer,_that.liters,_that.amount,_that.currency,_that.station,_that.memo,_that.fullTank,_that.distance,_that.pricePerLiter,_that.consumption);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date, @JsonKey(fromJson: jsonToDoubleN)  double? odometer, @JsonKey(fromJson: jsonToDoubleN)  double? liters, @JsonKey(fromJson: jsonToDoubleN)  double? amount,  String? currency,  String? station,  String? memo,  bool fullTank, @JsonKey(fromJson: jsonToDoubleN)  double? distance, @JsonKey(fromJson: jsonToDoubleN)  double? pricePerLiter, @JsonKey(fromJson: jsonToDoubleN)  double? consumption)?  $default,) {final _that = this;
switch (_that) {
case _FuelEntry() when $default != null:
return $default(_that.date,_that.odometer,_that.liters,_that.amount,_that.currency,_that.station,_that.memo,_that.fullTank,_that.distance,_that.pricePerLiter,_that.consumption);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FuelEntry implements FuelEntry {
  const _FuelEntry({required this.date, @JsonKey(fromJson: jsonToDoubleN) this.odometer, @JsonKey(fromJson: jsonToDoubleN) this.liters, @JsonKey(fromJson: jsonToDoubleN) this.amount, this.currency, this.station, this.memo, this.fullTank = false, @JsonKey(fromJson: jsonToDoubleN) this.distance, @JsonKey(fromJson: jsonToDoubleN) this.pricePerLiter, @JsonKey(fromJson: jsonToDoubleN) this.consumption});
  factory _FuelEntry.fromJson(Map<String, dynamic> json) => _$FuelEntryFromJson(json);

@override final  DateTime date;
@override@JsonKey(fromJson: jsonToDoubleN) final  double? odometer;
@override@JsonKey(fromJson: jsonToDoubleN) final  double? liters;
@override@JsonKey(fromJson: jsonToDoubleN) final  double? amount;
@override final  String? currency;
@override final  String? station;
@override final  String? memo;
@override@JsonKey() final  bool fullTank;
@override@JsonKey(fromJson: jsonToDoubleN) final  double? distance;
@override@JsonKey(fromJson: jsonToDoubleN) final  double? pricePerLiter;
@override@JsonKey(fromJson: jsonToDoubleN) final  double? consumption;

/// Create a copy of FuelEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FuelEntryCopyWith<_FuelEntry> get copyWith => __$FuelEntryCopyWithImpl<_FuelEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FuelEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FuelEntry&&(identical(other.date, date) || other.date == date)&&(identical(other.odometer, odometer) || other.odometer == odometer)&&(identical(other.liters, liters) || other.liters == liters)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.station, station) || other.station == station)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.fullTank, fullTank) || other.fullTank == fullTank)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.pricePerLiter, pricePerLiter) || other.pricePerLiter == pricePerLiter)&&(identical(other.consumption, consumption) || other.consumption == consumption));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,odometer,liters,amount,currency,station,memo,fullTank,distance,pricePerLiter,consumption);

@override
String toString() {
  return 'FuelEntry(date: $date, odometer: $odometer, liters: $liters, amount: $amount, currency: $currency, station: $station, memo: $memo, fullTank: $fullTank, distance: $distance, pricePerLiter: $pricePerLiter, consumption: $consumption)';
}


}

/// @nodoc
abstract mixin class _$FuelEntryCopyWith<$Res> implements $FuelEntryCopyWith<$Res> {
  factory _$FuelEntryCopyWith(_FuelEntry value, $Res Function(_FuelEntry) _then) = __$FuelEntryCopyWithImpl;
@override @useResult
$Res call({
 DateTime date,@JsonKey(fromJson: jsonToDoubleN) double? odometer,@JsonKey(fromJson: jsonToDoubleN) double? liters,@JsonKey(fromJson: jsonToDoubleN) double? amount, String? currency, String? station, String? memo, bool fullTank,@JsonKey(fromJson: jsonToDoubleN) double? distance,@JsonKey(fromJson: jsonToDoubleN) double? pricePerLiter,@JsonKey(fromJson: jsonToDoubleN) double? consumption
});




}
/// @nodoc
class __$FuelEntryCopyWithImpl<$Res>
    implements _$FuelEntryCopyWith<$Res> {
  __$FuelEntryCopyWithImpl(this._self, this._then);

  final _FuelEntry _self;
  final $Res Function(_FuelEntry) _then;

/// Create a copy of FuelEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? odometer = freezed,Object? liters = freezed,Object? amount = freezed,Object? currency = freezed,Object? station = freezed,Object? memo = freezed,Object? fullTank = null,Object? distance = freezed,Object? pricePerLiter = freezed,Object? consumption = freezed,}) {
  return _then(_FuelEntry(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,odometer: freezed == odometer ? _self.odometer : odometer // ignore: cast_nullable_to_non_nullable
as double?,liters: freezed == liters ? _self.liters : liters // ignore: cast_nullable_to_non_nullable
as double?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,station: freezed == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as String?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,fullTank: null == fullTank ? _self.fullTank : fullTank // ignore: cast_nullable_to_non_nullable
as bool,distance: freezed == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double?,pricePerLiter: freezed == pricePerLiter ? _self.pricePerLiter : pricePerLiter // ignore: cast_nullable_to_non_nullable
as double?,consumption: freezed == consumption ? _self.consumption : consumption // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$VehicleReport {

 List<FuelEntry> get entries;@JsonKey(fromJson: jsonToDouble) double get totalCost;@JsonKey(fromJson: jsonToDouble) double get totalLiters;@JsonKey(fromJson: jsonToDouble) double get totalDistance;@JsonKey(fromJson: jsonToDoubleN) double? get avgConsumption;@JsonKey(fromJson: jsonToDoubleN) double? get avgPricePerLiter; String get currency;
/// Create a copy of VehicleReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleReportCopyWith<VehicleReport> get copyWith => _$VehicleReportCopyWithImpl<VehicleReport>(this as VehicleReport, _$identity);

  /// Serializes this VehicleReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleReport&&const DeepCollectionEquality().equals(other.entries, entries)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.totalLiters, totalLiters) || other.totalLiters == totalLiters)&&(identical(other.totalDistance, totalDistance) || other.totalDistance == totalDistance)&&(identical(other.avgConsumption, avgConsumption) || other.avgConsumption == avgConsumption)&&(identical(other.avgPricePerLiter, avgPricePerLiter) || other.avgPricePerLiter == avgPricePerLiter)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(entries),totalCost,totalLiters,totalDistance,avgConsumption,avgPricePerLiter,currency);

@override
String toString() {
  return 'VehicleReport(entries: $entries, totalCost: $totalCost, totalLiters: $totalLiters, totalDistance: $totalDistance, avgConsumption: $avgConsumption, avgPricePerLiter: $avgPricePerLiter, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $VehicleReportCopyWith<$Res>  {
  factory $VehicleReportCopyWith(VehicleReport value, $Res Function(VehicleReport) _then) = _$VehicleReportCopyWithImpl;
@useResult
$Res call({
 List<FuelEntry> entries,@JsonKey(fromJson: jsonToDouble) double totalCost,@JsonKey(fromJson: jsonToDouble) double totalLiters,@JsonKey(fromJson: jsonToDouble) double totalDistance,@JsonKey(fromJson: jsonToDoubleN) double? avgConsumption,@JsonKey(fromJson: jsonToDoubleN) double? avgPricePerLiter, String currency
});




}
/// @nodoc
class _$VehicleReportCopyWithImpl<$Res>
    implements $VehicleReportCopyWith<$Res> {
  _$VehicleReportCopyWithImpl(this._self, this._then);

  final VehicleReport _self;
  final $Res Function(VehicleReport) _then;

/// Create a copy of VehicleReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,Object? totalCost = null,Object? totalLiters = null,Object? totalDistance = null,Object? avgConsumption = freezed,Object? avgPricePerLiter = freezed,Object? currency = null,}) {
  return _then(_self.copyWith(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<FuelEntry>,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,totalLiters: null == totalLiters ? _self.totalLiters : totalLiters // ignore: cast_nullable_to_non_nullable
as double,totalDistance: null == totalDistance ? _self.totalDistance : totalDistance // ignore: cast_nullable_to_non_nullable
as double,avgConsumption: freezed == avgConsumption ? _self.avgConsumption : avgConsumption // ignore: cast_nullable_to_non_nullable
as double?,avgPricePerLiter: freezed == avgPricePerLiter ? _self.avgPricePerLiter : avgPricePerLiter // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VehicleReport].
extension VehicleReportPatterns on VehicleReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehicleReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehicleReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehicleReport value)  $default,){
final _that = this;
switch (_that) {
case _VehicleReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehicleReport value)?  $default,){
final _that = this;
switch (_that) {
case _VehicleReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<FuelEntry> entries, @JsonKey(fromJson: jsonToDouble)  double totalCost, @JsonKey(fromJson: jsonToDouble)  double totalLiters, @JsonKey(fromJson: jsonToDouble)  double totalDistance, @JsonKey(fromJson: jsonToDoubleN)  double? avgConsumption, @JsonKey(fromJson: jsonToDoubleN)  double? avgPricePerLiter,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleReport() when $default != null:
return $default(_that.entries,_that.totalCost,_that.totalLiters,_that.totalDistance,_that.avgConsumption,_that.avgPricePerLiter,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<FuelEntry> entries, @JsonKey(fromJson: jsonToDouble)  double totalCost, @JsonKey(fromJson: jsonToDouble)  double totalLiters, @JsonKey(fromJson: jsonToDouble)  double totalDistance, @JsonKey(fromJson: jsonToDoubleN)  double? avgConsumption, @JsonKey(fromJson: jsonToDoubleN)  double? avgPricePerLiter,  String currency)  $default,) {final _that = this;
switch (_that) {
case _VehicleReport():
return $default(_that.entries,_that.totalCost,_that.totalLiters,_that.totalDistance,_that.avgConsumption,_that.avgPricePerLiter,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<FuelEntry> entries, @JsonKey(fromJson: jsonToDouble)  double totalCost, @JsonKey(fromJson: jsonToDouble)  double totalLiters, @JsonKey(fromJson: jsonToDouble)  double totalDistance, @JsonKey(fromJson: jsonToDoubleN)  double? avgConsumption, @JsonKey(fromJson: jsonToDoubleN)  double? avgPricePerLiter,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _VehicleReport() when $default != null:
return $default(_that.entries,_that.totalCost,_that.totalLiters,_that.totalDistance,_that.avgConsumption,_that.avgPricePerLiter,_that.currency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehicleReport implements VehicleReport {
  const _VehicleReport({final  List<FuelEntry> entries = const [], @JsonKey(fromJson: jsonToDouble) this.totalCost = 0, @JsonKey(fromJson: jsonToDouble) this.totalLiters = 0, @JsonKey(fromJson: jsonToDouble) this.totalDistance = 0, @JsonKey(fromJson: jsonToDoubleN) this.avgConsumption, @JsonKey(fromJson: jsonToDoubleN) this.avgPricePerLiter, this.currency = 'EUR'}): _entries = entries;
  factory _VehicleReport.fromJson(Map<String, dynamic> json) => _$VehicleReportFromJson(json);

 final  List<FuelEntry> _entries;
@override@JsonKey() List<FuelEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

@override@JsonKey(fromJson: jsonToDouble) final  double totalCost;
@override@JsonKey(fromJson: jsonToDouble) final  double totalLiters;
@override@JsonKey(fromJson: jsonToDouble) final  double totalDistance;
@override@JsonKey(fromJson: jsonToDoubleN) final  double? avgConsumption;
@override@JsonKey(fromJson: jsonToDoubleN) final  double? avgPricePerLiter;
@override@JsonKey() final  String currency;

/// Create a copy of VehicleReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleReportCopyWith<_VehicleReport> get copyWith => __$VehicleReportCopyWithImpl<_VehicleReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleReport&&const DeepCollectionEquality().equals(other._entries, _entries)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.totalLiters, totalLiters) || other.totalLiters == totalLiters)&&(identical(other.totalDistance, totalDistance) || other.totalDistance == totalDistance)&&(identical(other.avgConsumption, avgConsumption) || other.avgConsumption == avgConsumption)&&(identical(other.avgPricePerLiter, avgPricePerLiter) || other.avgPricePerLiter == avgPricePerLiter)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries),totalCost,totalLiters,totalDistance,avgConsumption,avgPricePerLiter,currency);

@override
String toString() {
  return 'VehicleReport(entries: $entries, totalCost: $totalCost, totalLiters: $totalLiters, totalDistance: $totalDistance, avgConsumption: $avgConsumption, avgPricePerLiter: $avgPricePerLiter, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$VehicleReportCopyWith<$Res> implements $VehicleReportCopyWith<$Res> {
  factory _$VehicleReportCopyWith(_VehicleReport value, $Res Function(_VehicleReport) _then) = __$VehicleReportCopyWithImpl;
@override @useResult
$Res call({
 List<FuelEntry> entries,@JsonKey(fromJson: jsonToDouble) double totalCost,@JsonKey(fromJson: jsonToDouble) double totalLiters,@JsonKey(fromJson: jsonToDouble) double totalDistance,@JsonKey(fromJson: jsonToDoubleN) double? avgConsumption,@JsonKey(fromJson: jsonToDoubleN) double? avgPricePerLiter, String currency
});




}
/// @nodoc
class __$VehicleReportCopyWithImpl<$Res>
    implements _$VehicleReportCopyWith<$Res> {
  __$VehicleReportCopyWithImpl(this._self, this._then);

  final _VehicleReport _self;
  final $Res Function(_VehicleReport) _then;

/// Create a copy of VehicleReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entries = null,Object? totalCost = null,Object? totalLiters = null,Object? totalDistance = null,Object? avgConsumption = freezed,Object? avgPricePerLiter = freezed,Object? currency = null,}) {
  return _then(_VehicleReport(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<FuelEntry>,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,totalLiters: null == totalLiters ? _self.totalLiters : totalLiters // ignore: cast_nullable_to_non_nullable
as double,totalDistance: null == totalDistance ? _self.totalDistance : totalDistance // ignore: cast_nullable_to_non_nullable
as double,avgConsumption: freezed == avgConsumption ? _self.avgConsumption : avgConsumption // ignore: cast_nullable_to_non_nullable
as double?,avgPricePerLiter: freezed == avgPricePerLiter ? _self.avgPricePerLiter : avgPricePerLiter // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
