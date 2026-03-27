// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'listing_filters.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ListingFilters {

 String get searchQuery; String? get categoryId; Set<String>? get categoryIds; Set<String> get subcategoryIds; Set<String> get parishIds; Set<String> get amenityIds; double? get maxDistanceMiles; double? get minRating; bool get dealOnly;
/// Create a copy of ListingFilters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListingFiltersCopyWith<ListingFilters> get copyWith => _$ListingFiltersCopyWithImpl<ListingFilters>(this as ListingFilters, _$identity);

  /// Serializes this ListingFilters to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListingFilters&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&const DeepCollectionEquality().equals(other.categoryIds, categoryIds)&&const DeepCollectionEquality().equals(other.subcategoryIds, subcategoryIds)&&const DeepCollectionEquality().equals(other.parishIds, parishIds)&&const DeepCollectionEquality().equals(other.amenityIds, amenityIds)&&(identical(other.maxDistanceMiles, maxDistanceMiles) || other.maxDistanceMiles == maxDistanceMiles)&&(identical(other.minRating, minRating) || other.minRating == minRating)&&(identical(other.dealOnly, dealOnly) || other.dealOnly == dealOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,searchQuery,categoryId,const DeepCollectionEquality().hash(categoryIds),const DeepCollectionEquality().hash(subcategoryIds),const DeepCollectionEquality().hash(parishIds),const DeepCollectionEquality().hash(amenityIds),maxDistanceMiles,minRating,dealOnly);

@override
String toString() {
  return 'ListingFilters(searchQuery: $searchQuery, categoryId: $categoryId, categoryIds: $categoryIds, subcategoryIds: $subcategoryIds, parishIds: $parishIds, amenityIds: $amenityIds, maxDistanceMiles: $maxDistanceMiles, minRating: $minRating, dealOnly: $dealOnly)';
}


}

/// @nodoc
abstract mixin class $ListingFiltersCopyWith<$Res>  {
  factory $ListingFiltersCopyWith(ListingFilters value, $Res Function(ListingFilters) _then) = _$ListingFiltersCopyWithImpl;
@useResult
$Res call({
 String searchQuery, String? categoryId, Set<String>? categoryIds, Set<String> subcategoryIds, Set<String> parishIds, Set<String> amenityIds, double? maxDistanceMiles, double? minRating, bool dealOnly
});




}
/// @nodoc
class _$ListingFiltersCopyWithImpl<$Res>
    implements $ListingFiltersCopyWith<$Res> {
  _$ListingFiltersCopyWithImpl(this._self, this._then);

  final ListingFilters _self;
  final $Res Function(ListingFilters) _then;

/// Create a copy of ListingFilters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? searchQuery = null,Object? categoryId = freezed,Object? categoryIds = freezed,Object? subcategoryIds = null,Object? parishIds = null,Object? amenityIds = null,Object? maxDistanceMiles = freezed,Object? minRating = freezed,Object? dealOnly = null,}) {
  return _then(_self.copyWith(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,categoryIds: freezed == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>?,subcategoryIds: null == subcategoryIds ? _self.subcategoryIds : subcategoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>,parishIds: null == parishIds ? _self.parishIds : parishIds // ignore: cast_nullable_to_non_nullable
as Set<String>,amenityIds: null == amenityIds ? _self.amenityIds : amenityIds // ignore: cast_nullable_to_non_nullable
as Set<String>,maxDistanceMiles: freezed == maxDistanceMiles ? _self.maxDistanceMiles : maxDistanceMiles // ignore: cast_nullable_to_non_nullable
as double?,minRating: freezed == minRating ? _self.minRating : minRating // ignore: cast_nullable_to_non_nullable
as double?,dealOnly: null == dealOnly ? _self.dealOnly : dealOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ListingFilters].
extension ListingFiltersPatterns on ListingFilters {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListingFilters value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListingFilters() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListingFilters value)  $default,){
final _that = this;
switch (_that) {
case _ListingFilters():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListingFilters value)?  $default,){
final _that = this;
switch (_that) {
case _ListingFilters() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String searchQuery,  String? categoryId,  Set<String>? categoryIds,  Set<String> subcategoryIds,  Set<String> parishIds,  Set<String> amenityIds,  double? maxDistanceMiles,  double? minRating,  bool dealOnly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListingFilters() when $default != null:
return $default(_that.searchQuery,_that.categoryId,_that.categoryIds,_that.subcategoryIds,_that.parishIds,_that.amenityIds,_that.maxDistanceMiles,_that.minRating,_that.dealOnly);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String searchQuery,  String? categoryId,  Set<String>? categoryIds,  Set<String> subcategoryIds,  Set<String> parishIds,  Set<String> amenityIds,  double? maxDistanceMiles,  double? minRating,  bool dealOnly)  $default,) {final _that = this;
switch (_that) {
case _ListingFilters():
return $default(_that.searchQuery,_that.categoryId,_that.categoryIds,_that.subcategoryIds,_that.parishIds,_that.amenityIds,_that.maxDistanceMiles,_that.minRating,_that.dealOnly);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String searchQuery,  String? categoryId,  Set<String>? categoryIds,  Set<String> subcategoryIds,  Set<String> parishIds,  Set<String> amenityIds,  double? maxDistanceMiles,  double? minRating,  bool dealOnly)?  $default,) {final _that = this;
switch (_that) {
case _ListingFilters() when $default != null:
return $default(_that.searchQuery,_that.categoryId,_that.categoryIds,_that.subcategoryIds,_that.parishIds,_that.amenityIds,_that.maxDistanceMiles,_that.minRating,_that.dealOnly);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListingFilters implements ListingFilters {
  const _ListingFilters({this.searchQuery = '', this.categoryId, final  Set<String>? categoryIds, final  Set<String> subcategoryIds = const {}, final  Set<String> parishIds = const {}, final  Set<String> amenityIds = const {}, this.maxDistanceMiles, this.minRating, this.dealOnly = false}): _categoryIds = categoryIds,_subcategoryIds = subcategoryIds,_parishIds = parishIds,_amenityIds = amenityIds;
  factory _ListingFilters.fromJson(Map<String, dynamic> json) => _$ListingFiltersFromJson(json);

@override@JsonKey() final  String searchQuery;
@override final  String? categoryId;
 final  Set<String>? _categoryIds;
@override Set<String>? get categoryIds {
  final value = _categoryIds;
  if (value == null) return null;
  if (_categoryIds is EqualUnmodifiableSetView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(value);
}

 final  Set<String> _subcategoryIds;
@override@JsonKey() Set<String> get subcategoryIds {
  if (_subcategoryIds is EqualUnmodifiableSetView) return _subcategoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_subcategoryIds);
}

 final  Set<String> _parishIds;
@override@JsonKey() Set<String> get parishIds {
  if (_parishIds is EqualUnmodifiableSetView) return _parishIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_parishIds);
}

 final  Set<String> _amenityIds;
@override@JsonKey() Set<String> get amenityIds {
  if (_amenityIds is EqualUnmodifiableSetView) return _amenityIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_amenityIds);
}

@override final  double? maxDistanceMiles;
@override final  double? minRating;
@override@JsonKey() final  bool dealOnly;

/// Create a copy of ListingFilters
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListingFiltersCopyWith<_ListingFilters> get copyWith => __$ListingFiltersCopyWithImpl<_ListingFilters>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListingFiltersToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListingFilters&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&const DeepCollectionEquality().equals(other._categoryIds, _categoryIds)&&const DeepCollectionEquality().equals(other._subcategoryIds, _subcategoryIds)&&const DeepCollectionEquality().equals(other._parishIds, _parishIds)&&const DeepCollectionEquality().equals(other._amenityIds, _amenityIds)&&(identical(other.maxDistanceMiles, maxDistanceMiles) || other.maxDistanceMiles == maxDistanceMiles)&&(identical(other.minRating, minRating) || other.minRating == minRating)&&(identical(other.dealOnly, dealOnly) || other.dealOnly == dealOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,searchQuery,categoryId,const DeepCollectionEquality().hash(_categoryIds),const DeepCollectionEquality().hash(_subcategoryIds),const DeepCollectionEquality().hash(_parishIds),const DeepCollectionEquality().hash(_amenityIds),maxDistanceMiles,minRating,dealOnly);

@override
String toString() {
  return 'ListingFilters(searchQuery: $searchQuery, categoryId: $categoryId, categoryIds: $categoryIds, subcategoryIds: $subcategoryIds, parishIds: $parishIds, amenityIds: $amenityIds, maxDistanceMiles: $maxDistanceMiles, minRating: $minRating, dealOnly: $dealOnly)';
}


}

/// @nodoc
abstract mixin class _$ListingFiltersCopyWith<$Res> implements $ListingFiltersCopyWith<$Res> {
  factory _$ListingFiltersCopyWith(_ListingFilters value, $Res Function(_ListingFilters) _then) = __$ListingFiltersCopyWithImpl;
@override @useResult
$Res call({
 String searchQuery, String? categoryId, Set<String>? categoryIds, Set<String> subcategoryIds, Set<String> parishIds, Set<String> amenityIds, double? maxDistanceMiles, double? minRating, bool dealOnly
});




}
/// @nodoc
class __$ListingFiltersCopyWithImpl<$Res>
    implements _$ListingFiltersCopyWith<$Res> {
  __$ListingFiltersCopyWithImpl(this._self, this._then);

  final _ListingFilters _self;
  final $Res Function(_ListingFilters) _then;

/// Create a copy of ListingFilters
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? searchQuery = null,Object? categoryId = freezed,Object? categoryIds = freezed,Object? subcategoryIds = null,Object? parishIds = null,Object? amenityIds = null,Object? maxDistanceMiles = freezed,Object? minRating = freezed,Object? dealOnly = null,}) {
  return _then(_ListingFilters(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,categoryIds: freezed == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>?,subcategoryIds: null == subcategoryIds ? _self._subcategoryIds : subcategoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>,parishIds: null == parishIds ? _self._parishIds : parishIds // ignore: cast_nullable_to_non_nullable
as Set<String>,amenityIds: null == amenityIds ? _self._amenityIds : amenityIds // ignore: cast_nullable_to_non_nullable
as Set<String>,maxDistanceMiles: freezed == maxDistanceMiles ? _self.maxDistanceMiles : maxDistanceMiles // ignore: cast_nullable_to_non_nullable
as double?,minRating: freezed == minRating ? _self.minRating : minRating // ignore: cast_nullable_to_non_nullable
as double?,dealOnly: null == dealOnly ? _self.dealOnly : dealOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
