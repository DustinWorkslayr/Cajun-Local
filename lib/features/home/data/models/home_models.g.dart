// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomeEvent _$HomeEventFromJson(Map<String, dynamic> json) => _HomeEvent(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  businessName: json['businessName'] as String,
  title: json['title'] as String,
  eventDate: DateTime.parse(json['eventDate'] as String),
  imageUrl: json['imageUrl'] as String?,
  location: json['location'] as String?,
);

Map<String, dynamic> _$HomeEventToJson(_HomeEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'businessName': instance.businessName,
      'title': instance.title,
      'eventDate': instance.eventDate.toIso8601String(),
      'imageUrl': instance.imageUrl,
      'location': instance.location,
    };
