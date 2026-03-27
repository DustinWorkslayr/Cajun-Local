// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing_filters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ListingFilters _$ListingFiltersFromJson(
  Map<String, dynamic> json,
) => _ListingFilters(
  searchQuery: json['searchQuery'] as String? ?? '',
  categoryId: json['categoryId'] as String?,
  categoryIds: (json['categoryIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toSet(),
  subcategoryIds:
      (json['subcategoryIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const {},
  parishIds:
      (json['parishIds'] as List<dynamic>?)?.map((e) => e as String).toSet() ??
      const {},
  amenityIds:
      (json['amenityIds'] as List<dynamic>?)?.map((e) => e as String).toSet() ??
      const {},
  maxDistanceMiles: (json['maxDistanceMiles'] as num?)?.toDouble(),
  minRating: (json['minRating'] as num?)?.toDouble(),
  dealOnly: json['dealOnly'] as bool? ?? false,
);

Map<String, dynamic> _$ListingFiltersToJson(_ListingFilters instance) =>
    <String, dynamic>{
      'searchQuery': instance.searchQuery,
      'categoryId': instance.categoryId,
      'categoryIds': instance.categoryIds?.toList(),
      'subcategoryIds': instance.subcategoryIds.toList(),
      'parishIds': instance.parishIds.toList(),
      'amenityIds': instance.amenityIds.toList(),
      'maxDistanceMiles': instance.maxDistanceMiles,
      'minRating': instance.minRating,
      'dealOnly': instance.dealOnly,
    };
