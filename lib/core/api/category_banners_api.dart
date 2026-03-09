import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/data/models/category_banner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_banners_api.g.dart';

class CategoryBannersApi {
  CategoryBannersApi(this._client);
  final ApiClient _client;

  /// Fetch category banners.
  Future<List<CategoryBanner>> list({String? status, String? categoryId, int skip = 0, int limit = 100}) async {
    try {
      final response = await _client.dio.get(
        '/category-banners/',
        queryParameters: {
          if (status != null) 'status': status,
          if (categoryId != null) 'category_id': categoryId,
          'skip': skip,
          'limit': limit,
        },
      );
      final data = response.data as List;
      return data.map((json) => CategoryBanner.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list category banners');
    }
  }

  /// Get banner by ID.
  Future<CategoryBanner?> getById(String id) async {
    try {
      final response = await _client.dio.get('/category-banners/$id');
      return CategoryBanner.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get category banner');
    }
  }

  /// Admin: insert category banner.
  Future<void> insert(Map<String, dynamic> data) async {
    try {
      await _client.dio.post('/category-banners/', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create category banner');
    }
  }

  /// Admin: update category banner.
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _client.dio.put('/category-banners/$id', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update category banner');
    }
  }

  /// Admin: delete category banner.
  Future<void> delete(String id) async {
    try {
      await _client.dio.delete('/category-banners/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete category banner');
    }
  }
}

@riverpod
CategoryBannersApi categoryBannersApi(CategoryBannersApiRef ref) {
  return CategoryBannersApi(ApiClient.instance);
}
