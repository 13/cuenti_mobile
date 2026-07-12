// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BudgetProgress {

 int get budgetId; int get categoryId; String? get categoryName;@JsonKey(fromJson: jsonToDouble) double get monthlyLimit;@JsonKey(fromJson: jsonToDouble) double get spent;@JsonKey(fromJson: jsonToDouble) double get remaining; bool get active;
/// Create a copy of BudgetProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetProgressCopyWith<BudgetProgress> get copyWith => _$BudgetProgressCopyWithImpl<BudgetProgress>(this as BudgetProgress, _$identity);

  /// Serializes this BudgetProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetProgress&&(identical(other.budgetId, budgetId) || other.budgetId == budgetId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.monthlyLimit, monthlyLimit) || other.monthlyLimit == monthlyLimit)&&(identical(other.spent, spent) || other.spent == spent)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.active, active) || other.active == active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,budgetId,categoryId,categoryName,monthlyLimit,spent,remaining,active);

@override
String toString() {
  return 'BudgetProgress(budgetId: $budgetId, categoryId: $categoryId, categoryName: $categoryName, monthlyLimit: $monthlyLimit, spent: $spent, remaining: $remaining, active: $active)';
}


}

/// @nodoc
abstract mixin class $BudgetProgressCopyWith<$Res>  {
  factory $BudgetProgressCopyWith(BudgetProgress value, $Res Function(BudgetProgress) _then) = _$BudgetProgressCopyWithImpl;
@useResult
$Res call({
 int budgetId, int categoryId, String? categoryName,@JsonKey(fromJson: jsonToDouble) double monthlyLimit,@JsonKey(fromJson: jsonToDouble) double spent,@JsonKey(fromJson: jsonToDouble) double remaining, bool active
});




}
/// @nodoc
class _$BudgetProgressCopyWithImpl<$Res>
    implements $BudgetProgressCopyWith<$Res> {
  _$BudgetProgressCopyWithImpl(this._self, this._then);

  final BudgetProgress _self;
  final $Res Function(BudgetProgress) _then;

/// Create a copy of BudgetProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? budgetId = null,Object? categoryId = null,Object? categoryName = freezed,Object? monthlyLimit = null,Object? spent = null,Object? remaining = null,Object? active = null,}) {
  return _then(_self.copyWith(
budgetId: null == budgetId ? _self.budgetId : budgetId // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,monthlyLimit: null == monthlyLimit ? _self.monthlyLimit : monthlyLimit // ignore: cast_nullable_to_non_nullable
as double,spent: null == spent ? _self.spent : spent // ignore: cast_nullable_to_non_nullable
as double,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as double,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BudgetProgress].
extension BudgetProgressPatterns on BudgetProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BudgetProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BudgetProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BudgetProgress value)  $default,){
final _that = this;
switch (_that) {
case _BudgetProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BudgetProgress value)?  $default,){
final _that = this;
switch (_that) {
case _BudgetProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int budgetId,  int categoryId,  String? categoryName, @JsonKey(fromJson: jsonToDouble)  double monthlyLimit, @JsonKey(fromJson: jsonToDouble)  double spent, @JsonKey(fromJson: jsonToDouble)  double remaining,  bool active)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BudgetProgress() when $default != null:
return $default(_that.budgetId,_that.categoryId,_that.categoryName,_that.monthlyLimit,_that.spent,_that.remaining,_that.active);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int budgetId,  int categoryId,  String? categoryName, @JsonKey(fromJson: jsonToDouble)  double monthlyLimit, @JsonKey(fromJson: jsonToDouble)  double spent, @JsonKey(fromJson: jsonToDouble)  double remaining,  bool active)  $default,) {final _that = this;
switch (_that) {
case _BudgetProgress():
return $default(_that.budgetId,_that.categoryId,_that.categoryName,_that.monthlyLimit,_that.spent,_that.remaining,_that.active);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int budgetId,  int categoryId,  String? categoryName, @JsonKey(fromJson: jsonToDouble)  double monthlyLimit, @JsonKey(fromJson: jsonToDouble)  double spent, @JsonKey(fromJson: jsonToDouble)  double remaining,  bool active)?  $default,) {final _that = this;
switch (_that) {
case _BudgetProgress() when $default != null:
return $default(_that.budgetId,_that.categoryId,_that.categoryName,_that.monthlyLimit,_that.spent,_that.remaining,_that.active);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BudgetProgress implements BudgetProgress {
  const _BudgetProgress({required this.budgetId, required this.categoryId, this.categoryName, @JsonKey(fromJson: jsonToDouble) this.monthlyLimit = 0, @JsonKey(fromJson: jsonToDouble) this.spent = 0, @JsonKey(fromJson: jsonToDouble) this.remaining = 0, this.active = true});
  factory _BudgetProgress.fromJson(Map<String, dynamic> json) => _$BudgetProgressFromJson(json);

@override final  int budgetId;
@override final  int categoryId;
@override final  String? categoryName;
@override@JsonKey(fromJson: jsonToDouble) final  double monthlyLimit;
@override@JsonKey(fromJson: jsonToDouble) final  double spent;
@override@JsonKey(fromJson: jsonToDouble) final  double remaining;
@override@JsonKey() final  bool active;

/// Create a copy of BudgetProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetProgressCopyWith<_BudgetProgress> get copyWith => __$BudgetProgressCopyWithImpl<_BudgetProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BudgetProgress&&(identical(other.budgetId, budgetId) || other.budgetId == budgetId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.monthlyLimit, monthlyLimit) || other.monthlyLimit == monthlyLimit)&&(identical(other.spent, spent) || other.spent == spent)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.active, active) || other.active == active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,budgetId,categoryId,categoryName,monthlyLimit,spent,remaining,active);

@override
String toString() {
  return 'BudgetProgress(budgetId: $budgetId, categoryId: $categoryId, categoryName: $categoryName, monthlyLimit: $monthlyLimit, spent: $spent, remaining: $remaining, active: $active)';
}


}

/// @nodoc
abstract mixin class _$BudgetProgressCopyWith<$Res> implements $BudgetProgressCopyWith<$Res> {
  factory _$BudgetProgressCopyWith(_BudgetProgress value, $Res Function(_BudgetProgress) _then) = __$BudgetProgressCopyWithImpl;
@override @useResult
$Res call({
 int budgetId, int categoryId, String? categoryName,@JsonKey(fromJson: jsonToDouble) double monthlyLimit,@JsonKey(fromJson: jsonToDouble) double spent,@JsonKey(fromJson: jsonToDouble) double remaining, bool active
});




}
/// @nodoc
class __$BudgetProgressCopyWithImpl<$Res>
    implements _$BudgetProgressCopyWith<$Res> {
  __$BudgetProgressCopyWithImpl(this._self, this._then);

  final _BudgetProgress _self;
  final $Res Function(_BudgetProgress) _then;

/// Create a copy of BudgetProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? budgetId = null,Object? categoryId = null,Object? categoryName = freezed,Object? monthlyLimit = null,Object? spent = null,Object? remaining = null,Object? active = null,}) {
  return _then(_BudgetProgress(
budgetId: null == budgetId ? _self.budgetId : budgetId // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,monthlyLimit: null == monthlyLimit ? _self.monthlyLimit : monthlyLimit // ignore: cast_nullable_to_non_nullable
as double,spent: null == spent ? _self.spent : spent // ignore: cast_nullable_to_non_nullable
as double,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as double,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
