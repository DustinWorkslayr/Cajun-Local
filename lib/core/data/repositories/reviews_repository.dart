import 'package:my_app/core/data/models/review.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reviews with moderation (backend-cheatsheet §2). Admin can list any status and update.
class ReviewsRepository {
  ReviewsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  static const _limit = 500;

  Future<List<Review>> listForAdmin({String? status, String? businessId}) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('reviews').select();
    if (status != null) q = q.eq('status', status);
    if (businessId != null) q = q.eq('business_id', businessId);
    final list = await q.order('created_at', ascending: false).limit(_limit);
    return (list as List).map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Review?> getById(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('reviews').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return Review.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> updateStatus(String id, String status, {String? approvedBy}) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{'status': status};
    if (status == 'approved' && approvedBy != null) {
      data['approved_at'] = DateTime.now().toUtc().toIso8601String();
      data['approved_by'] = approvedBy;
    }
    await client.from('reviews').update(data).eq('id', id);
  }

  /// Admin: delete a review. RLS must allow admin to delete.
  Future<void> deleteForAdmin(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('reviews').delete().eq('id', id);
  }
}
