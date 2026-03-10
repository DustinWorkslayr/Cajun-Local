import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_images_api.g.dart';

class BusinessImagesApi {
  BusinessImagesApi(this._client);
  final ApiClient _client;

  Future<List<Map<String, dynamic>>> listImages({
    String? businessId,
    String? status,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _client.dio.get(
        '/business-images/',
        queryParameters: {
          if (businessId != null) 'business_id': businessId,
          if (status != null) 'status': status,
          'skip': skip,
          'limit': limit,
        },
      );
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list business images');
    }
  }

  Future<Map<String, dynamic>> getImageById(String id) async {
    try {
      final response = await _client.dio.get('/business-images/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get business image');
    }
  }

  Future<Map<String, dynamic>> createImage(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/business-images/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create business image');
    }
  }

  Future<Map<String, dynamic>> updateImageStatus(String id, String status) async {
    try {
      final response = await _client.dio.patch('/business-images/$id/status', queryParameters: {'status': status});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update image status');
    }
  }

  Future<void> updateSortOrder(List<String> orderedIds) async {
    try {
      await _client.dio.put('/business-images/sort-order', data: orderedIds);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update sort order');
    }
  }

  Future<void> deleteImage(String id) async {
    try {
      await _client.dio.delete('/business-images/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete business image');
    }
  }
}

@riverpod
BusinessImagesApi businessImagesApi(BusinessImagesApiRef ref) {
  return BusinessImagesApi(ApiClient.instance);
}
