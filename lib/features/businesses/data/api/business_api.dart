import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/models/featured_business.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_api.g.dart';

class BusinessApi {
  BusinessApi(this._client);
  final ApiClient _client;

  /// Fetch approved businesses with filters.
  Future<List<Business>> listApproved({
    String? categoryId,
    Set<String>? parishIds,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client.dio.get(
        '/businesses/',
        queryParameters: {
          'status': 'approved',
          if (categoryId != null) 'category_id': categoryId,
          if (parishIds != null && parishIds.isNotEmpty)
            'parish_id': parishIds.first, // FastAPI schema currently takes single parish_id
          'skip': offset,
          'limit': limit,
        },
      );
      final data = response.data as List;
      return data.map((json) => Business.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list businesses');
    }
  }

  /// Get total count of approved businesses.
  /// Note: Our current FastAPI implementation returns the list.
  /// We might need a separate count endpoint or extract it from headers if implemented.
  /// For now, we'll return the length of the filtered list (not ideal for large datasets).
  Future<int> listApprovedCount({String? categoryId, Set<String>? parishIds}) async {
    final list = await listApproved(categoryId: categoryId, parishIds: parishIds, limit: 1000);
    return list.length;
  }

  /// Get business by ID.
  Future<Business?> getById(String id) async {
    try {
      final response = await _client.dio.get('/businesses/$id');
      if (response.statusCode == 404) return null;
      return Business.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get business');
    }
  }

  /// Update business status (Admin only).
  Future<void> updateStatus(String id, String status) async {
    try {
      await _client.dio.patch('/businesses/$id/status', data: {'status': status});
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update status');
    }
  }

  /// Insert business (Admin).
  Future<String> insertBusiness(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/businesses/', data: data);
      return response.data['id'] as String;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to insert business');
    }
  }

  /// Update business profile (Admin/Manager).
  Future<void> updateBusiness(String id, Map<String, dynamic> data) async {
    try {
      await _client.dio.put('/businesses/$id', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update business');
    }
  }

  /// Get operating hours for a business.
  Future<List<Map<String, dynamic>>> getHours(String businessId) async {
    try {
      final response = await _client.dio.get('/businesses/$businessId/hours');
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get business hours');
    }
  }

  /// Update operating hours for a business.
  Future<void> updateHours(String businessId, List<Map<String, dynamic>> hours) async {
    try {
      await _client.dio.put('/businesses/$businessId/hours', data: hours);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update business hours');
    }
  }

  /// Admin: list all businesses with filters.
  Future<List<Business>> listBusinesses({String? status, String? search, int limit = 50, int offset = 0}) async {
    try {
      final response = await _client.dio.get(
        '/businesses/',
        queryParameters: {
          if (status != null) 'status': status,
          if (search != null) 'search': search,
          'skip': offset,
          'limit': limit,
        },
      );
      final data = response.data as List;
      return data.map((json) => Business.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list businesses for admin');
    }
  }

  /// Admin: delete business.
  Future<void> deleteBusiness(String id) async {
    try {
      await _client.dio.delete('/businesses/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete business');
    }
  }

  /// Get parish IDs for a business.
  Future<List<String>> getBusinessParishIds(String businessId) async {
    try {
      final response = await _client.dio.get('/businesses/$businessId/parishes');
      final data = response.data as List;
      return data.cast<String>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get business parishes');
    }
  }

  /// Set parish IDs for a business.
  Future<void> setBusinessParishes(String businessId, List<String> parishIds) async {
    try {
      await _client.dio.post('/businesses/$businessId/parishes', data: parishIds);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to set business parishes');
    }
  }

  /// Get subcategory IDs for a business.
  Future<List<String>> getBusinessSubcategoryIds(String businessId) async {
    try {
      final response = await _client.dio.get('/businesses/$businessId/subcategories');
      final data = response.data as List;
      return data.cast<String>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get business subcategories');
    }
  }

  /// Set subcategory IDs for a business.
  Future<void> setBusinessSubcategories(String businessId, List<String> subcategoryIds) async {
    try {
      await _client.dio.post('/businesses/$businessId/subcategories', data: subcategoryIds);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to set business subcategories');
    }
  }

  /// Update contact form template.
  Future<void> updateContactFormTemplate(String businessId, String? template) async {
    try {
      await _client.dio.patch('/businesses/$businessId', data: {'contact_form_template': template});
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update contact form template');
    }
  }

  /// Fetch featured businesses with category/subcategory pre-populated.
  Future<List<FeaturedBusiness>> getFeaturedBusiness({int limit = 10}) async {
    try {
      final response = await _client.dio.get(
        '/businesses/featured',
        queryParameters: {'limit': limit},
      );
      final data = response.data as List;
      return data.map((json) => FeaturedBusiness.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get featured businesses');
    }
  }
}

@riverpod
BusinessApi businessApi(BusinessApiRef ref) {
  return BusinessApi(ApiClient.instance);
}
