import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_links_api.g.dart';

class BusinessLinksApi {
  BusinessLinksApi(this._client);
  final ApiClient _client;

  Future<List<Map<String, dynamic>>> listLinks({String? businessId, int skip = 0, int limit = 100}) async {
    try {
      final response = await _client.dio.get(
        '/business-links/',
        queryParameters: {if (businessId != null) 'business_id': businessId, 'skip': skip, 'limit': limit},
      );
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list business links');
    }
  }

  Future<Map<String, dynamic>> getLinkById(String id) async {
    try {
      final response = await _client.dio.get('/business-links/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get business link');
    }
  }

  Future<Map<String, dynamic>> createLink(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/business-links/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create business link');
    }
  }

  Future<Map<String, dynamic>> updateLink(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/business-links/$id', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update business link');
    }
  }

  Future<void> deleteLink(String id) async {
    try {
      await _client.dio.delete('/business-links/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete business link');
    }
  }
}

@riverpod
BusinessLinksApi businessLinksApi(BusinessLinksApiRef ref) {
  return BusinessLinksApi(ApiClient.instance);
}
