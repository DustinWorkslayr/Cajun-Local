import 'package:freezed_annotation/freezed_annotation.dart';

part 'business.freezed.dart';
part 'business.g.dart';

@freezed
abstract class Business with _$Business {
  const factory Business({
    required String id,
    required String name,
    required String status,
    @JsonKey(name: 'category_id') required String categoryId,
    String? slug,
    String? city,
    String? parish,
    String? state,
    double? latitude,
    double? longitude,
    String? description,
    String? address,
    String? phone,
    String? website,
    String? tagline,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'banner_url') String? bannerUrl,
    @JsonKey(name: 'contact_form_template') String? contactFormTemplate,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'is_claimable') bool? isClaimable,
    @JsonKey(name: 'is_open_now') bool? isOpenNow,
    @JsonKey(name: 'created_by') String? createdBy,
  }) = _Business;

  factory Business.fromJson(Map<String, dynamic> json) => _$BusinessFromJson(json);
}
