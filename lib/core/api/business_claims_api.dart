import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_claims_api.g.dart';

class BusinessClaimsApi {
  BusinessClaimsApi(this._client);
  final ApiClient _client;

  Future<List<Map<String, dynamic>>> listClaims({int skip = 0, int limit = 50}) async {
    try {
      final response = await _client.dio.get('/business-claims/', queryParameters: {'skip': skip, 'limit': limit});
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list business claims');
    }
  }

  Future<Map<String, dynamic>> getClaimById(String id) async {
    try {
      final response = await _client.dio.get('/business-claims/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get business claim');
    }
  }

  Future<Map<String, dynamic>> createClaim(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/business-claims/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create business claim');
    }
  }

  Future<Map<String, dynamic>> approveClaim(String id) async {
    try {
      final response = await _client.dio.post('/business-claims/$id/approve');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to approve business claim');
    }
  }

  Future<Map<String, dynamic>> rejectClaim(String id) async {
    try {
      final response = await _client.dio.post('/business-claims/$id/reject');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to reject business claim');
    }
  }
}

@riverpod
BusinessClaimsApi businessClaimsApi(BusinessClaimsApiRef ref) {
  return BusinessClaimsApi(ApiClient.instance);
}
