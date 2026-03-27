// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Business {

 String get id; String get name; String get status;@JsonKey(name: 'category_id') String get categoryId; String? get slug; String? get city; String? get parish; String? get state; double? get latitude; double? get longitude; String? get description; String? get address; String? get phone; String? get website; String? get tagline;@JsonKey(name: 'logo_url') String? get logoUrl;@JsonKey(name: 'banner_url') String? get bannerUrl;@JsonKey(name: 'contact_form_template') String? get contactFormTemplate;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'is_claimable') bool? get isClaimable;@JsonKey(name: 'is_open_now') bool? get isOpenNow;@JsonKey(name: 'created_by') String? get createdBy;
/// Create a copy of Business
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessCopyWith<Business> get copyWith => _$BusinessCopyWithImpl<Business>(this as Business, _$identity);

  /// Serializes this Business to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Business&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.city, city) || other.city == city)&&(identical(other.parish, parish) || other.parish == parish)&&(identical(other.state, state) || other.state == state)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.description, description) || other.description == description)&&(identical(other.address, address) || other.address == address)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.website, website) || other.website == website)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.bannerUrl, bannerUrl) || other.bannerUrl == bannerUrl)&&(identical(other.contactFormTemplate, contactFormTemplate) || other.contactFormTemplate == contactFormTemplate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isClaimable, isClaimable) || other.isClaimable == isClaimable)&&(identical(other.isOpenNow, isOpenNow) || other.isOpenNow == isOpenNow)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,status,categoryId,slug,city,parish,state,latitude,longitude,description,address,phone,website,tagline,logoUrl,bannerUrl,contactFormTemplate,createdAt,updatedAt,isClaimable,isOpenNow,createdBy]);

@override
String toString() {
  return 'Business(id: $id, name: $name, status: $status, categoryId: $categoryId, slug: $slug, city: $city, parish: $parish, state: $state, latitude: $latitude, longitude: $longitude, description: $description, address: $address, phone: $phone, website: $website, tagline: $tagline, logoUrl: $logoUrl, bannerUrl: $bannerUrl, contactFormTemplate: $contactFormTemplate, createdAt: $createdAt, updatedAt: $updatedAt, isClaimable: $isClaimable, isOpenNow: $isOpenNow, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $BusinessCopyWith<$Res>  {
  factory $BusinessCopyWith(Business value, $Res Function(Business) _then) = _$BusinessCopyWithImpl;
@useResult
$Res call({
 String id, String name, String status,@JsonKey(name: 'category_id') String categoryId, String? slug, String? city, String? parish, String? state, double? latitude, double? longitude, String? description, String? address, String? phone, String? website, String? tagline,@JsonKey(name: 'logo_url') String? logoUrl,@JsonKey(name: 'banner_url') String? bannerUrl,@JsonKey(name: 'contact_form_template') String? contactFormTemplate,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'is_claimable') bool? isClaimable,@JsonKey(name: 'is_open_now') bool? isOpenNow,@JsonKey(name: 'created_by') String? createdBy
});




}
/// @nodoc
class _$BusinessCopyWithImpl<$Res>
    implements $BusinessCopyWith<$Res> {
  _$BusinessCopyWithImpl(this._self, this._then);

  final Business _self;
  final $Res Function(Business) _then;

/// Create a copy of Business
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? status = null,Object? categoryId = null,Object? slug = freezed,Object? city = freezed,Object? parish = freezed,Object? state = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? description = freezed,Object? address = freezed,Object? phone = freezed,Object? website = freezed,Object? tagline = freezed,Object? logoUrl = freezed,Object? bannerUrl = freezed,Object? contactFormTemplate = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? isClaimable = freezed,Object? isOpenNow = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,parish: freezed == parish ? _self.parish : parish // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,bannerUrl: freezed == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String?,contactFormTemplate: freezed == contactFormTemplate ? _self.contactFormTemplate : contactFormTemplate // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isClaimable: freezed == isClaimable ? _self.isClaimable : isClaimable // ignore: cast_nullable_to_non_nullable
as bool?,isOpenNow: freezed == isOpenNow ? _self.isOpenNow : isOpenNow // ignore: cast_nullable_to_non_nullable
as bool?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Business].
extension BusinessPatterns on Business {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Business value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Business() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Business value)  $default,){
final _that = this;
switch (_that) {
case _Business():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Business value)?  $default,){
final _that = this;
switch (_that) {
case _Business() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String status, @JsonKey(name: 'category_id')  String categoryId,  String? slug,  String? city,  String? parish,  String? state,  double? latitude,  double? longitude,  String? description,  String? address,  String? phone,  String? website,  String? tagline, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'banner_url')  String? bannerUrl, @JsonKey(name: 'contact_form_template')  String? contactFormTemplate, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'is_claimable')  bool? isClaimable, @JsonKey(name: 'is_open_now')  bool? isOpenNow, @JsonKey(name: 'created_by')  String? createdBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Business() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.categoryId,_that.slug,_that.city,_that.parish,_that.state,_that.latitude,_that.longitude,_that.description,_that.address,_that.phone,_that.website,_that.tagline,_that.logoUrl,_that.bannerUrl,_that.contactFormTemplate,_that.createdAt,_that.updatedAt,_that.isClaimable,_that.isOpenNow,_that.createdBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String status, @JsonKey(name: 'category_id')  String categoryId,  String? slug,  String? city,  String? parish,  String? state,  double? latitude,  double? longitude,  String? description,  String? address,  String? phone,  String? website,  String? tagline, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'banner_url')  String? bannerUrl, @JsonKey(name: 'contact_form_template')  String? contactFormTemplate, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'is_claimable')  bool? isClaimable, @JsonKey(name: 'is_open_now')  bool? isOpenNow, @JsonKey(name: 'created_by')  String? createdBy)  $default,) {final _that = this;
switch (_that) {
case _Business():
return $default(_that.id,_that.name,_that.status,_that.categoryId,_that.slug,_that.city,_that.parish,_that.state,_that.latitude,_that.longitude,_that.description,_that.address,_that.phone,_that.website,_that.tagline,_that.logoUrl,_that.bannerUrl,_that.contactFormTemplate,_that.createdAt,_that.updatedAt,_that.isClaimable,_that.isOpenNow,_that.createdBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String status, @JsonKey(name: 'category_id')  String categoryId,  String? slug,  String? city,  String? parish,  String? state,  double? latitude,  double? longitude,  String? description,  String? address,  String? phone,  String? website,  String? tagline, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'banner_url')  String? bannerUrl, @JsonKey(name: 'contact_form_template')  String? contactFormTemplate, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'is_claimable')  bool? isClaimable, @JsonKey(name: 'is_open_now')  bool? isOpenNow, @JsonKey(name: 'created_by')  String? createdBy)?  $default,) {final _that = this;
switch (_that) {
case _Business() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.categoryId,_that.slug,_that.city,_that.parish,_that.state,_that.latitude,_that.longitude,_that.description,_that.address,_that.phone,_that.website,_that.tagline,_that.logoUrl,_that.bannerUrl,_that.contactFormTemplate,_that.createdAt,_that.updatedAt,_that.isClaimable,_that.isOpenNow,_that.createdBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Business implements Business {
  const _Business({required this.id, required this.name, required this.status, @JsonKey(name: 'category_id') required this.categoryId, this.slug, this.city, this.parish, this.state, this.latitude, this.longitude, this.description, this.address, this.phone, this.website, this.tagline, @JsonKey(name: 'logo_url') this.logoUrl, @JsonKey(name: 'banner_url') this.bannerUrl, @JsonKey(name: 'contact_form_template') this.contactFormTemplate, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'is_claimable') this.isClaimable, @JsonKey(name: 'is_open_now') this.isOpenNow, @JsonKey(name: 'created_by') this.createdBy});
  factory _Business.fromJson(Map<String, dynamic> json) => _$BusinessFromJson(json);

@override final  String id;
@override final  String name;
@override final  String status;
@override@JsonKey(name: 'category_id') final  String categoryId;
@override final  String? slug;
@override final  String? city;
@override final  String? parish;
@override final  String? state;
@override final  double? latitude;
@override final  double? longitude;
@override final  String? description;
@override final  String? address;
@override final  String? phone;
@override final  String? website;
@override final  String? tagline;
@override@JsonKey(name: 'logo_url') final  String? logoUrl;
@override@JsonKey(name: 'banner_url') final  String? bannerUrl;
@override@JsonKey(name: 'contact_form_template') final  String? contactFormTemplate;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'is_claimable') final  bool? isClaimable;
@override@JsonKey(name: 'is_open_now') final  bool? isOpenNow;
@override@JsonKey(name: 'created_by') final  String? createdBy;

/// Create a copy of Business
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessCopyWith<_Business> get copyWith => __$BusinessCopyWithImpl<_Business>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusinessToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Business&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.city, city) || other.city == city)&&(identical(other.parish, parish) || other.parish == parish)&&(identical(other.state, state) || other.state == state)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.description, description) || other.description == description)&&(identical(other.address, address) || other.address == address)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.website, website) || other.website == website)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.bannerUrl, bannerUrl) || other.bannerUrl == bannerUrl)&&(identical(other.contactFormTemplate, contactFormTemplate) || other.contactFormTemplate == contactFormTemplate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isClaimable, isClaimable) || other.isClaimable == isClaimable)&&(identical(other.isOpenNow, isOpenNow) || other.isOpenNow == isOpenNow)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,status,categoryId,slug,city,parish,state,latitude,longitude,description,address,phone,website,tagline,logoUrl,bannerUrl,contactFormTemplate,createdAt,updatedAt,isClaimable,isOpenNow,createdBy]);

@override
String toString() {
  return 'Business(id: $id, name: $name, status: $status, categoryId: $categoryId, slug: $slug, city: $city, parish: $parish, state: $state, latitude: $latitude, longitude: $longitude, description: $description, address: $address, phone: $phone, website: $website, tagline: $tagline, logoUrl: $logoUrl, bannerUrl: $bannerUrl, contactFormTemplate: $contactFormTemplate, createdAt: $createdAt, updatedAt: $updatedAt, isClaimable: $isClaimable, isOpenNow: $isOpenNow, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$BusinessCopyWith<$Res> implements $BusinessCopyWith<$Res> {
  factory _$BusinessCopyWith(_Business value, $Res Function(_Business) _then) = __$BusinessCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String status,@JsonKey(name: 'category_id') String categoryId, String? slug, String? city, String? parish, String? state, double? latitude, double? longitude, String? description, String? address, String? phone, String? website, String? tagline,@JsonKey(name: 'logo_url') String? logoUrl,@JsonKey(name: 'banner_url') String? bannerUrl,@JsonKey(name: 'contact_form_template') String? contactFormTemplate,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'is_claimable') bool? isClaimable,@JsonKey(name: 'is_open_now') bool? isOpenNow,@JsonKey(name: 'created_by') String? createdBy
});




}
/// @nodoc
class __$BusinessCopyWithImpl<$Res>
    implements _$BusinessCopyWith<$Res> {
  __$BusinessCopyWithImpl(this._self, this._then);

  final _Business _self;
  final $Res Function(_Business) _then;

/// Create a copy of Business
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? status = null,Object? categoryId = null,Object? slug = freezed,Object? city = freezed,Object? parish = freezed,Object? state = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? description = freezed,Object? address = freezed,Object? phone = freezed,Object? website = freezed,Object? tagline = freezed,Object? logoUrl = freezed,Object? bannerUrl = freezed,Object? contactFormTemplate = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? isClaimable = freezed,Object? isOpenNow = freezed,Object? createdBy = freezed,}) {
  return _then(_Business(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,parish: freezed == parish ? _self.parish : parish // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,bannerUrl: freezed == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String?,contactFormTemplate: freezed == contactFormTemplate ? _self.contactFormTemplate : contactFormTemplate // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isClaimable: freezed == isClaimable ? _self.isClaimable : isClaimable // ignore: cast_nullable_to_non_nullable
as bool?,isOpenNow: freezed == isOpenNow ? _self.isOpenNow : isOpenNow // ignore: cast_nullable_to_non_nullable
as bool?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
