// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transactions_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionsState implements DiagnosticableTreeMixin {

 List<Transaction> get items; int get nextPage; bool get hasMore; bool get loadingMore; TransactionFilter get filter;/// Writes the server has not taken yet. The [items] above already
/// reflect them; this is here so the UI can mark the rows.
 List<PendingTransaction> get pending;
/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionsStateCopyWith<TransactionsState> get copyWith => _$TransactionsStateCopyWithImpl<TransactionsState>(this as TransactionsState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as TransactionsState;
  properties
    ..add(DiagnosticsProperty('type', 'TransactionsState'))
    ..add(DiagnosticsProperty('items', _this.items))..add(DiagnosticsProperty('nextPage', _this.nextPage))..add(DiagnosticsProperty('hasMore', _this.hasMore))..add(DiagnosticsProperty('loadingMore', _this.loadingMore))..add(DiagnosticsProperty('filter', _this.filter))..add(DiagnosticsProperty('pending', _this.pending));
}

@override
bool operator ==(Object other) {
  final _this = this as TransactionsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionsState&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextPage, _this.nextPage) || other.nextPage == _this.nextPage)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore)&&(identical(other.filter, _this.filter) || other.filter == _this.filter)&&const DeepCollectionEquality().equals(other.pending, _this.pending));
}


@override
int get hashCode {
  final _this = this as TransactionsState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextPage,_this.hasMore,_this.loadingMore,_this.filter,const DeepCollectionEquality().hash(_this.pending));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as TransactionsState;
  return 'TransactionsState(items: ${_this.items}, nextPage: ${_this.nextPage}, hasMore: ${_this.hasMore}, loadingMore: ${_this.loadingMore}, filter: ${_this.filter}, pending: ${_this.pending})';
}


}

/// @nodoc
abstract mixin class $TransactionsStateCopyWith<$Res>  {
  factory $TransactionsStateCopyWith(TransactionsState value, $Res Function(TransactionsState) _then) = _$TransactionsStateCopyWithImpl;
@useResult
$Res call({
 List<Transaction> items, int nextPage, bool hasMore, bool loadingMore, TransactionFilter filter, List<PendingTransaction> pending
});


$TransactionFilterCopyWith<$Res> get filter;

}
/// @nodoc
class _$TransactionsStateCopyWithImpl<$Res>
    implements $TransactionsStateCopyWith<$Res> {
  _$TransactionsStateCopyWithImpl(this._self, this._then);

  final TransactionsState _self;
  final $Res Function(TransactionsState) _then;

/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextPage = null,Object? hasMore = null,Object? loadingMore = null,Object? filter = null,Object? pending = null,}) {
  return _then(TransactionsState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Transaction>,nextPage: null == nextPage ? _self.nextPage : nextPage // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as TransactionFilter,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as List<PendingTransaction>,
  ));
}
/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionFilterCopyWith<$Res> get filter {
  
  return $TransactionFilterCopyWith<$Res>(_self.filter, (value) {
    return _then(_self.copyWith(filter: value));
  });
}
}


/// Adds pattern-matching-related methods to [TransactionsState].
extension TransactionsStatePatterns on TransactionsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionsState value)  $default,){
final _that = this;
switch (_that) {
case _TransactionsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionsState value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Transaction> items,  int nextPage,  bool hasMore,  bool loadingMore,  TransactionFilter filter,  List<PendingTransaction> pending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionsState() when $default != null:
return $default(_that.items,_that.nextPage,_that.hasMore,_that.loadingMore,_that.filter,_that.pending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Transaction> items,  int nextPage,  bool hasMore,  bool loadingMore,  TransactionFilter filter,  List<PendingTransaction> pending)  $default,) {final _that = this;
switch (_that) {
case _TransactionsState():
return $default(_that.items,_that.nextPage,_that.hasMore,_that.loadingMore,_that.filter,_that.pending);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Transaction> items,  int nextPage,  bool hasMore,  bool loadingMore,  TransactionFilter filter,  List<PendingTransaction> pending)?  $default,) {final _that = this;
switch (_that) {
case _TransactionsState() when $default != null:
return $default(_that.items,_that.nextPage,_that.hasMore,_that.loadingMore,_that.filter,_that.pending);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionsState with DiagnosticableTreeMixin implements TransactionsState {
  const _TransactionsState({ List<Transaction> items = const [], this.nextPage = 0, this.hasMore = true, this.loadingMore = false, this.filter = const TransactionFilter(),  List<PendingTransaction> pending = const []}): _items = items,_pending = pending;
  

 final  List<Transaction> _items;
@override@JsonKey() List<Transaction> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int nextPage;
@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  bool loadingMore;
@override@JsonKey() final  TransactionFilter filter;
/// Writes the server has not taken yet. The [items] above already
/// reflect them; this is here so the UI can mark the rows.
 final  List<PendingTransaction> _pending;
/// Writes the server has not taken yet. The [items] above already
/// reflect them; this is here so the UI can mark the rows.
@override@JsonKey() List<PendingTransaction> get pending {
  if (_pending is EqualUnmodifiableListView) return _pending;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pending);
}


/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionsStateCopyWith<_TransactionsState> get copyWith => __$TransactionsStateCopyWithImpl<_TransactionsState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'TransactionsState'))
    ..add(DiagnosticsProperty('items', items))..add(DiagnosticsProperty('nextPage', nextPage))..add(DiagnosticsProperty('hasMore', hasMore))..add(DiagnosticsProperty('loadingMore', loadingMore))..add(DiagnosticsProperty('filter', filter))..add(DiagnosticsProperty('pending', pending));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionsState&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextPage, nextPage) || other.nextPage == nextPage)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.filter, filter) || other.filter == filter)&&const DeepCollectionEquality().equals(other.pending, _pending));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextPage,hasMore,loadingMore,filter,const DeepCollectionEquality().hash(_pending));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'TransactionsState(items: $items, nextPage: $nextPage, hasMore: $hasMore, loadingMore: $loadingMore, filter: $filter, pending: $pending)';
}


}

/// @nodoc
abstract mixin class _$TransactionsStateCopyWith<$Res> implements $TransactionsStateCopyWith<$Res> {
  factory _$TransactionsStateCopyWith(_TransactionsState value, $Res Function(_TransactionsState) _then) = __$TransactionsStateCopyWithImpl;
@override @useResult
$Res call({
 List<Transaction> items, int nextPage, bool hasMore, bool loadingMore, TransactionFilter filter, List<PendingTransaction> pending
});


@override $TransactionFilterCopyWith<$Res> get filter;

}
/// @nodoc
class __$TransactionsStateCopyWithImpl<$Res>
    implements _$TransactionsStateCopyWith<$Res> {
  __$TransactionsStateCopyWithImpl(this._self, this._then);

  final _TransactionsState _self;
  final $Res Function(_TransactionsState) _then;

/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextPage = null,Object? hasMore = null,Object? loadingMore = null,Object? filter = null,Object? pending = null,}) {
  return _then(_TransactionsState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Transaction>,nextPage: null == nextPage ? _self.nextPage : nextPage // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as TransactionFilter,pending: null == pending ? _self._pending : pending // ignore: cast_nullable_to_non_nullable
as List<PendingTransaction>,
  ));
}

/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionFilterCopyWith<$Res> get filter {
  
  return $TransactionFilterCopyWith<$Res>(_self.filter, (value) {
    return _then(_self.copyWith(filter: value));
  });
}
}

// dart format on
