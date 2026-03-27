// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BusinessEvent {

 String get id;@JsonKey(name: 'business_id') String get businessId; String get title;@JsonKey(name: 'event_date') DateTime get eventDate; String? get description;@JsonKey(name: 'end_date') DateTime? get endDate; String? get location;@JsonKey(name: 'image_url') String? get imageUrl; String get status;
/// Create a copy of BusinessEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessEventCopyWith<BusinessEvent> get copyWith => _$BusinessEventCopyWithImpl<BusinessEvent>(this as BusinessEvent, _$identity);

  /// Serializes this BusinessEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.title, title) || other.title == title)&&(identical(other.eventDate, eventDate) || other.eventDate == eventDate)&&(identical(other.description, description) || other.description == description)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.location, location) || other.location == location)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,title,eventDate,description,endDate,location,imageUrl,status);

@override
String toString() {
  return 'BusinessEvent(id: $id, businessId: $businessId, title: $title, eventDate: $eventDate, description: $description, endDate: $endDate, location: $location, imageUrl: $imageUrl, status: $status)';
}


}

/// @nodoc
abstract mixin class $BusinessEventCopyWith<$Res>  {
  factory $BusinessEventCopyWith(BusinessEvent value, $Res Function(BusinessEvent) _then) = _$BusinessEventCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'business_id') String businessId, String title,@JsonKey(name: 'event_date') DateTime eventDate, String? description,@JsonKey(name: 'end_date') DateTime? endDate, String? location,@JsonKey(name: 'image_url') String? imageUrl, String status
});




}
/// @nodoc
class _$BusinessEventCopyWithImpl<$Res>
    implements $BusinessEventCopyWith<$Res> {
  _$BusinessEventCopyWithImpl(this._self, this._then);

  final BusinessEvent _self;
  final $Res Function(BusinessEvent) _then;

/// Create a copy of BusinessEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? title = null,Object? eventDate = null,Object? description = freezed,Object? endDate = freezed,Object? location = freezed,Object? imageUrl = freezed,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,eventDate: null == eventDate ? _self.eventDate : eventDate // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BusinessEvent].
extension BusinessEventPatterns on BusinessEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusinessEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusinessEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusinessEvent value)  $default,){
final _that = this;
switch (_that) {
case _BusinessEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusinessEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BusinessEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'business_id')  String businessId,  String title, @JsonKey(name: 'event_date')  DateTime eventDate,  String? description, @JsonKey(name: 'end_date')  DateTime? endDate,  String? location, @JsonKey(name: 'image_url')  String? imageUrl,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BusinessEvent() when $default != null:
return $default(_that.id,_that.businessId,_that.title,_that.eventDate,_that.description,_that.endDate,_that.location,_that.imageUrl,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'business_id')  String businessId,  String title, @JsonKey(name: 'event_date')  DateTime eventDate,  String? description, @JsonKey(name: 'end_date')  DateTime? endDate,  String? location, @JsonKey(name: 'image_url')  String? imageUrl,  String status)  $default,) {final _that = this;
switch (_that) {
case _BusinessEvent():
return $default(_that.id,_that.businessId,_that.title,_that.eventDate,_that.description,_that.endDate,_that.location,_that.imageUrl,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'business_id')  String businessId,  String title, @JsonKey(name: 'event_date')  DateTime eventDate,  String? description, @JsonKey(name: 'end_date')  DateTime? endDate,  String? location, @JsonKey(name: 'image_url')  String? imageUrl,  String status)?  $default,) {final _that = this;
switch (_that) {
case _BusinessEvent() when $default != null:
return $default(_that.id,_that.businessId,_that.title,_that.eventDate,_that.description,_that.endDate,_that.location,_that.imageUrl,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BusinessEvent implements BusinessEvent {
  const _BusinessEvent({required this.id, @JsonKey(name: 'business_id') required this.businessId, required this.title, @JsonKey(name: 'event_date') required this.eventDate, this.description, @JsonKey(name: 'end_date') this.endDate, this.location, @JsonKey(name: 'image_url') this.imageUrl, this.status = 'pending'});
  factory _BusinessEvent.fromJson(Map<String, dynamic> json) => _$BusinessEventFromJson(json);

@override final  String id;
@override@JsonKey(name: 'business_id') final  String businessId;
@override final  String title;
@override@JsonKey(name: 'event_date') final  DateTime eventDate;
@override final  String? description;
@override@JsonKey(name: 'end_date') final  DateTime? endDate;
@override final  String? location;
@override@JsonKey(name: 'image_url') final  String? imageUrl;
@override@JsonKey() final  String status;

/// Create a copy of BusinessEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessEventCopyWith<_BusinessEvent> get copyWith => __$BusinessEventCopyWithImpl<_BusinessEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusinessEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.title, title) || other.title == title)&&(identical(other.eventDate, eventDate) || other.eventDate == eventDate)&&(identical(other.description, description) || other.description == description)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.location, location) || other.location == location)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,title,eventDate,description,endDate,location,imageUrl,status);

@override
String toString() {
  return 'BusinessEvent(id: $id, businessId: $businessId, title: $title, eventDate: $eventDate, description: $description, endDate: $endDate, location: $location, imageUrl: $imageUrl, status: $status)';
}


}

/// @nodoc
abstract mixin class _$BusinessEventCopyWith<$Res> implements $BusinessEventCopyWith<$Res> {
  factory _$BusinessEventCopyWith(_BusinessEvent value, $Res Function(_BusinessEvent) _then) = __$BusinessEventCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'business_id') String businessId, String title,@JsonKey(name: 'event_date') DateTime eventDate, String? description,@JsonKey(name: 'end_date') DateTime? endDate, String? location,@JsonKey(name: 'image_url') String? imageUrl, String status
});




}
/// @nodoc
class __$BusinessEventCopyWithImpl<$Res>
    implements _$BusinessEventCopyWith<$Res> {
  __$BusinessEventCopyWithImpl(this._self, this._then);

  final _BusinessEvent _self;
  final $Res Function(_BusinessEvent) _then;

/// Create a copy of BusinessEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? title = null,Object? eventDate = null,Object? description = freezed,Object? endDate = freezed,Object? location = freezed,Object? imageUrl = freezed,Object? status = null,}) {
  return _then(_BusinessEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,eventDate: null == eventDate ? _self.eventDate : eventDate // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
