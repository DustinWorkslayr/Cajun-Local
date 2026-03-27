// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'featured_business.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeaturedBusiness {

 String get id; String get name; String? get tagline;@JsonKey(name: 'category_id') String get categoryId;@JsonKey(name: 'category_name') String? get categoryName;@JsonKey(name: 'subcategory_name') String? get subcategoryName;@JsonKey(name: 'logo_url') String? get logoUrl; double? get rating;@JsonKey(name: 'is_open_now') bool? get isOpenNow;
/// Create a copy of FeaturedBusiness
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeaturedBusinessCopyWith<FeaturedBusiness> get copyWith => _$FeaturedBusinessCopyWithImpl<FeaturedBusiness>(this as FeaturedBusiness, _$identity);

  /// Serializes this FeaturedBusiness to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeaturedBusiness&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.subcategoryName, subcategoryName) || other.subcategoryName == subcategoryName)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.isOpenNow, isOpenNow) || other.isOpenNow == isOpenNow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,tagline,categoryId,categoryName,subcategoryName,logoUrl,rating,isOpenNow);

@override
String toString() {
  return 'FeaturedBusiness(id: $id, name: $name, tagline: $tagline, categoryId: $categoryId, categoryName: $categoryName, subcategoryName: $subcategoryName, logoUrl: $logoUrl, rating: $rating, isOpenNow: $isOpenNow)';
}


}

/// @nodoc
abstract mixin class $FeaturedBusinessCopyWith<$Res>  {
  factory $FeaturedBusinessCopyWith(FeaturedBusiness value, $Res Function(FeaturedBusiness) _then) = _$FeaturedBusinessCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? tagline,@JsonKey(name: 'category_id') String categoryId,@JsonKey(name: 'category_name') String? categoryName,@JsonKey(name: 'subcategory_name') String? subcategoryName,@JsonKey(name: 'logo_url') String? logoUrl, double? rating,@JsonKey(name: 'is_open_now') bool? isOpenNow
});




}
/// @nodoc
class _$FeaturedBusinessCopyWithImpl<$Res>
    implements $FeaturedBusinessCopyWith<$Res> {
  _$FeaturedBusinessCopyWithImpl(this._self, this._then);

  final FeaturedBusiness _self;
  final $Res Function(FeaturedBusiness) _then;

/// Create a copy of FeaturedBusiness
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? tagline = freezed,Object? categoryId = null,Object? categoryName = freezed,Object? subcategoryName = freezed,Object? logoUrl = freezed,Object? rating = freezed,Object? isOpenNow = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,subcategoryName: freezed == subcategoryName ? _self.subcategoryName : subcategoryName // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,isOpenNow: freezed == isOpenNow ? _self.isOpenNow : isOpenNow // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeaturedBusiness].
extension FeaturedBusinessPatterns on FeaturedBusiness {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeaturedBusiness value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeaturedBusiness() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeaturedBusiness value)  $default,){
final _that = this;
switch (_that) {
case _FeaturedBusiness():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeaturedBusiness value)?  $default,){
final _that = this;
switch (_that) {
case _FeaturedBusiness() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? tagline, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'category_name')  String? categoryName, @JsonKey(name: 'subcategory_name')  String? subcategoryName, @JsonKey(name: 'logo_url')  String? logoUrl,  double? rating, @JsonKey(name: 'is_open_now')  bool? isOpenNow)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeaturedBusiness() when $default != null:
return $default(_that.id,_that.name,_that.tagline,_that.categoryId,_that.categoryName,_that.subcategoryName,_that.logoUrl,_that.rating,_that.isOpenNow);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? tagline, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'category_name')  String? categoryName, @JsonKey(name: 'subcategory_name')  String? subcategoryName, @JsonKey(name: 'logo_url')  String? logoUrl,  double? rating, @JsonKey(name: 'is_open_now')  bool? isOpenNow)  $default,) {final _that = this;
switch (_that) {
case _FeaturedBusiness():
return $default(_that.id,_that.name,_that.tagline,_that.categoryId,_that.categoryName,_that.subcategoryName,_that.logoUrl,_that.rating,_that.isOpenNow);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? tagline, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'category_name')  String? categoryName, @JsonKey(name: 'subcategory_name')  String? subcategoryName, @JsonKey(name: 'logo_url')  String? logoUrl,  double? rating, @JsonKey(name: 'is_open_now')  bool? isOpenNow)?  $default,) {final _that = this;
switch (_that) {
case _FeaturedBusiness() when $default != null:
return $default(_that.id,_that.name,_that.tagline,_that.categoryId,_that.categoryName,_that.subcategoryName,_that.logoUrl,_that.rating,_that.isOpenNow);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeaturedBusiness implements FeaturedBusiness {
  const _FeaturedBusiness({required this.id, required this.name, this.tagline, @JsonKey(name: 'category_id') required this.categoryId, @JsonKey(name: 'category_name') this.categoryName, @JsonKey(name: 'subcategory_name') this.subcategoryName, @JsonKey(name: 'logo_url') this.logoUrl, this.rating, @JsonKey(name: 'is_open_now') this.isOpenNow});
  factory _FeaturedBusiness.fromJson(Map<String, dynamic> json) => _$FeaturedBusinessFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? tagline;
@override@JsonKey(name: 'category_id') final  String categoryId;
@override@JsonKey(name: 'category_name') final  String? categoryName;
@override@JsonKey(name: 'subcategory_name') final  String? subcategoryName;
@override@JsonKey(name: 'logo_url') final  String? logoUrl;
@override final  double? rating;
@override@JsonKey(name: 'is_open_now') final  bool? isOpenNow;

/// Create a copy of FeaturedBusiness
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeaturedBusinessCopyWith<_FeaturedBusiness> get copyWith => __$FeaturedBusinessCopyWithImpl<_FeaturedBusiness>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeaturedBusinessToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeaturedBusiness&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.subcategoryName, subcategoryName) || other.subcategoryName == subcategoryName)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.isOpenNow, isOpenNow) || other.isOpenNow == isOpenNow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,tagline,categoryId,categoryName,subcategoryName,logoUrl,rating,isOpenNow);

@override
String toString() {
  return 'FeaturedBusiness(id: $id, name: $name, tagline: $tagline, categoryId: $categoryId, categoryName: $categoryName, subcategoryName: $subcategoryName, logoUrl: $logoUrl, rating: $rating, isOpenNow: $isOpenNow)';
}


}

/// @nodoc
abstract mixin class _$FeaturedBusinessCopyWith<$Res> implements $FeaturedBusinessCopyWith<$Res> {
  factory _$FeaturedBusinessCopyWith(_FeaturedBusiness value, $Res Function(_FeaturedBusiness) _then) = __$FeaturedBusinessCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? tagline,@JsonKey(name: 'category_id') String categoryId,@JsonKey(name: 'category_name') String? categoryName,@JsonKey(name: 'subcategory_name') String? subcategoryName,@JsonKey(name: 'logo_url') String? logoUrl, double? rating,@JsonKey(name: 'is_open_now') bool? isOpenNow
});




}
/// @nodoc
class __$FeaturedBusinessCopyWithImpl<$Res>
    implements _$FeaturedBusinessCopyWith<$Res> {
  __$FeaturedBusinessCopyWithImpl(this._self, this._then);

  final _FeaturedBusiness _self;
  final $Res Function(_FeaturedBusiness) _then;

/// Create a copy of FeaturedBusiness
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? tagline = freezed,Object? categoryId = null,Object? categoryName = freezed,Object? subcategoryName = freezed,Object? logoUrl = freezed,Object? rating = freezed,Object? isOpenNow = freezed,}) {
  return _then(_FeaturedBusiness(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,subcategoryName: freezed == subcategoryName ? _self.subcategoryName : subcategoryName // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,isOpenNow: freezed == isOpenNow ? _self.isOpenNow : isOpenNow // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
