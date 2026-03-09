import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/data/models/business_category.dart';
import 'package:my_app/core/data/models/subcategory.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_api.g.dart';

class CategoryApi {
  CategoryApi(this._client);
  final ApiClient _client;

  /// Fetch all categories with their subcategories.
  Future<List<BusinessCategory>> listCategories() async {
    try {
      final response = await _client.dio.get('/categories/');
      final data = response.data as List;
      return data.map((json) => BusinessCategory.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list categories');
    }
  }

  /// Get subcategories for a specific category or all subcategories.
  Future<List<Subcategory>> listSubcategories({String? categoryId}) async {
    final categories = await listCategories();
    if (categoryId != null) {
      final cat = categories.where((c) => c.id == categoryId).firstOrNull;
      return cat?.subcategories ?? [];
    }
    // Return all subcategories flat
    return categories.expand((c) => c.subcategories).toList();
  }

  /// Admin: insert category.
  Future<void> insertCategory(Map<String, dynamic> data) async {
    try {
      await _client.dio.post('/categories/', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to insert category');
    }
  }

  /// Admin: update category.
  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      await _client.dio.put('/categories/$id', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update category');
    }
  }

  /// Admin: delete category.
  Future<void> deleteCategory(String id) async {
    try {
      await _client.dio.delete('/categories/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete category');
    }
  }

  /// Admin: insert subcategory.
  Future<void> insertSubcategory(Map<String, dynamic> data) async {
    try {
      await _client.dio.post('/categories/subcategories', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to insert subcategory');
    }
  }

  /// Admin: update subcategory.
  Future<void> updateSubcategory(String id, Map<String, dynamic> data) async {
    try {
      await _client.dio.put('/categories/subcategories/$id', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update subcategory');
    }
  }

  /// Admin: delete subcategory.
  Future<void> deleteSubcategory(String id) async {
    try {
      await _client.dio.delete('/categories/subcategories/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete subcategory');
    }
  }

  /// Get subcategory IDs for a specific business.
  Future<List<String>> getSubcategoryIdsForBusiness(String businessId) async {
    try {
      final response = await _client.dio.get('/businesses/$businessId/subcategories');
      final data = response.data as List;
      return data.cast<String>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get business subcategories');
    }
  }
}

@riverpod
CategoryApi categoryApi(CategoryApiRef ref) {
  return CategoryApi(ApiClient.instance);
}
