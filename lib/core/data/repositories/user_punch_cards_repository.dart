import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/user_punch_cards_api.dart';
import 'package:my_app/core/data/models/punch_card_enrollment.dart';
import 'package:my_app/core/data/models/user_punch_card.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_punch_cards_repository.g.dart';

/// User punch card enrollments (backend-cheatsheet §2, §4).
/// RLS: own SELECT/INSERT; current_punches/is_redeemed only via server functions.
class UserPunchCardsRepository {
  UserPunchCardsRepository({UserPunchCardsApi? api}) : _api = api ?? UserPunchCardsApi(ApiClient.instance);
  final UserPunchCardsApi _api;

  /// List enrollments for the current user.
  Future<List<UserPunchCard>> listForCurrentUser() async {
    return _api.listForCurrentUser();
  }

  /// Get enrollment for current user and program, if any.
  Future<UserPunchCard?> getByProgramForCurrentUser(String programId) async {
    return _api.getByProgramForCurrentUser(programId);
  }

  /// Enroll current user in a program.
  Future<UserPunchCard> enroll(String programId) async {
    return _api.enroll(programId);
  }

  /// List enrollments for a business (managers only).
  Future<List<PunchCardEnrollment>> listEnrollmentsForBusiness(String businessId) async {
    return _api.listEnrollmentsForBusiness(businessId);
  }

  /// Redeem a full punch card. Caller must be a manager of the business that owns the program.
  Future<void> redeem(String userPunchCardId) async {
    await _api.redeem(userPunchCardId);
  }
}

@riverpod
UserPunchCardsRepository userPunchCardsRepository(UserPunchCardsRepositoryRef ref) {
  return UserPunchCardsRepository(api: ref.watch(userPunchCardsApiProvider));
}
