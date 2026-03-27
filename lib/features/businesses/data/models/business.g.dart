// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Business _$BusinessFromJson(Map<String, dynamic> json) => _Business(
  id: json['id'] as String,
  name: json['name'] as String,
  status: json['status'] as String,
  categoryId: json['category_id'] as String,
  slug: json['slug'] as String?,
  city: json['city'] as String?,
  parish: json['parish'] as String?,
  state: json['state'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  description: json['description'] as String?,
  address: json['address'] as String?,
  phone: json['phone'] as String?,
  website: json['website'] as String?,
  tagline: json['tagline'] as String?,
  logoUrl: json['logo_url'] as String?,
  bannerUrl: json['banner_url'] as String?,
  contactFormTemplate: json['contact_form_template'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  isClaimable: json['is_claimable'] as bool?,
  isOpenNow: json['is_open_now'] as bool?,
  createdBy: json['created_by'] as String?,
);

Map<String, dynamic> _$BusinessToJson(_Business instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'status': instance.status,
  'category_id': instance.categoryId,
  'slug': instance.slug,
  'city': instance.city,
  'parish': instance.parish,
  'state': instance.state,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'description': instance.description,
  'address': instance.address,
  'phone': instance.phone,
  'website': instance.website,
  'tagline': instance.tagline,
  'logo_url': instance.logoUrl,
  'banner_url': instance.bannerUrl,
  'contact_form_template': instance.contactFormTemplate,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'is_claimable': instance.isClaimable,
  'is_open_now': instance.isOpenNow,
  'created_by': instance.createdBy,
};
