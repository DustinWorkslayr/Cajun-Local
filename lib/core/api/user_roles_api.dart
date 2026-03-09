import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/data/models/user_role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_roles_api.g.dart';

class UserRolesApi {
  UserRolesApi(this._client);
  final ApiClient _client;

  /// Get role for user.
  Future<String?> getRoleForUser(String userId) async {
    try {
      final response = await _client.dio.get('/users/$userId/role');
      return response.data['role'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get user role');
    }
  }

  /// Admin: list all user roles.
  Future<List<UserRole>> listForAdmin({int skip = 0, int limit = 500}) async {
    try {
      final response = await _client.dio.get('/users/', queryParameters: {'skip': skip, 'limit': limit});
      final data = response.data as List;
      // Map API User data to UserRole model.
      return data.map((json) {
        return UserRole(userId: json['id'] as String, role: json['role'] as String);
      }).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list user roles');
    }
  }

  /// Admin: set role for user.
  Future<void> setRole(String userId, String role) async {
    try {
      await _client.dio.put('/users/$userId/role', queryParameters: {'role': role});
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to set user role');
    }
  }

  /// Admin: remove role (reset to 'user').
  Future<void> deleteRole(String userId) async {
    try {
      await _client.dio.delete('/users/$userId/role');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete user role');
    }
  }
}

@riverpod
UserRolesApi userRolesApi(UserRolesApiRef ref) {
  return UserRolesApi(ApiClient.instance);
}
