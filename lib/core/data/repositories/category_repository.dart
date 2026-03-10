import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/api/category_api.dart';
import 'package:cajun_local/core/data/models/business_category.dart';
import 'package:cajun_local/core/data/models/subcategory.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_repository.g.dart';

class CategoryRepository {
  CategoryRepository({CategoryApi? api}) : _api = api ?? CategoryApi(ApiClient.instance);
  final CategoryApi _api;

  Future<List<BusinessCategory>> listCategories() async {
    return _api.listCategories();
  }

  /// Get category by id. Returns null if not found.
  Future<BusinessCategory?> getById(String categoryId) async {
    final list = await _api.listCategories();
    return list.where((c) => c.id == categoryId).firstOrNull;
  }

  Future<List<Subcategory>> listSubcategories({String? categoryId}) async {
    return _api.listSubcategories(categoryId: categoryId);
  }

  Future<List<String>> getSubcategoryIdsForBusiness(String businessId) async {
    return _api.getSubcategoryIdsForBusiness(businessId);
  }

  /// Resolve category by name (case-insensitive match). Returns null if not found.
  Future<BusinessCategory?> getCategoryByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final list = await listCategories();
    return list.where((c) => c.name.trim().toLowerCase() == trimmed.toLowerCase()).firstOrNull;
  }

  /// Resolve comma-separated subcategory names to IDs for the given category.
  Future<List<String>> resolveSubcategoryIdsByNames(String categoryId, String commaSeparatedNames) async {
    if (commaSeparatedNames.trim().isEmpty) return [];
    final names = commaSeparatedNames
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (names.isEmpty) return [];
    final subcategories = await listSubcategories(categoryId: categoryId);
    final ids = <String>[];
    for (final n in names) {
      final sub = subcategories.where((s) => s.name.trim().toLowerCase() == n).firstOrNull;
      if (sub != null) ids.add(sub.id);
    }
    return ids;
  }

  /// Admin: create category.
  Future<void> insertCategory(Map<String, dynamic> data) async {
    await _api.insertCategory(data);
  }

  /// Admin: update category.
  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _api.updateCategory(id, data);
  }

  /// Admin: delete category.
  Future<void> deleteCategory(String id) async {
    await _api.deleteCategory(id);
  }

  /// Admin: create subcategory.
  Future<void> insertSubcategory(Map<String, dynamic> data) async {
    await _api.insertSubcategory(data);
  }

  /// Admin: update subcategory.
  Future<void> updateSubcategory(String id, Map<String, dynamic> data) async {
    await _api.updateSubcategory(id, data);
  }

  Future<void> deleteSubcategory(String id) async {
    await _api.deleteSubcategory(id);
  }
}

@riverpod
CategoryRepository categoryRepository(CategoryRepositoryRef ref) {
  return CategoryRepository(api: ref.watch(categoryApiProvider));
}
