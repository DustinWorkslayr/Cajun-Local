import 'package:freezed_annotation/freezed_annotation.dart';

part 'subcategory.freezed.dart';
part 'subcategory.g.dart';

@freezed
abstract class Subcategory with _$Subcategory {
  const factory Subcategory({
    required String id,
    required String name,
    @JsonKey(name: 'category_id') required String categoryId,
    String? slug,
  }) = _Subcategory;

  factory Subcategory.fromJson(Map<String, dynamic> json) => _$SubcategoryFromJson(json);
}
