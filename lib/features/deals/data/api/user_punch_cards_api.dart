import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/deals/data/models/user_punch_card.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_punch_cards_api.g.dart';

class UserPunchCardsApi {
  UserPunchCardsApi(this._client);
  final ApiClient _client;

  Future<List<UserPunchCard>> listForUser(String userId) async {
    try {
      final response = await _client.dio.get('/user-punch-cards/', queryParameters: {'user_id': userId});
      final data = response.data as List;
      return data.map((json) => UserPunchCard.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list user punch cards');
    }
  }

  Future<UserPunchCard> enroll(String userId, String programId) async {
    try {
      final response = await _client.dio.post(
        '/user-punch-cards/',
        data: {
          'user_id': userId,
          'program_id': programId,
        },
      );
      return UserPunchCard.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to enroll in punch card');
    }
  }

  Future<UserPunchCard?> getById(String id) async {
    try {
      final response = await _client.dio.get('/user-punch-cards/$id');
      return UserPunchCard.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get user punch card');
    }
  }
}

@riverpod
UserPunchCardsApi userPunchCardsApi(UserPunchCardsApiRef ref) {
  return UserPunchCardsApi(ApiClient.instance);
}
