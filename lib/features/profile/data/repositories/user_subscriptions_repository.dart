import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/profile/data/api/user_subscriptions_api.dart';
import 'package:cajun_local/features/profile/data/models/user_subscription.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_subscriptions_repository.g.dart';

/// user_subscriptions: one per user (UNIQUE user_id). Admin-only write (pricing-and-ads-cheatsheet §2.4).
class UserSubscriptionsRepository {
  UserSubscriptionsRepository({UserSubscriptionsApi? api}) : _api = api ?? UserSubscriptionsApi(ApiClient.instance);
  final UserSubscriptionsApi _api;

  /// Get the active subscription for a user, if any.
  Future<UserSubscription?> getByUserId(String userId) async {
    return _api.getByUserId(userId);
  }

  /// Admin: assign or change plan for a user.
  Future<void> setPlanForUser(String userId, String planId) async {
    await _api.setPlanForUser(userId, planId);
  }

  /// Admin: remove subscription for a user (downgrade to no plan).
  Future<void> deleteByUserId(String userId) async {
    await _api.deleteByUserId(userId);
  }
}

@riverpod
UserSubscriptionsRepository userSubscriptionsRepository(UserSubscriptionsRepositoryRef ref) {
  return UserSubscriptionsRepository(api: ref.watch(userSubscriptionsApiProvider));
}
