import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'users_api.g.dart';

class UsersApi {
  UsersApi(this._client);
  final ApiClient _client;

  Future<void> deleteUser(String userId) async {
    try {
      await _client.dio.delete('/users/$userId');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete user');
    }
  }
}

@riverpod
UsersApi usersApi(UsersApiRef ref) {
  return UsersApi(ApiClient.instance);
}
