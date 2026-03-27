// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parish.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Parish _$ParishFromJson(Map<String, dynamic> json) => _Parish(
  id: json['id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String?,
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ParishToJson(_Parish instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'sort_order': instance.sortOrder,
};
