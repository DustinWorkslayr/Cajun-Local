import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cajun_local/features/categories/data/models/subcategory.dart';

part 'business_category.freezed.dart';
part 'business_category.g.dart';

@freezed
abstract class BusinessCategory with _$BusinessCategory {
  const factory BusinessCategory({
    required String id,
    required String name,
    @Default('explore') String bucket,
    String? slug,
    @JsonKey(name: 'icon_name') String? iconName,
    @JsonKey(name: 'sort_order') int? sortOrder,
    @Default([]) List<Subcategory> subcategories,
    @JsonKey(name: 'business_count') @Default(0) int businessCount,
  }) = _BusinessCategory;

  factory BusinessCategory.fromJson(Map<String, dynamic> json) => _$BusinessCategoryFromJson(json);
}
