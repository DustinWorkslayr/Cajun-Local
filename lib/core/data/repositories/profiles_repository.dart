import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/api/profiles_api.dart';
import 'package:cajun_local/core/data/models/profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profiles_repository.g.dart';

class ProfilesRepository {
  ProfilesRepository({ProfilesApi? api}) : _api = api ?? ProfilesApi(ApiClient.instance);
  final ProfilesApi _api;

  Future<Profile?> getProfile(String userId) async {
    try {
      return await _api.getProfile(userId);
    } catch (_) {
      return null;
    }
  }

  Future<List<Profile>> listProfilesForAdmin({int skip = 0, int limit = 500}) async {
    return _api.listProfiles(skip: skip, limit: limit);
  }

  Future<void> updateProfileForAdmin(String userId, {String? displayName, String? avatarUrl}) async {
    await _api.updateProfile(userId, displayName: displayName, avatarUrl: avatarUrl);
  }
}

@riverpod
ProfilesRepository profilesRepository(ProfilesRepositoryRef ref) {
  return ProfilesRepository(api: ref.watch(profilesApiProvider));
}
