// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuditPage {

 List<AuditEntry> get content; int get page; int get size; int get totalElements; int get totalPages;
/// Create a copy of AuditPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditPageCopyWith<AuditPage> get copyWith => _$AuditPageCopyWithImpl<AuditPage>(this as AuditPage, _$identity);

  /// Serializes this AuditPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditPage&&const DeepCollectionEquality().equals(other.content, content)&&(identical(other.page, page) || other.page == page)&&(identical(other.size, size) || other.size == size)&&(identical(other.totalElements, totalElements) || other.totalElements == totalElements)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(content),page,size,totalElements,totalPages);

@override
String toString() {
  return 'AuditPage(content: $content, page: $page, size: $size, totalElements: $totalElements, totalPages: $totalPages)';
}


}

/// @nodoc
abstract mixin class $AuditPageCopyWith<$Res>  {
  factory $AuditPageCopyWith(AuditPage value, $Res Function(AuditPage) _then) = _$AuditPageCopyWithImpl;
@useResult
$Res call({
 List<AuditEntry> content, int page, int size, int totalElements, int totalPages
});




}
/// @nodoc
class _$AuditPageCopyWithImpl<$Res>
    implements $AuditPageCopyWith<$Res> {
  _$AuditPageCopyWithImpl(this._self, this._then);

  final AuditPage _self;
  final $Res Function(AuditPage) _then;

/// Create a copy of AuditPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? page = null,Object? size = null,Object? totalElements = null,Object? totalPages = null,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as List<AuditEntry>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,totalElements: null == totalElements ? _self.totalElements : totalElements // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditPage].
extension AuditPagePatterns on AuditPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditPage value)  $default,){
final _that = this;
switch (_that) {
case _AuditPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditPage value)?  $default,){
final _that = this;
switch (_that) {
case _AuditPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AuditEntry> content,  int page,  int size,  int totalElements,  int totalPages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditPage() when $default != null:
return $default(_that.content,_that.page,_that.size,_that.totalElements,_that.totalPages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AuditEntry> content,  int page,  int size,  int totalElements,  int totalPages)  $default,) {final _that = this;
switch (_that) {
case _AuditPage():
return $default(_that.content,_that.page,_that.size,_that.totalElements,_that.totalPages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AuditEntry> content,  int page,  int size,  int totalElements,  int totalPages)?  $default,) {final _that = this;
switch (_that) {
case _AuditPage() when $default != null:
return $default(_that.content,_that.page,_that.size,_that.totalElements,_that.totalPages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditPage implements AuditPage {
  const _AuditPage({final  List<AuditEntry> content = const [], this.page = 0, this.size = 50, this.totalElements = 0, this.totalPages = 0}): _content = content;
  factory _AuditPage.fromJson(Map<String, dynamic> json) => _$AuditPageFromJson(json);

 final  List<AuditEntry> _content;
@override@JsonKey() List<AuditEntry> get content {
  if (_content is EqualUnmodifiableListView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_content);
}

@override@JsonKey() final  int page;
@override@JsonKey() final  int size;
@override@JsonKey() final  int totalElements;
@override@JsonKey() final  int totalPages;

/// Create a copy of AuditPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditPageCopyWith<_AuditPage> get copyWith => __$AuditPageCopyWithImpl<_AuditPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditPage&&const DeepCollectionEquality().equals(other._content, _content)&&(identical(other.page, page) || other.page == page)&&(identical(other.size, size) || other.size == size)&&(identical(other.totalElements, totalElements) || other.totalElements == totalElements)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_content),page,size,totalElements,totalPages);

@override
String toString() {
  return 'AuditPage(content: $content, page: $page, size: $size, totalElements: $totalElements, totalPages: $totalPages)';
}


}

/// @nodoc
abstract mixin class _$AuditPageCopyWith<$Res> implements $AuditPageCopyWith<$Res> {
  factory _$AuditPageCopyWith(_AuditPage value, $Res Function(_AuditPage) _then) = __$AuditPageCopyWithImpl;
@override @useResult
$Res call({
 List<AuditEntry> content, int page, int size, int totalElements, int totalPages
});




}
/// @nodoc
class __$AuditPageCopyWithImpl<$Res>
    implements _$AuditPageCopyWith<$Res> {
  __$AuditPageCopyWithImpl(this._self, this._then);

  final _AuditPage _self;
  final $Res Function(_AuditPage) _then;

/// Create a copy of AuditPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? page = null,Object? size = null,Object? totalElements = null,Object? totalPages = null,}) {
  return _then(_AuditPage(
content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as List<AuditEntry>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,totalElements: null == totalElements ? _self.totalElements : totalElements // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
