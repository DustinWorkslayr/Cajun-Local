// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parish.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Parish {

 String get id; String get name; String? get slug;@JsonKey(name: 'sort_order', defaultValue: 0) int get sortOrder;
/// Create a copy of Parish
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParishCopyWith<Parish> get copyWith => _$ParishCopyWithImpl<Parish>(this as Parish, _$identity);

  /// Serializes this Parish to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Parish&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,sortOrder);

@override
String toString() {
  return 'Parish(id: $id, name: $name, slug: $slug, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ParishCopyWith<$Res>  {
  factory $ParishCopyWith(Parish value, $Res Function(Parish) _then) = _$ParishCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? slug,@JsonKey(name: 'sort_order', defaultValue: 0) int sortOrder
});




}
/// @nodoc
class _$ParishCopyWithImpl<$Res>
    implements $ParishCopyWith<$Res> {
  _$ParishCopyWithImpl(this._self, this._then);

  final Parish _self;
  final $Res Function(Parish) _then;

/// Create a copy of Parish
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slug = freezed,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Parish].
extension ParishPatterns on Parish {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Parish value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Parish() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Parish value)  $default,){
final _that = this;
switch (_that) {
case _Parish():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Parish value)?  $default,){
final _that = this;
switch (_that) {
case _Parish() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? slug, @JsonKey(name: 'sort_order', defaultValue: 0)  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Parish() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? slug, @JsonKey(name: 'sort_order', defaultValue: 0)  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _Parish():
return $default(_that.id,_that.name,_that.slug,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? slug, @JsonKey(name: 'sort_order', defaultValue: 0)  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _Parish() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Parish implements Parish {
  const _Parish({required this.id, required this.name, this.slug, @JsonKey(name: 'sort_order', defaultValue: 0) required this.sortOrder});
  factory _Parish.fromJson(Map<String, dynamic> json) => _$ParishFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? slug;
@override@JsonKey(name: 'sort_order', defaultValue: 0) final  int sortOrder;

/// Create a copy of Parish
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParishCopyWith<_Parish> get copyWith => __$ParishCopyWithImpl<_Parish>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParishToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Parish&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,sortOrder);

@override
String toString() {
  return 'Parish(id: $id, name: $name, slug: $slug, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ParishCopyWith<$Res> implements $ParishCopyWith<$Res> {
  factory _$ParishCopyWith(_Parish value, $Res Function(_Parish) _then) = __$ParishCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? slug,@JsonKey(name: 'sort_order', defaultValue: 0) int sortOrder
});




}
/// @nodoc
class __$ParishCopyWithImpl<$Res>
    implements _$ParishCopyWith<$Res> {
  __$ParishCopyWithImpl(this._self, this._then);

  final _Parish _self;
  final $Res Function(_Parish) _then;

/// Create a copy of Parish
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slug = freezed,Object? sortOrder = null,}) {
  return _then(_Parish(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
