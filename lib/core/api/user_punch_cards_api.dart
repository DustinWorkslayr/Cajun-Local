import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/data/models/punch_card_enrollment.dart';
import 'package:cajun_local/core/data/models/user_punch_card.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_punch_cards_api.g.dart';

class UserPunchCardsApi {
  UserPunchCardsApi(this._client);
  final ApiClient _client;

  Future<List<UserPunchCard>> listForCurrentUser() async {
    try {
      final response = await _client.dio.get('/punch-cards/all');
      final data = response.data as List;
      return data.map((json) => UserPunchCard.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list punch cards');
    }
  }

  Future<UserPunchCard?> getByProgramForCurrentUser(String programId) async {
    try {
      final response = await _client.dio.get('/punch-cards/program/$programId');
      return UserPunchCard.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get punch card for program');
    }
  }

  Future<UserPunchCard> enroll(String programId) async {
    try {
      final response = await _client.dio.post('/punch-cards/enroll', data: {'program_id': programId});
      return UserPunchCard.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to enroll in program');
    }
  }

  Future<List<PunchCardEnrollment>> listEnrollmentsForBusiness(String businessId) async {
    try {
      final response = await _client.dio.get('/punch-cards/business/$businessId/enrollments');
      final data = response.data as List;
      return data.map((json) => PunchCardEnrollment.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list enrollments for business');
    }
  }

  Future<void> redeem(String userPunchCardId) async {
    try {
      await _client.dio.post('/punch-cards/$userPunchCardId/redeem');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to redeem punch card');
    }
  }
}

@riverpod
UserPunchCardsApi userPunchCardsApi(UserPunchCardsApiRef ref) {
  return UserPunchCardsApi(ApiClient.instance);
}
