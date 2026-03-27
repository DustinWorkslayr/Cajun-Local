// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BusinessEvent _$BusinessEventFromJson(Map<String, dynamic> json) =>
    _BusinessEvent(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      title: json['title'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      description: json['description'] as String?,
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      location: json['location'] as String?,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'pending',
    );

Map<String, dynamic> _$BusinessEventToJson(_BusinessEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'business_id': instance.businessId,
      'title': instance.title,
      'event_date': instance.eventDate.toIso8601String(),
      'description': instance.description,
      'end_date': instance.endDate?.toIso8601String(),
      'location': instance.location,
      'image_url': instance.imageUrl,
      'status': instance.status,
    };
