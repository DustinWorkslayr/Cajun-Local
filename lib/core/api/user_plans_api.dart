import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/data/models/user_plan.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_plans_api.g.dart';

class UserPlansApi {
  UserPlansApi(this._client);
  final ApiClient _client;

  Future<List<UserPlan>> list() async {
    try {
      final response = await _client.dio.get('/user-plans/');
      final data = response.data as List;
      return data.map((json) => UserPlan.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list user plans');
    }
  }

  Future<UserPlan?> getById(String id) async {
    try {
      final response = await _client.dio.get('/user-plans/$id');
      return UserPlan.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get user plan');
    }
  }

  Future<void> insert(UserPlan plan) async {
    try {
      final data = plan.toJson()..remove('id');
      await _client.dio.post('/user-plans/', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to insert user plan');
    }
  }

  Future<void> update(UserPlan plan) async {
    try {
      final data = plan.toJson()..remove('id');
      await _client.dio.put('/user-plans/${plan.id}', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update user plan');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete('/user-plans/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete user plan');
    }
  }
}

@riverpod
UserPlansApi userPlansApi(UserPlansApiRef ref) {
  return UserPlansApi(ApiClient.instance);
}
