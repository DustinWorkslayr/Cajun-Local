import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/deals/data/api/user_punch_cards_api.dart';
import 'package:cajun_local/features/deals/data/models/user_punch_card.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_punch_cards_repository.g.dart';

class UserPunchCardsRepository {
  UserPunchCardsRepository({UserPunchCardsApi? api}) : _api = api ?? UserPunchCardsApi(ApiClient.instance);
  final UserPunchCardsApi _api;

  Future<List<UserPunchCard>> listForUser(String userId) async {
    return _api.listForUser(userId);
  }

  Future<UserPunchCard> enroll(String userId, String programId) async {
    return _api.enroll(userId, programId);
  }

  Future<UserPunchCard?> getById(String id) async {
    return _api.getById(id);
  }
}

@riverpod
UserPunchCardsRepository userPunchCardsRepository(UserPunchCardsRepositoryRef ref) {
  return UserPunchCardsRepository(api: ref.watch(userPunchCardsApiProvider));
}
