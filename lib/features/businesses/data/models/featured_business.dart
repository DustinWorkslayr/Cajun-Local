import 'package:freezed_annotation/freezed_annotation.dart';

part 'featured_business.freezed.dart';
part 'featured_business.g.dart';

@freezed
abstract class FeaturedBusiness with _$FeaturedBusiness {
  const factory FeaturedBusiness({
    required String id,
    required String name,
    String? tagline,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'category_name') String? categoryName,
    @JsonKey(name: 'subcategory_name') String? subcategoryName,
    @JsonKey(name: 'logo_url') String? logoUrl,
    double? rating,
    @JsonKey(name: 'is_open_now') bool? isOpenNow,
  }) = _FeaturedBusiness;

  factory FeaturedBusiness.fromJson(Map<String, dynamic> json) => _$FeaturedBusinessFromJson(json);
}
