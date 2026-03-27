// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomeEvent {

 String get id; String get businessId; String get businessName; String get title; DateTime get eventDate; String? get imageUrl; String? get location;
/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeEventCopyWith<HomeEvent> get copyWith => _$HomeEventCopyWithImpl<HomeEvent>(this as HomeEvent, _$identity);

  /// Serializes this HomeEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.title, title) || other.title == title)&&(identical(other.eventDate, eventDate) || other.eventDate == eventDate)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.location, location) || other.location == location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,businessName,title,eventDate,imageUrl,location);

@override
String toString() {
  return 'HomeEvent(id: $id, businessId: $businessId, businessName: $businessName, title: $title, eventDate: $eventDate, imageUrl: $imageUrl, location: $location)';
}


}

/// @nodoc
abstract mixin class $HomeEventCopyWith<$Res>  {
  factory $HomeEventCopyWith(HomeEvent value, $Res Function(HomeEvent) _then) = _$HomeEventCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String businessName, String title, DateTime eventDate, String? imageUrl, String? location
});




}
/// @nodoc
class _$HomeEventCopyWithImpl<$Res>
    implements $HomeEventCopyWith<$Res> {
  _$HomeEventCopyWithImpl(this._self, this._then);

  final HomeEvent _self;
  final $Res Function(HomeEvent) _then;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? businessName = null,Object? title = null,Object? eventDate = null,Object? imageUrl = freezed,Object? location = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,eventDate: null == eventDate ? _self.eventDate : eventDate // ignore: cast_nullable_to_non_nullable
as DateTime,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeEvent].
extension HomeEventPatterns on HomeEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeEvent value)  $default,){
final _that = this;
switch (_that) {
case _HomeEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeEvent value)?  $default,){
final _that = this;
switch (_that) {
case _HomeEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String businessName,  String title,  DateTime eventDate,  String? imageUrl,  String? location)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeEvent() when $default != null:
return $default(_that.id,_that.businessId,_that.businessName,_that.title,_that.eventDate,_that.imageUrl,_that.location);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String businessName,  String title,  DateTime eventDate,  String? imageUrl,  String? location)  $default,) {final _that = this;
switch (_that) {
case _HomeEvent():
return $default(_that.id,_that.businessId,_that.businessName,_that.title,_that.eventDate,_that.imageUrl,_that.location);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String businessName,  String title,  DateTime eventDate,  String? imageUrl,  String? location)?  $default,) {final _that = this;
switch (_that) {
case _HomeEvent() when $default != null:
return $default(_that.id,_that.businessId,_that.businessName,_that.title,_that.eventDate,_that.imageUrl,_that.location);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomeEvent implements HomeEvent {
  const _HomeEvent({required this.id, required this.businessId, required this.businessName, required this.title, required this.eventDate, this.imageUrl, this.location});
  factory _HomeEvent.fromJson(Map<String, dynamic> json) => _$HomeEventFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String businessName;
@override final  String title;
@override final  DateTime eventDate;
@override final  String? imageUrl;
@override final  String? location;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeEventCopyWith<_HomeEvent> get copyWith => __$HomeEventCopyWithImpl<_HomeEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomeEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.title, title) || other.title == title)&&(identical(other.eventDate, eventDate) || other.eventDate == eventDate)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.location, location) || other.location == location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,businessName,title,eventDate,imageUrl,location);

@override
String toString() {
  return 'HomeEvent(id: $id, businessId: $businessId, businessName: $businessName, title: $title, eventDate: $eventDate, imageUrl: $imageUrl, location: $location)';
}


}

/// @nodoc
abstract mixin class _$HomeEventCopyWith<$Res> implements $HomeEventCopyWith<$Res> {
  factory _$HomeEventCopyWith(_HomeEvent value, $Res Function(_HomeEvent) _then) = __$HomeEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String businessName, String title, DateTime eventDate, String? imageUrl, String? location
});




}
/// @nodoc
class __$HomeEventCopyWithImpl<$Res>
    implements _$HomeEventCopyWith<$Res> {
  __$HomeEventCopyWithImpl(this._self, this._then);

  final _HomeEvent _self;
  final $Res Function(_HomeEvent) _then;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? businessName = null,Object? title = null,Object? eventDate = null,Object? imageUrl = freezed,Object? location = freezed,}) {
  return _then(_HomeEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,eventDate: null == eventDate ? _self.eventDate : eventDate // ignore: cast_nullable_to_non_nullable
as DateTime,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
