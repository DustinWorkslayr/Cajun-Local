import 'package:flutter/foundation.dart';
import 'package:my_app/core/data/models/parish.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Parishes table: allowed list for businesses and filters. Public read; admin write.
/// All parish lists in the app (Ask Local, filters, business forms, etc.) read from here — no mock fallback.
class ParishRepository {
  ParishRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  static const _limit = 500;

  /// Returns parishes from DB only. Empty if not configured or on error.
  Future<List<Parish>> listParishes() async {
    final client = _client;
    if (client == null) return [];
    try {
      final list = await client
          .from('parishes')
          .select()
          .order('sort_order')
          .limit(_limit);
      return (list as List)
          .map((e) => Parish.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      debugPrint('ParishRepository.listParishes failed: $e');
      debugPrint(st.toString());
      return [];
    }
  }

  /// Admin: create parish.
  Future<void> insertParish({
    required String id,
    required String name,
    int sortOrder = 0,
  }) async {
    final client = _client;
    if (client == null) return;
    await client.from('parishes').insert({
      'id': id,
      'name': name,
      'sort_order': sortOrder,
    });
  }

  /// Admin: update parish.
  Future<void> updateParish(String id, {String? name, int? sortOrder}) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (sortOrder != null) data['sort_order'] = sortOrder;
    if (data.isEmpty) return;
    await client.from('parishes').update(data).eq('id', id);
  }

  /// Admin: delete parish.
  Future<void> deleteParish(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('parishes').delete().eq('id', id);
  }
}
