import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'parish_api.g.dart';

class ParishApi {
  ParishApi(this._client);
  final ApiClient _client;

  Future<List<Map<String, dynamic>>> listParishes({int skip = 0, int limit = 100}) async {
    try {
      final response = await _client.dio.get('/parishes/', queryParameters: {'skip': skip, 'limit': limit});
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list parishes');
    }
  }

  Future<Map<String, dynamic>> insertParish(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/parishes/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create parish');
    }
  }

  Future<Map<String, dynamic>> updateParish(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.patch('/parishes/$id', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update parish');
    }
  }

  Future<void> deleteParish(String id) async {
    try {
      await _client.dio.delete('/parishes/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete parish');
    }
  }
}

@riverpod
ParishApi parishApi(ParishApiRef ref) {
  return ParishApi(ApiClient.instance);
}
