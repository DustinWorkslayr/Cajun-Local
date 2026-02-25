import 'package:my_app/core/data/models/business_hours.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Public read: business_hours (§7).
class BusinessHoursRepository {
  BusinessHoursRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  Future<List<BusinessHours>> getForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('business_hours')
        .select()
        .eq('business_id', businessId)
        .order('day_of_week');
    return (list as List)
        .map((e) => BusinessHours.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Manager/admin: replace all hours for a business. Pass 7 items (one per day).
  Future<void> setForBusiness(String businessId, List<BusinessHours> hours) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_hours').delete().eq('business_id', businessId);
    if (hours.isEmpty) return;
    await client.from('business_hours').insert(
      hours.map((h) => {
        'business_id': h.businessId,
        'day_of_week': h.dayOfWeek,
        'open_time': h.openTime,
        'close_time': h.closeTime,
        'is_closed': h.isClosed ?? false,
      }).toList(),
    );
  }
}
