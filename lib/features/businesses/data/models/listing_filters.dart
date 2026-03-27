import 'package:freezed_annotation/freezed_annotation.dart';

part 'listing_filters.freezed.dart';
part 'listing_filters.g.dart';

@freezed
abstract class ListingFilters with _$ListingFilters {
  const factory ListingFilters({
    @Default('') String searchQuery,
    String? categoryId,
    Set<String>? categoryIds,
    @Default({}) Set<String> subcategoryIds,
    @Default({}) Set<String> parishIds,
    @Default({}) Set<String> amenityIds,
    double? maxDistanceMiles,
    double? minRating,
    @Default(false) bool dealOnly,
  }) = _ListingFilters;

  factory ListingFilters.fromJson(Map<String, dynamic> json) => _$ListingFiltersFromJson(json);
}
