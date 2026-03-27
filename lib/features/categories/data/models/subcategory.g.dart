// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subcategory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Subcategory _$SubcategoryFromJson(Map<String, dynamic> json) => _Subcategory(
  id: json['id'] as String,
  name: json['name'] as String,
  categoryId: json['category_id'] as String,
  slug: json['slug'] as String?,
);

Map<String, dynamic> _$SubcategoryToJson(_Subcategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category_id': instance.categoryId,
      'slug': instance.slug,
    };
