// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_business.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeaturedBusiness _$FeaturedBusinessFromJson(Map<String, dynamic> json) =>
    _FeaturedBusiness(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String?,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String?,
      subcategoryName: json['subcategory_name'] as String?,
      logoUrl: json['logo_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      isOpenNow: json['is_open_now'] as bool?,
    );

Map<String, dynamic> _$FeaturedBusinessToJson(_FeaturedBusiness instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tagline': instance.tagline,
      'category_id': instance.categoryId,
      'category_name': instance.categoryName,
      'subcategory_name': instance.subcategoryName,
      'logo_url': instance.logoUrl,
      'rating': instance.rating,
      'is_open_now': instance.isOpenNow,
    };
