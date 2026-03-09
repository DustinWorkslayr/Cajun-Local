import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_managers_api.g.dart';

class BusinessManagersApi {
  BusinessManagersApi(this._client);
  final ApiClient _client;

  Future<List<Map<String, dynamic>>> listManagers(String businessId) async {
    try {
      final response = await _client.dio.get('/business-managers/$businessId/managers');
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list business managers');
    }
  }

  Future<Map<String, dynamic>> lookupUser(String businessId, String email) async {
    try {
      final response = await _client.dio.get(
        '/business-managers/$businessId/lookup-user',
        queryParameters: {'email': email},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to lookup user');
    }
  }

  Future<void> addManager(String businessId, String userId, {String role = 'owner'}) async {
    try {
      await _client.dio.post(
        '/business-managers/$businessId/managers',
        queryParameters: {'user_id': userId, 'role': role},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to add manager');
    }
  }

  Future<void> removeManager(String businessId, String userId) async {
    try {
      await _client.dio.delete('/business-managers/$businessId/managers/$userId');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to remove manager');
    }
  }

  Future<List<Map<String, dynamic>>> listManagedBusinesses() async {
    try {
      final response = await _client.dio.get('/merchant/businesses');
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list managed businesses');
    }
  }
}

@riverpod
BusinessManagersApi businessManagersApi(BusinessManagersApiRef ref) {
  return BusinessManagersApi(ApiClient.instance);
}
