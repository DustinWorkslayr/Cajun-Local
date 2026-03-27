// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'details_tab_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DetailsTabState {

 List<BusinessCategory> get categories; List<Parish> get parishes; List<String> get initialSubcategoryIds; List<BusinessImage> get galleryImages; bool get galleryLoading; bool get uploadingGallery; bool get saving; String? get error; bool get success; Business? get businessRaw;
/// Create a copy of DetailsTabState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetailsTabStateCopyWith<DetailsTabState> get copyWith => _$DetailsTabStateCopyWithImpl<DetailsTabState>(this as DetailsTabState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetailsTabState&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.parishes, parishes)&&const DeepCollectionEquality().equals(other.initialSubcategoryIds, initialSubcategoryIds)&&const DeepCollectionEquality().equals(other.galleryImages, galleryImages)&&(identical(other.galleryLoading, galleryLoading) || other.galleryLoading == galleryLoading)&&(identical(other.uploadingGallery, uploadingGallery) || other.uploadingGallery == uploadingGallery)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.error, error) || other.error == error)&&(identical(other.success, success) || other.success == success)&&(identical(other.businessRaw, businessRaw) || other.businessRaw == businessRaw));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(parishes),const DeepCollectionEquality().hash(initialSubcategoryIds),const DeepCollectionEquality().hash(galleryImages),galleryLoading,uploadingGallery,saving,error,success,businessRaw);

@override
String toString() {
  return 'DetailsTabState(categories: $categories, parishes: $parishes, initialSubcategoryIds: $initialSubcategoryIds, galleryImages: $galleryImages, galleryLoading: $galleryLoading, uploadingGallery: $uploadingGallery, saving: $saving, error: $error, success: $success, businessRaw: $businessRaw)';
}


}

/// @nodoc
abstract mixin class $DetailsTabStateCopyWith<$Res>  {
  factory $DetailsTabStateCopyWith(DetailsTabState value, $Res Function(DetailsTabState) _then) = _$DetailsTabStateCopyWithImpl;
@useResult
$Res call({
 List<BusinessCategory> categories, List<Parish> parishes, List<String> initialSubcategoryIds, List<BusinessImage> galleryImages, bool galleryLoading, bool uploadingGallery, bool saving, String? error, bool success, Business? businessRaw
});


$BusinessCopyWith<$Res>? get businessRaw;

}
/// @nodoc
class _$DetailsTabStateCopyWithImpl<$Res>
    implements $DetailsTabStateCopyWith<$Res> {
  _$DetailsTabStateCopyWithImpl(this._self, this._then);

  final DetailsTabState _self;
  final $Res Function(DetailsTabState) _then;

/// Create a copy of DetailsTabState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categories = null,Object? parishes = null,Object? initialSubcategoryIds = null,Object? galleryImages = null,Object? galleryLoading = null,Object? uploadingGallery = null,Object? saving = null,Object? error = freezed,Object? success = null,Object? businessRaw = freezed,}) {
  return _then(_self.copyWith(
categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<BusinessCategory>,parishes: null == parishes ? _self.parishes : parishes // ignore: cast_nullable_to_non_nullable
as List<Parish>,initialSubcategoryIds: null == initialSubcategoryIds ? _self.initialSubcategoryIds : initialSubcategoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,galleryImages: null == galleryImages ? _self.galleryImages : galleryImages // ignore: cast_nullable_to_non_nullable
as List<BusinessImage>,galleryLoading: null == galleryLoading ? _self.galleryLoading : galleryLoading // ignore: cast_nullable_to_non_nullable
as bool,uploadingGallery: null == uploadingGallery ? _self.uploadingGallery : uploadingGallery // ignore: cast_nullable_to_non_nullable
as bool,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,businessRaw: freezed == businessRaw ? _self.businessRaw : businessRaw // ignore: cast_nullable_to_non_nullable
as Business?,
  ));
}
/// Create a copy of DetailsTabState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BusinessCopyWith<$Res>? get businessRaw {
    if (_self.businessRaw == null) {
    return null;
  }

  return $BusinessCopyWith<$Res>(_self.businessRaw!, (value) {
    return _then(_self.copyWith(businessRaw: value));
  });
}
}


/// Adds pattern-matching-related methods to [DetailsTabState].
extension DetailsTabStatePatterns on DetailsTabState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DetailsTabState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DetailsTabState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DetailsTabState value)  $default,){
final _that = this;
switch (_that) {
case _DetailsTabState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DetailsTabState value)?  $default,){
final _that = this;
switch (_that) {
case _DetailsTabState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BusinessCategory> categories,  List<Parish> parishes,  List<String> initialSubcategoryIds,  List<BusinessImage> galleryImages,  bool galleryLoading,  bool uploadingGallery,  bool saving,  String? error,  bool success,  Business? businessRaw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DetailsTabState() when $default != null:
return $default(_that.categories,_that.parishes,_that.initialSubcategoryIds,_that.galleryImages,_that.galleryLoading,_that.uploadingGallery,_that.saving,_that.error,_that.success,_that.businessRaw);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BusinessCategory> categories,  List<Parish> parishes,  List<String> initialSubcategoryIds,  List<BusinessImage> galleryImages,  bool galleryLoading,  bool uploadingGallery,  bool saving,  String? error,  bool success,  Business? businessRaw)  $default,) {final _that = this;
switch (_that) {
case _DetailsTabState():
return $default(_that.categories,_that.parishes,_that.initialSubcategoryIds,_that.galleryImages,_that.galleryLoading,_that.uploadingGallery,_that.saving,_that.error,_that.success,_that.businessRaw);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BusinessCategory> categories,  List<Parish> parishes,  List<String> initialSubcategoryIds,  List<BusinessImage> galleryImages,  bool galleryLoading,  bool uploadingGallery,  bool saving,  String? error,  bool success,  Business? businessRaw)?  $default,) {final _that = this;
switch (_that) {
case _DetailsTabState() when $default != null:
return $default(_that.categories,_that.parishes,_that.initialSubcategoryIds,_that.galleryImages,_that.galleryLoading,_that.uploadingGallery,_that.saving,_that.error,_that.success,_that.businessRaw);case _:
  return null;

}
}

}

/// @nodoc


class _DetailsTabState implements DetailsTabState {
  const _DetailsTabState({final  List<BusinessCategory> categories = const [], final  List<Parish> parishes = const [], final  List<String> initialSubcategoryIds = const [], final  List<BusinessImage> galleryImages = const [], this.galleryLoading = false, this.uploadingGallery = false, this.saving = false, this.error, this.success = false, this.businessRaw}): _categories = categories,_parishes = parishes,_initialSubcategoryIds = initialSubcategoryIds,_galleryImages = galleryImages;
  

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

 final  List<String> _initialSubcategoryIds;
@override@JsonKey() List<String> get initialSubcategoryIds {
  if (_initialSubcategoryIds is EqualUnmodifiableListView) return _initialSubcategoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_initialSubcategoryIds);
}

 final  List<BusinessImage> _galleryImages;
@override@JsonKey() List<BusinessImage> get galleryImages {
  if (_galleryImages is EqualUnmodifiableListView) return _galleryImages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_galleryImages);
}

@override@JsonKey() final  bool galleryLoading;
@override@JsonKey() final  bool uploadingGallery;
@override@JsonKey() final  bool saving;
@override final  String? error;
@override@JsonKey() final  bool success;
@override final  Business? businessRaw;

/// Create a copy of DetailsTabState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DetailsTabStateCopyWith<_DetailsTabState> get copyWith => __$DetailsTabStateCopyWithImpl<_DetailsTabState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DetailsTabState&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._parishes, _parishes)&&const DeepCollectionEquality().equals(other._initialSubcategoryIds, _initialSubcategoryIds)&&const DeepCollectionEquality().equals(other._galleryImages, _galleryImages)&&(identical(other.galleryLoading, galleryLoading) || other.galleryLoading == galleryLoading)&&(identical(other.uploadingGallery, uploadingGallery) || other.uploadingGallery == uploadingGallery)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.error, error) || other.error == error)&&(identical(other.success, success) || other.success == success)&&(identical(other.businessRaw, businessRaw) || other.businessRaw == businessRaw));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_parishes),const DeepCollectionEquality().hash(_initialSubcategoryIds),const DeepCollectionEquality().hash(_galleryImages),galleryLoading,uploadingGallery,saving,error,success,businessRaw);

@override
String toString() {
  return 'DetailsTabState(categories: $categories, parishes: $parishes, initialSubcategoryIds: $initialSubcategoryIds, galleryImages: $galleryImages, galleryLoading: $galleryLoading, uploadingGallery: $uploadingGallery, saving: $saving, error: $error, success: $success, businessRaw: $businessRaw)';
}


}

/// @nodoc
abstract mixin class _$DetailsTabStateCopyWith<$Res> implements $DetailsTabStateCopyWith<$Res> {
  factory _$DetailsTabStateCopyWith(_DetailsTabState value, $Res Function(_DetailsTabState) _then) = __$DetailsTabStateCopyWithImpl;
@override @useResult
$Res call({
 List<BusinessCategory> categories, List<Parish> parishes, List<String> initialSubcategoryIds, List<BusinessImage> galleryImages, bool galleryLoading, bool uploadingGallery, bool saving, String? error, bool success, Business? businessRaw
});


@override $BusinessCopyWith<$Res>? get businessRaw;

}
/// @nodoc
class __$DetailsTabStateCopyWithImpl<$Res>
    implements _$DetailsTabStateCopyWith<$Res> {
  __$DetailsTabStateCopyWithImpl(this._self, this._then);

  final _DetailsTabState _self;
  final $Res Function(_DetailsTabState) _then;

/// Create a copy of DetailsTabState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = null,Object? parishes = null,Object? initialSubcategoryIds = null,Object? galleryImages = null,Object? galleryLoading = null,Object? uploadingGallery = null,Object? saving = null,Object? error = freezed,Object? success = null,Object? businessRaw = freezed,}) {
  return _then(_DetailsTabState(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<BusinessCategory>,parishes: null == parishes ? _self._parishes : parishes // ignore: cast_nullable_to_non_nullable
as List<Parish>,initialSubcategoryIds: null == initialSubcategoryIds ? _self._initialSubcategoryIds : initialSubcategoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,galleryImages: null == galleryImages ? _self._galleryImages : galleryImages // ignore: cast_nullable_to_non_nullable
as List<BusinessImage>,galleryLoading: null == galleryLoading ? _self.galleryLoading : galleryLoading // ignore: cast_nullable_to_non_nullable
as bool,uploadingGallery: null == uploadingGallery ? _self.uploadingGallery : uploadingGallery // ignore: cast_nullable_to_non_nullable
as bool,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,businessRaw: freezed == businessRaw ? _self.businessRaw : businessRaw // ignore: cast_nullable_to_non_nullable
as Business?,
  ));
}

/// Create a copy of DetailsTabState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BusinessCopyWith<$Res>? get businessRaw {
    if (_self.businessRaw == null) {
    return null;
  }

  return $BusinessCopyWith<$Res>(_self.businessRaw!, (value) {
    return _then(_self.copyWith(businessRaw: value));
  });
}
}

// dart format on
