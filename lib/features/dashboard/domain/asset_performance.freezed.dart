// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_performance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssetPerformance {

 String get assetName; String get assetSymbol;@JsonKey(fromJson: jsonToDouble) double get totalUnits;@JsonKey(fromJson: jsonToDouble) double get totalCost;@JsonKey(fromJson: jsonToDouble) double get currentValue;@JsonKey(fromJson: jsonToDouble) double get currentPrice;@JsonKey(fromJson: jsonToDouble) double get gainLoss;@JsonKey(fromJson: jsonToDouble) double get gainLossPercent;
/// Create a copy of AssetPerformance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetPerformanceCopyWith<AssetPerformance> get copyWith => _$AssetPerformanceCopyWithImpl<AssetPerformance>(this as AssetPerformance, _$identity);

  /// Serializes this AssetPerformance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetPerformance&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.assetSymbol, assetSymbol) || other.assetSymbol == assetSymbol)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.gainLoss, gainLoss) || other.gainLoss == gainLoss)&&(identical(other.gainLossPercent, gainLossPercent) || other.gainLossPercent == gainLossPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assetName,assetSymbol,totalUnits,totalCost,currentValue,currentPrice,gainLoss,gainLossPercent);

@override
String toString() {
  return 'AssetPerformance(assetName: $assetName, assetSymbol: $assetSymbol, totalUnits: $totalUnits, totalCost: $totalCost, currentValue: $currentValue, currentPrice: $currentPrice, gainLoss: $gainLoss, gainLossPercent: $gainLossPercent)';
}


}

/// @nodoc
abstract mixin class $AssetPerformanceCopyWith<$Res>  {
  factory $AssetPerformanceCopyWith(AssetPerformance value, $Res Function(AssetPerformance) _then) = _$AssetPerformanceCopyWithImpl;
@useResult
$Res call({
 String assetName, String assetSymbol,@JsonKey(fromJson: jsonToDouble) double totalUnits,@JsonKey(fromJson: jsonToDouble) double totalCost,@JsonKey(fromJson: jsonToDouble) double currentValue,@JsonKey(fromJson: jsonToDouble) double currentPrice,@JsonKey(fromJson: jsonToDouble) double gainLoss,@JsonKey(fromJson: jsonToDouble) double gainLossPercent
});




}
/// @nodoc
class _$AssetPerformanceCopyWithImpl<$Res>
    implements $AssetPerformanceCopyWith<$Res> {
  _$AssetPerformanceCopyWithImpl(this._self, this._then);

  final AssetPerformance _self;
  final $Res Function(AssetPerformance) _then;

/// Create a copy of AssetPerformance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assetName = null,Object? assetSymbol = null,Object? totalUnits = null,Object? totalCost = null,Object? currentValue = null,Object? currentPrice = null,Object? gainLoss = null,Object? gainLossPercent = null,}) {
  return _then(_self.copyWith(
assetName: null == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String,assetSymbol: null == assetSymbol ? _self.assetSymbol : assetSymbol // ignore: cast_nullable_to_non_nullable
as String,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as double,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as double,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as double,gainLoss: null == gainLoss ? _self.gainLoss : gainLoss // ignore: cast_nullable_to_non_nullable
as double,gainLossPercent: null == gainLossPercent ? _self.gainLossPercent : gainLossPercent // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetPerformance].
extension AssetPerformancePatterns on AssetPerformance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetPerformance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetPerformance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetPerformance value)  $default,){
final _that = this;
switch (_that) {
case _AssetPerformance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetPerformance value)?  $default,){
final _that = this;
switch (_that) {
case _AssetPerformance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String assetName,  String assetSymbol, @JsonKey(fromJson: jsonToDouble)  double totalUnits, @JsonKey(fromJson: jsonToDouble)  double totalCost, @JsonKey(fromJson: jsonToDouble)  double currentValue, @JsonKey(fromJson: jsonToDouble)  double currentPrice, @JsonKey(fromJson: jsonToDouble)  double gainLoss, @JsonKey(fromJson: jsonToDouble)  double gainLossPercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetPerformance() when $default != null:
return $default(_that.assetName,_that.assetSymbol,_that.totalUnits,_that.totalCost,_that.currentValue,_that.currentPrice,_that.gainLoss,_that.gainLossPercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String assetName,  String assetSymbol, @JsonKey(fromJson: jsonToDouble)  double totalUnits, @JsonKey(fromJson: jsonToDouble)  double totalCost, @JsonKey(fromJson: jsonToDouble)  double currentValue, @JsonKey(fromJson: jsonToDouble)  double currentPrice, @JsonKey(fromJson: jsonToDouble)  double gainLoss, @JsonKey(fromJson: jsonToDouble)  double gainLossPercent)  $default,) {final _that = this;
switch (_that) {
case _AssetPerformance():
return $default(_that.assetName,_that.assetSymbol,_that.totalUnits,_that.totalCost,_that.currentValue,_that.currentPrice,_that.gainLoss,_that.gainLossPercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String assetName,  String assetSymbol, @JsonKey(fromJson: jsonToDouble)  double totalUnits, @JsonKey(fromJson: jsonToDouble)  double totalCost, @JsonKey(fromJson: jsonToDouble)  double currentValue, @JsonKey(fromJson: jsonToDouble)  double currentPrice, @JsonKey(fromJson: jsonToDouble)  double gainLoss, @JsonKey(fromJson: jsonToDouble)  double gainLossPercent)?  $default,) {final _that = this;
switch (_that) {
case _AssetPerformance() when $default != null:
return $default(_that.assetName,_that.assetSymbol,_that.totalUnits,_that.totalCost,_that.currentValue,_that.currentPrice,_that.gainLoss,_that.gainLossPercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssetPerformance extends AssetPerformance {
  const _AssetPerformance({this.assetName = '', this.assetSymbol = '', @JsonKey(fromJson: jsonToDouble) required this.totalUnits, @JsonKey(fromJson: jsonToDouble) required this.totalCost, @JsonKey(fromJson: jsonToDouble) required this.currentValue, @JsonKey(fromJson: jsonToDouble) required this.currentPrice, @JsonKey(fromJson: jsonToDouble) required this.gainLoss, @JsonKey(fromJson: jsonToDouble) required this.gainLossPercent}): super._();
  factory _AssetPerformance.fromJson(Map<String, dynamic> json) => _$AssetPerformanceFromJson(json);

@override@JsonKey() final  String assetName;
@override@JsonKey() final  String assetSymbol;
@override@JsonKey(fromJson: jsonToDouble) final  double totalUnits;
@override@JsonKey(fromJson: jsonToDouble) final  double totalCost;
@override@JsonKey(fromJson: jsonToDouble) final  double currentValue;
@override@JsonKey(fromJson: jsonToDouble) final  double currentPrice;
@override@JsonKey(fromJson: jsonToDouble) final  double gainLoss;
@override@JsonKey(fromJson: jsonToDouble) final  double gainLossPercent;

/// Create a copy of AssetPerformance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetPerformanceCopyWith<_AssetPerformance> get copyWith => __$AssetPerformanceCopyWithImpl<_AssetPerformance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetPerformanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetPerformance&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.assetSymbol, assetSymbol) || other.assetSymbol == assetSymbol)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.gainLoss, gainLoss) || other.gainLoss == gainLoss)&&(identical(other.gainLossPercent, gainLossPercent) || other.gainLossPercent == gainLossPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assetName,assetSymbol,totalUnits,totalCost,currentValue,currentPrice,gainLoss,gainLossPercent);

@override
String toString() {
  return 'AssetPerformance(assetName: $assetName, assetSymbol: $assetSymbol, totalUnits: $totalUnits, totalCost: $totalCost, currentValue: $currentValue, currentPrice: $currentPrice, gainLoss: $gainLoss, gainLossPercent: $gainLossPercent)';
}


}

/// @nodoc
abstract mixin class _$AssetPerformanceCopyWith<$Res> implements $AssetPerformanceCopyWith<$Res> {
  factory _$AssetPerformanceCopyWith(_AssetPerformance value, $Res Function(_AssetPerformance) _then) = __$AssetPerformanceCopyWithImpl;
@override @useResult
$Res call({
 String assetName, String assetSymbol,@JsonKey(fromJson: jsonToDouble) double totalUnits,@JsonKey(fromJson: jsonToDouble) double totalCost,@JsonKey(fromJson: jsonToDouble) double currentValue,@JsonKey(fromJson: jsonToDouble) double currentPrice,@JsonKey(fromJson: jsonToDouble) double gainLoss,@JsonKey(fromJson: jsonToDouble) double gainLossPercent
});




}
/// @nodoc
class __$AssetPerformanceCopyWithImpl<$Res>
    implements _$AssetPerformanceCopyWith<$Res> {
  __$AssetPerformanceCopyWithImpl(this._self, this._then);

  final _AssetPerformance _self;
  final $Res Function(_AssetPerformance) _then;

/// Create a copy of AssetPerformance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assetName = null,Object? assetSymbol = null,Object? totalUnits = null,Object? totalCost = null,Object? currentValue = null,Object? currentPrice = null,Object? gainLoss = null,Object? gainLossPercent = null,}) {
  return _then(_AssetPerformance(
assetName: null == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String,assetSymbol: null == assetSymbol ? _self.assetSymbol : assetSymbol // ignore: cast_nullable_to_non_nullable
as String,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as double,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as double,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as double,gainLoss: null == gainLoss ? _self.gainLoss : gainLoss // ignore: cast_nullable_to_non_nullable
as double,gainLossPercent: null == gainLossPercent ? _self.gainLossPercent : gainLossPercent // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
