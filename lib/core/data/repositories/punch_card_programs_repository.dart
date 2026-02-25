import 'package:my_app/core/data/models/punch_card_program.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Public read: punch_card_programs (backend-cheatsheet §7).
class PunchCardProgramsRepository {
  PunchCardProgramsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  static const _limit = 1000;

  Future<List<PunchCardProgram>> listActive({String? businessId}) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('punch_card_programs').select().eq('is_active', true);
    if (businessId != null) q = q.eq('business_id', businessId);
    final list = await q.limit(_limit);
    return (list as List)
        .map((e) => PunchCardProgram.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Manager: delete a punch card program. RLS must allow manager to delete own business programs.
  Future<void> deleteForManager(String programId) async {
    final client = _client;
    if (client == null) return;
    await client.from('punch_card_programs').delete().eq('id', programId);
  }

  /// Manager/admin: insert a new punch card program.
  Future<void> insert({
    required String businessId,
    required int punchesRequired,
    required String rewardDescription,
    String? title,
    bool isActive = true,
  }) async {
    final client = _client;
    if (client == null) return;
    final id = 'p-${DateTime.now().millisecondsSinceEpoch}-${rewardDescription.hashCode.abs()}';
    await client.from('punch_card_programs').insert({
      'id': id,
      'business_id': businessId,
      'punches_required': punchesRequired,
      'reward_description': rewardDescription,
      'title': title,
      'is_active': isActive,
    });
  }
}
