// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_listing_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreateListingState {

 List<BusinessCategory> get categories; List<Parish> get parishes; List<Subcategory> get subcategories; bool get categoriesLoading; bool get parishesLoading; bool get subcategoriesLoading;// Form State
 BusinessCategory? get selectedCategory; Parish? get selectedParish; Set<String> get selectedSubcategoryIds; bool get agreedToPrivacy; String? get message; bool get success; bool get submitting; String? get createdBusinessId;
/// Create a copy of CreateListingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateListingStateCopyWith<CreateListingState> get copyWith => _$CreateListingStateCopyWithImpl<CreateListingState>(this as CreateListingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateListingState&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.parishes, parishes)&&const DeepCollectionEquality().equals(other.subcategories, subcategories)&&(identical(other.categoriesLoading, categoriesLoading) || other.categoriesLoading == categoriesLoading)&&(identical(other.parishesLoading, parishesLoading) || other.parishesLoading == parishesLoading)&&(identical(other.subcategoriesLoading, subcategoriesLoading) || other.subcategoriesLoading == subcategoriesLoading)&&(identical(other.selectedCategory, selectedCategory) || other.selectedCategory == selectedCategory)&&(identical(other.selectedParish, selectedParish) || other.selectedParish == selectedParish)&&const DeepCollectionEquality().equals(other.selectedSubcategoryIds, selectedSubcategoryIds)&&(identical(other.agreedToPrivacy, agreedToPrivacy) || other.agreedToPrivacy == agreedToPrivacy)&&(identical(other.message, message) || other.message == message)&&(identical(other.success, success) || other.success == success)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.createdBusinessId, createdBusinessId) || other.createdBusinessId == createdBusinessId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(parishes),const DeepCollectionEquality().hash(subcategories),categoriesLoading,parishesLoading,subcategoriesLoading,selectedCategory,selectedParish,const DeepCollectionEquality().hash(selectedSubcategoryIds),agreedToPrivacy,message,success,submitting,createdBusinessId);

@override
String toString() {
  return 'CreateListingState(categories: $categories, parishes: $parishes, subcategories: $subcategories, categoriesLoading: $categoriesLoading, parishesLoading: $parishesLoading, subcategoriesLoading: $subcategoriesLoading, selectedCategory: $selectedCategory, selectedParish: $selectedParish, selectedSubcategoryIds: $selectedSubcategoryIds, agreedToPrivacy: $agreedToPrivacy, message: $message, success: $success, submitting: $submitting, createdBusinessId: $createdBusinessId)';
}


}

/// @nodoc
abstract mixin class $CreateListingStateCopyWith<$Res>  {
  factory $CreateListingStateCopyWith(CreateListingState value, $Res Function(CreateListingState) _then) = _$CreateListingStateCopyWithImpl;
@useResult
$Res call({
 List<BusinessCategory> categories, List<Parish> parishes, List<Subcategory> subcategories, bool categoriesLoading, bool parishesLoading, bool subcategoriesLoading, BusinessCategory? selectedCategory, Parish? selectedParish, Set<String> selectedSubcategoryIds, bool agreedToPrivacy, String? message, bool success, bool submitting, String? createdBusinessId
});




}
/// @nodoc
class _$CreateListingStateCopyWithImpl<$Res>
    implements $CreateListingStateCopyWith<$Res> {
  _$CreateListingStateCopyWithImpl(this._self, this._then);

  final CreateListingState _self;
  final $Res Function(CreateListingState) _then;

/// Create a copy of CreateListingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categories = null,Object? parishes = null,Object? subcategories = null,Object? categoriesLoading = null,Object? parishesLoading = null,Object? subcategoriesLoading = null,Object? selectedCategory = freezed,Object? selectedParish = freezed,Object? selectedSubcategoryIds = null,Object? agreedToPrivacy = null,Object? message = freezed,Object? success = null,Object? submitting = null,Object? createdBusinessId = freezed,}) {
  return _then(_self.copyWith(
categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<BusinessCategory>,parishes: null == parishes ? _self.parishes : parishes // ignore: cast_nullable_to_non_nullable
as List<Parish>,subcategories: null == subcategories ? _self.subcategories : subcategories // ignore: cast_nullable_to_non_nullable
as List<Subcategory>,categoriesLoading: null == categoriesLoading ? _self.categoriesLoading : categoriesLoading // ignore: cast_nullable_to_non_nullable
as bool,parishesLoading: null == parishesLoading ? _self.parishesLoading : parishesLoading // ignore: cast_nullable_to_non_nullable
as bool,subcategoriesLoading: null == subcategoriesLoading ? _self.subcategoriesLoading : subcategoriesLoading // ignore: cast_nullable_to_non_nullable
as bool,selectedCategory: freezed == selectedCategory ? _self.selectedCategory : selectedCategory // ignore: cast_nullable_to_non_nullable
as BusinessCategory?,selectedParish: freezed == selectedParish ? _self.selectedParish : selectedParish // ignore: cast_nullable_to_non_nullable
as Parish?,selectedSubcategoryIds: null == selectedSubcategoryIds ? _self.selectedSubcategoryIds : selectedSubcategoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>,agreedToPrivacy: null == agreedToPrivacy ? _self.agreedToPrivacy : agreedToPrivacy // ignore: cast_nullable_to_non_nullable
as bool,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,createdBusinessId: freezed == createdBusinessId ? _self.createdBusinessId : createdBusinessId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateListingState].
extension CreateListingStatePatterns on CreateListingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateListingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateListingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateListingState value)  $default,){
final _that = this;
switch (_that) {
case _CreateListingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateListingState value)?  $default,){
final _that = this;
switch (_that) {
case _CreateListingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BusinessCategory> categories,  List<Parish> parishes,  List<Subcategory> subcategories,  bool categoriesLoading,  bool parishesLoading,  bool subcategoriesLoading,  BusinessCategory? selectedCategory,  Parish? selectedParish,  Set<String> selectedSubcategoryIds,  bool agreedToPrivacy,  String? message,  bool success,  bool submitting,  String? createdBusinessId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateListingState() when $default != null:
return $default(_that.categories,_that.parishes,_that.subcategories,_that.categoriesLoading,_that.parishesLoading,_that.subcategoriesLoading,_that.selectedCategory,_that.selectedParish,_that.selectedSubcategoryIds,_that.agreedToPrivacy,_that.message,_that.success,_that.submitting,_that.createdBusinessId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BusinessCategory> categories,  List<Parish> parishes,  List<Subcategory> subcategories,  bool categoriesLoading,  bool parishesLoading,  bool subcategoriesLoading,  BusinessCategory? selectedCategory,  Parish? selectedParish,  Set<String> selectedSubcategoryIds,  bool agreedToPrivacy,  String? message,  bool success,  bool submitting,  String? createdBusinessId)  $default,) {final _that = this;
switch (_that) {
case _CreateListingState():
return $default(_that.categories,_that.parishes,_that.subcategories,_that.categoriesLoading,_that.parishesLoading,_that.subcategoriesLoading,_that.selectedCategory,_that.selectedParish,_that.selectedSubcategoryIds,_that.agreedToPrivacy,_that.message,_that.success,_that.submitting,_that.createdBusinessId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BusinessCategory> categories,  List<Parish> parishes,  List<Subcategory> subcategories,  bool categoriesLoading,  bool parishesLoading,  bool subcategoriesLoading,  BusinessCategory? selectedCategory,  Parish? selectedParish,  Set<String> selectedSubcategoryIds,  bool agreedToPrivacy,  String? message,  bool success,  bool submitting,  String? createdBusinessId)?  $default,) {final _that = this;
switch (_that) {
case _CreateListingState() when $default != null:
return $default(_that.categories,_that.parishes,_that.subcategories,_that.categoriesLoading,_that.parishesLoading,_that.subcategoriesLoading,_that.selectedCategory,_that.selectedParish,_that.selectedSubcategoryIds,_that.agreedToPrivacy,_that.message,_that.success,_that.submitting,_that.createdBusinessId);case _:
  return null;

}
}

}

/// @nodoc


class _CreateListingState implements CreateListingState {
  const _CreateListingState({final  List<BusinessCategory> categories = const [], final  List<Parish> parishes = const [], final  List<Subcategory> subcategories = const [], this.categoriesLoading = true, this.parishesLoading = true, this.subcategoriesLoading = false, this.selectedCategory, this.selectedParish, final  Set<String> selectedSubcategoryIds = const {}, this.agreedToPrivacy = false, this.message, this.success = false, this.submitting = false, this.createdBusinessId}): _categories = categories,_parishes = parishes,_subcategories = subcategories,_selectedSubcategoryIds = selectedSubcategoryIds;
  

 final  List<BusinessCategory> _categories;
@override@JsonKey() List<BusinessCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<Parish> _parishes;
@override@JsonKey() List<Parish> get parishes {
  if (_parishes is EqualUnmodifiableListView) return _parishes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parishes);
}

 final  List<Subcategory> _subcategories;
@override@JsonKey() List<Subcategory> get subcategories {
  if (_subcategories is EqualUnmodifiableListView) return _subcategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subcategories);
}

@override@JsonKey() final  bool categoriesLoading;
@override@JsonKey() final  bool parishesLoading;
@override@JsonKey() final  bool subcategoriesLoading;
// Form State
@override final  BusinessCategory? selectedCategory;
@override final  Parish? selectedParish;
 final  Set<String> _selectedSubcategoryIds;
@override@JsonKey() Set<String> get selectedSubcategoryIds {
  if (_selectedSubcategoryIds is EqualUnmodifiableSetView) return _selectedSubcategoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedSubcategoryIds);
}

@override@JsonKey() final  bool agreedToPrivacy;
@override final  String? message;
@override@JsonKey() final  bool success;
@override@JsonKey() final  bool submitting;
@override final  String? createdBusinessId;

/// Create a copy of CreateListingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateListingStateCopyWith<_CreateListingState> get copyWith => __$CreateListingStateCopyWithImpl<_CreateListingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateListingState&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._parishes, _parishes)&&const DeepCollectionEquality().equals(other._subcategories, _subcategories)&&(identical(other.categoriesLoading, categoriesLoading) || other.categoriesLoading == categoriesLoading)&&(identical(other.parishesLoading, parishesLoading) || other.parishesLoading == parishesLoading)&&(identical(other.subcategoriesLoading, subcategoriesLoading) || other.subcategoriesLoading == subcategoriesLoading)&&(identical(other.selectedCategory, selectedCategory) || other.selectedCategory == selectedCategory)&&(identical(other.selectedParish, selectedParish) || other.selectedParish == selectedParish)&&const DeepCollectionEquality().equals(other._selectedSubcategoryIds, _selectedSubcategoryIds)&&(identical(other.agreedToPrivacy, agreedToPrivacy) || other.agreedToPrivacy == agreedToPrivacy)&&(identical(other.message, message) || other.message == message)&&(identical(other.success, success) || other.success == success)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.createdBusinessId, createdBusinessId) || other.createdBusinessId == createdBusinessId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_parishes),const DeepCollectionEquality().hash(_subcategories),categoriesLoading,parishesLoading,subcategoriesLoading,selectedCategory,selectedParish,const DeepCollectionEquality().hash(_selectedSubcategoryIds),agreedToPrivacy,message,success,submitting,createdBusinessId);

@override
String toString() {
  return 'CreateListingState(categories: $categories, parishes: $parishes, subcategories: $subcategories, categoriesLoading: $categoriesLoading, parishesLoading: $parishesLoading, subcategoriesLoading: $subcategoriesLoading, selectedCategory: $selectedCategory, selectedParish: $selectedParish, selectedSubcategoryIds: $selectedSubcategoryIds, agreedToPrivacy: $agreedToPrivacy, message: $message, success: $success, submitting: $submitting, createdBusinessId: $createdBusinessId)';
}


}

/// @nodoc
abstract mixin class _$CreateListingStateCopyWith<$Res> implements $CreateListingStateCopyWith<$Res> {
  factory _$CreateListingStateCopyWith(_CreateListingState value, $Res Function(_CreateListingState) _then) = __$CreateListingStateCopyWithImpl;
@override @useResult
$Res call({
 List<BusinessCategory> categories, List<Parish> parishes, List<Subcategory> subcategories, bool categoriesLoading, bool parishesLoading, bool subcategoriesLoading, BusinessCategory? selectedCategory, Parish? selectedParish, Set<String> selectedSubcategoryIds, bool agreedToPrivacy, String? message, bool success, bool submitting, String? createdBusinessId
});




}
/// @nodoc
class __$CreateListingStateCopyWithImpl<$Res>
    implements _$CreateListingStateCopyWith<$Res> {
  __$CreateListingStateCopyWithImpl(this._self, this._then);

  final _CreateListingState _self;
  final $Res Function(_CreateListingState) _then;

/// Create a copy of CreateListingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = null,Object? parishes = null,Object? subcategories = null,Object? categoriesLoading = null,Object? parishesLoading = null,Object? subcategoriesLoading = null,Object? selectedCategory = freezed,Object? selectedParish = freezed,Object? selectedSubcategoryIds = null,Object? agreedToPrivacy = null,Object? message = freezed,Object? success = null,Object? submitting = null,Object? createdBusinessId = freezed,}) {
  return _then(_CreateListingState(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<BusinessCategory>,parishes: null == parishes ? _self._parishes : parishes // ignore: cast_nullable_to_non_nullable
as List<Parish>,subcategories: null == subcategories ? _self._subcategories : subcategories // ignore: cast_nullable_to_non_nullable
as List<Subcategory>,categoriesLoading: null == categoriesLoading ? _self.categoriesLoading : categoriesLoading // ignore: cast_nullable_to_non_nullable
as bool,parishesLoading: null == parishesLoading ? _self.parishesLoading : parishesLoading // ignore: cast_nullable_to_non_nullable
as bool,subcategoriesLoading: null == subcategoriesLoading ? _self.subcategoriesLoading : subcategoriesLoading // ignore: cast_nullable_to_non_nullable
as bool,selectedCategory: freezed == selectedCategory ? _self.selectedCategory : selectedCategory // ignore: cast_nullable_to_non_nullable
as BusinessCategory?,selectedParish: freezed == selectedParish ? _self.selectedParish : selectedParish // ignore: cast_nullable_to_non_nullable
as Parish?,selectedSubcategoryIds: null == selectedSubcategoryIds ? _self._selectedSubcategoryIds : selectedSubcategoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>,agreedToPrivacy: null == agreedToPrivacy ? _self.agreedToPrivacy : agreedToPrivacy // ignore: cast_nullable_to_non_nullable
as bool,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,createdBusinessId: freezed == createdBusinessId ? _self.createdBusinessId : createdBusinessId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
