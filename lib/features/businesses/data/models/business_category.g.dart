// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BusinessCategory _$BusinessCategoryFromJson(Map<String, dynamic> json) =>
    _BusinessCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      bucket: json['bucket'] as String? ?? 'explore',
      slug: json['slug'] as String?,
      iconName: json['icon_name'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
      subcategories:
          (json['subcategories'] as List<dynamic>?)
              ?.map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      businessCount: (json['business_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BusinessCategoryToJson(_BusinessCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'bucket': instance.bucket,
      'slug': instance.slug,
      'icon_name': instance.iconName,
      'sort_order': instance.sortOrder,
      'subcategories': instance.subcategories,
      'business_count': instance.businessCount,
    };
