import 'package:my_app/core/data/models/punch_card_enrollment.dart';
import 'package:my_app/core/data/models/user_punch_card.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User punch card enrollments (backend-cheatsheet §2, §4).
/// RLS: own SELECT/INSERT; current_punches/is_redeemed only via server functions.
class UserPunchCardsRepository {
  UserPunchCardsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  String? get _currentUserId => _client?.auth.currentUser?.id;

  /// List enrollments for the current user.
  Future<List<UserPunchCard>> listForCurrentUser() async {
    final client = _client;
    final uid = _currentUserId;
    if (client == null || uid == null) return [];
    final list = await client
        .from('user_punch_cards')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (list as List)
        .map((e) => UserPunchCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get enrollment for current user and program, if any.
  Future<UserPunchCard?> getByProgramForCurrentUser(String programId) async {
    final client = _client;
    final uid = _currentUserId;
    if (client == null || uid == null) return null;
    final res = await client
        .from('user_punch_cards')
        .select()
        .eq('user_id', uid)
        .eq('program_id', programId)
        .maybeSingle();
    if (res == null) return null;
    return UserPunchCard.fromJson(Map<String, dynamic>.from(res));
  }

  /// Enroll current user in a program. RLS: user_id must equal auth.uid().
  Future<UserPunchCard> enroll(String programId) async {
    final client = _client;
    final uid = _currentUserId;
    if (client == null || uid == null) {
      throw StateError('Must be signed in to enroll');
    }
    final res = await client.from('user_punch_cards').insert({
      'user_id': uid,
      'program_id': programId,
      'current_punches': 0,
      'is_redeemed': false,
    }).select().single();
    return UserPunchCard.fromJson(Map<String, dynamic>.from(res));
  }

  /// List enrollments for a business (managers only). Calls list_punch_card_enrollments_for_business RPC.
  Future<List<PunchCardEnrollment>> listEnrollmentsForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client.rpc(
      'list_punch_card_enrollments_for_business',
      params: {'p_business_id': businessId},
    );
    if (list is! List) return [];
    return list
        .map((e) => PunchCardEnrollment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Redeem a full punch card. Caller must be a manager of the business that owns the program.
  /// Throws on error (not manager, already redeemed, card not full).
  Future<void> redeem(String userPunchCardId) async {
    final client = _client;
    final uid = _currentUserId;
    if (client == null || uid == null) {
      throw StateError('Must be signed in to redeem');
    }
    final res = await client.rpc(
      'redeem_punch_card',
      params: {
        'p_card_id': userPunchCardId,
        'p_redeemed_by': uid,
      },
    );
    final map = res is Map ? Map<String, dynamic>.from(res) : null;
    final ok = map?['ok'] as bool? ?? false;
    if (!ok) {
      throw Exception(map?['error']?.toString() ?? 'Redemption failed');
    }
  }
}
