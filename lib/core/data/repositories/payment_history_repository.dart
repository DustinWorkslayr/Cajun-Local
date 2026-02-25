import 'package:my_app/core/data/models/payment_history_entry.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Payment history (pricing-and-ads-cheatsheet §2.8). SELECT only; no client writes.
class PaymentHistoryRepository {
  PaymentHistoryRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// List payments (RLS: own user/business manager sees their rows; admin sees all).
  /// [userId] / [businessId] / [paymentType] optional filters (applied in app for admin; RLS filters by auth).
  Future<List<PaymentHistoryEntry>> list({
    String? userId,
    String? businessId,
    String? paymentType,
    int limit = 100,
  }) async {
    final client = _client;
    if (client == null) return [];
    var query = client.from('payment_history').select();
    if (userId != null && userId.isNotEmpty) query = query.eq('user_id', userId);
    if (businessId != null && businessId.isNotEmpty) query = query.eq('business_id', businessId);
    if (paymentType != null && paymentType.isNotEmpty) query = query.eq('payment_type', paymentType);
    final list = await query.order('created_at', ascending: false).limit(limit);
    return (list as List<dynamic>)
        .map((e) => PaymentHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PaymentHistoryEntry?> getById(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('payment_history').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return PaymentHistoryEntry.fromJson(Map<String, dynamic>.from(res));
  }
}
