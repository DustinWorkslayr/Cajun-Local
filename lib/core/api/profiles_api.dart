import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/data/models/profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profiles_api.g.dart';

class ProfilesApi {
  ProfilesApi(this._client);
  final ApiClient _client;

  Future<Profile> getProfile(String userId) async {
    try {
      final response = await _client.dio.get('/profiles/$userId');
      return Profile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Profile not found');
      }
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get profile');
    }
  }

  Future<List<Profile>> listProfiles({int skip = 0, int limit = 500}) async {
    try {
      final response = await _client.dio.get('/profiles/', queryParameters: {'skip': skip, 'limit': limit});
      final data = response.data as List;
      return data.map((json) => Profile.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list profiles');
    }
  }

  Future<Profile> updateProfile(String userId, {String? displayName, String? avatarUrl}) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['display_name'] = displayName;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      final response = await _client.dio.put('/profiles/$userId', queryParameters: data);
      return Profile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update profile');
    }
  }
}

@riverpod
ProfilesApi profilesApi(ProfilesApiRef ref) {
  return ProfilesApi(ApiClient.instance);
}
