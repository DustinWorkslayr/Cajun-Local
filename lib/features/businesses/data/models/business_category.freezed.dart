// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BusinessCategory {

 String get id; String get name; String get bucket; String? get slug;@JsonKey(name: 'icon_name') String? get iconName;@JsonKey(name: 'sort_order') int? get sortOrder; List<Subcategory> get subcategories;@JsonKey(name: 'business_count') int get businessCount;
/// Create a copy of BusinessCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessCategoryCopyWith<BusinessCategory> get copyWith => _$BusinessCategoryCopyWithImpl<BusinessCategory>(this as BusinessCategory, _$identity);

  /// Serializes this BusinessCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.bucket, bucket) || other.bucket == bucket)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other.subcategories, subcategories)&&(identical(other.businessCount, businessCount) || other.businessCount == businessCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,bucket,slug,iconName,sortOrder,const DeepCollectionEquality().hash(subcategories),businessCount);

@override
String toString() {
  return 'BusinessCategory(id: $id, name: $name, bucket: $bucket, slug: $slug, iconName: $iconName, sortOrder: $sortOrder, subcategories: $subcategories, businessCount: $businessCount)';
}


}

/// @nodoc
abstract mixin class $BusinessCategoryCopyWith<$Res>  {
  factory $BusinessCategoryCopyWith(BusinessCategory value, $Res Function(BusinessCategory) _then) = _$BusinessCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String bucket, String? slug,@JsonKey(name: 'icon_name') String? iconName,@JsonKey(name: 'sort_order') int? sortOrder, List<Subcategory> subcategories,@JsonKey(name: 'business_count') int businessCount
});




}
/// @nodoc
class _$BusinessCategoryCopyWithImpl<$Res>
    implements $BusinessCategoryCopyWith<$Res> {
  _$BusinessCategoryCopyWithImpl(this._self, this._then);

  final BusinessCategory _self;
  final $Res Function(BusinessCategory) _then;

/// Create a copy of BusinessCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? bucket = null,Object? slug = freezed,Object? iconName = freezed,Object? sortOrder = freezed,Object? subcategories = null,Object? businessCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as String,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,subcategories: null == subcategories ? _self.subcategories : subcategories // ignore: cast_nullable_to_non_nullable
as List<Subcategory>,businessCount: null == businessCount ? _self.businessCount : businessCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BusinessCategory].
extension BusinessCategoryPatterns on BusinessCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusinessCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusinessCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusinessCategory value)  $default,){
final _that = this;
switch (_that) {
case _BusinessCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusinessCategory value)?  $default,){
final _that = this;
switch (_that) {
case _BusinessCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String bucket,  String? slug, @JsonKey(name: 'icon_name')  String? iconName, @JsonKey(name: 'sort_order')  int? sortOrder,  List<Subcategory> subcategories, @JsonKey(name: 'business_count')  int businessCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BusinessCategory() when $default != null:
return $default(_that.id,_that.name,_that.bucket,_that.slug,_that.iconName,_that.sortOrder,_that.subcategories,_that.businessCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String bucket,  String? slug, @JsonKey(name: 'icon_name')  String? iconName, @JsonKey(name: 'sort_order')  int? sortOrder,  List<Subcategory> subcategories, @JsonKey(name: 'business_count')  int businessCount)  $default,) {final _that = this;
switch (_that) {
case _BusinessCategory():
return $default(_that.id,_that.name,_that.bucket,_that.slug,_that.iconName,_that.sortOrder,_that.subcategories,_that.businessCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String bucket,  String? slug, @JsonKey(name: 'icon_name')  String? iconName, @JsonKey(name: 'sort_order')  int? sortOrder,  List<Subcategory> subcategories, @JsonKey(name: 'business_count')  int businessCount)?  $default,) {final _that = this;
switch (_that) {
case _BusinessCategory() when $default != null:
return $default(_that.id,_that.name,_that.bucket,_that.slug,_that.iconName,_that.sortOrder,_that.subcategories,_that.businessCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BusinessCategory implements BusinessCategory {
  const _BusinessCategory({required this.id, required this.name, this.bucket = 'explore', this.slug, @JsonKey(name: 'icon_name') this.iconName, @JsonKey(name: 'sort_order') this.sortOrder, final  List<Subcategory> subcategories = const [], @JsonKey(name: 'business_count') this.businessCount = 0}): _subcategories = subcategories;
  factory _BusinessCategory.fromJson(Map<String, dynamic> json) => _$BusinessCategoryFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String bucket;
@override final  String? slug;
@override@JsonKey(name: 'icon_name') final  String? iconName;
@override@JsonKey(name: 'sort_order') final  int? sortOrder;
 final  List<Subcategory> _subcategories;
@override@JsonKey() List<Subcategory> get subcategories {
  if (_subcategories is EqualUnmodifiableListView) return _subcategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subcategories);
}

@override@JsonKey(name: 'business_count') final  int businessCount;

/// Create a copy of BusinessCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessCategoryCopyWith<_BusinessCategory> get copyWith => __$BusinessCategoryCopyWithImpl<_BusinessCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusinessCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.bucket, bucket) || other.bucket == bucket)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other._subcategories, _subcategories)&&(identical(other.businessCount, businessCount) || other.businessCount == businessCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,bucket,slug,iconName,sortOrder,const DeepCollectionEquality().hash(_subcategories),businessCount);

@override
String toString() {
  return 'BusinessCategory(id: $id, name: $name, bucket: $bucket, slug: $slug, iconName: $iconName, sortOrder: $sortOrder, subcategories: $subcategories, businessCount: $businessCount)';
}


}

/// @nodoc
abstract mixin class _$BusinessCategoryCopyWith<$Res> implements $BusinessCategoryCopyWith<$Res> {
  factory _$BusinessCategoryCopyWith(_BusinessCategory value, $Res Function(_BusinessCategory) _then) = __$BusinessCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String bucket, String? slug,@JsonKey(name: 'icon_name') String? iconName,@JsonKey(name: 'sort_order') int? sortOrder, List<Subcategory> subcategories,@JsonKey(name: 'business_count') int businessCount
});




}
/// @nodoc
class __$BusinessCategoryCopyWithImpl<$Res>
    implements _$BusinessCategoryCopyWith<$Res> {
  __$BusinessCategoryCopyWithImpl(this._self, this._then);

  final _BusinessCategory _self;
  final $Res Function(_BusinessCategory) _then;

/// Create a copy of BusinessCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? bucket = null,Object? slug = freezed,Object? iconName = freezed,Object? sortOrder = freezed,Object? subcategories = null,Object? businessCount = null,}) {
  return _then(_BusinessCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as String,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,subcategories: null == subcategories ? _self._subcategories : subcategories // ignore: cast_nullable_to_non_nullable
as List<Subcategory>,businessCount: null == businessCount ? _self.businessCount : businessCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
