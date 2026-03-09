import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/data/models/punch_card_program.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'punch_card_programs_api.g.dart';

class PunchCardProgramsApi {
  PunchCardProgramsApi(this._client);
  final ApiClient _client;

  Future<List<PunchCardProgram>> listActive({String? businessId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (businessId != null) queryParams['business_id'] = businessId;
      final response = await _client.dio.get('/punch-card-programs/', queryParameters: queryParams);
      final data = response.data as List;
      return data.map((json) => PunchCardProgram.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list punch card programs');
    }
  }

  Future<void> deleteForManager(String programId) async {
    try {
      await _client.dio.delete('/punch-card-programs/$programId');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete punch card program');
    }
  }

  Future<void> insert({
    required String businessId,
    required int punchesRequired,
    required String rewardDescription,
    String? title,
    bool isActive = true,
  }) async {
    try {
      await _client.dio.post(
        '/punch-card-programs/',
        data: {
          'business_id': businessId,
          'punches_required': punchesRequired,
          'reward_description': rewardDescription,
          'title': title,
          'is_active': isActive,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to insert punch card program');
    }
  }
}

@riverpod
PunchCardProgramsApi punchCardProgramsApi(PunchCardProgramsApiRef ref) {
  return PunchCardProgramsApi(ApiClient.instance);
}
