import 'package:my_app/core/data/models/amenity.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Amenities master list + business_amenities. Show only Global + category bucket.
class AmenitiesRepository {
  AmenitiesRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Amenities available for a category bucket: global + that bucket.
  /// Pass null to get only global amenities.
  Future<List<Amenity>> getAmenitiesForBucket(String? categoryBucket) async {
    final client = _client;
    if (client == null) return [];
    PostgrestList list;
    if (categoryBucket != null && categoryBucket.isNotEmpty) {
      list = await client
          .from('amenities')
          .select()
          .inFilter('bucket', ['global', categoryBucket])
          .order('bucket')
          .order('sort_order');
    } else {
      list = await client
          .from('amenities')
          .select()
          .eq('bucket', 'global')
          .order('sort_order');
    }
    return (list as List)
        .map((e) => Amenity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// All 50 amenities (e.g. for admin). Optional filter by bucket.
  Future<List<Amenity>> getAll({String? bucket}) async {
    final client = _client;
    if (client == null) return [];
    final query = client.from('amenities').select();
    final list = bucket != null
        ? await query.eq('bucket', bucket).order('sort_order')
        : await query.order('bucket').order('sort_order');
    return (list as List)
        .map((e) => Amenity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Selected amenity IDs for a business (from business_amenities).
  Future<List<String>> getSelectedAmenityIdsForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('business_amenities')
        .select('amenity_id')
        .eq('business_id', businessId);
    return (list as List)
        .map((e) => (e as Map<String, dynamic>)['amenity_id'] as String)
        .toList();
  }

  /// Selected amenities with details for a business.
  Future<List<Amenity>> getSelectedAmenitiesForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('business_amenities')
        .select('amenities(id, name, slug, bucket, sort_order)')
        .eq('business_id', businessId);
    return (list as List)
        .map((e) {
          final a = (e as Map<String, dynamic>)['amenities'];
          return a == null ? null : Amenity.fromJson(a as Map<String, dynamic>);
        })
        .whereType<Amenity>()
        .toList();
  }

  /// Replace business amenities. Enforces tier limit and bucket eligibility in DB.
  /// [amenityIds] must be from Global + business's category bucket only.
  Future<void> setBusinessAmenities(String businessId, List<String> amenityIds) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_amenities').delete().eq('business_id', businessId);
    if (amenityIds.isEmpty) return;
    await client.from('business_amenities').insert(
      amenityIds.map((id) => {'business_id': businessId, 'amenity_id': id}).toList(),
    );
  }

  /// Add one amenity. Throws if over limit or not allowed for bucket.
  Future<void> addBusinessAmenity(String businessId, String amenityId) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_amenities').insert({
      'business_id': businessId,
      'amenity_id': amenityId,
    });
  }

  /// Remove one amenity.
  Future<void> removeBusinessAmenity(String businessId, String amenityId) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_amenities').delete().eq('business_id', businessId).eq('amenity_id', amenityId);
  }

  /// Business IDs that have at least one of the given amenity IDs (for directory filter).
  Future<Set<String>> getBusinessIdsWithAnyAmenity(Set<String> amenityIds) async {
    if (amenityIds.isEmpty) return {};
    final client = _client;
    if (client == null) return {};
    final list = await client
        .from('business_amenities')
        .select('business_id')
        .inFilter('amenity_id', amenityIds.toList());
    return (list as List)
        .map((e) => (e as Map<String, dynamic>)['business_id'] as String)
        .toSet();
  }

  /// Amenity names per business ID (for building MockListing.amenities).
  Future<Map<String, List<String>>> getAmenityNamesForBusinesses(List<String> businessIds) async {
    if (businessIds.isEmpty) return {};
    final client = _client;
    if (client == null) return {};
    final list = await client
        .from('business_amenities')
        .select('business_id, amenities(name)')
        .inFilter('business_id', businessIds);
    final map = <String, List<String>>{};
    for (final row in list as List) {
      final r = row as Map<String, dynamic>;
      final bid = r['business_id'] as String?;
      final a = r['amenities'];
      if (bid == null) continue;
      final name = a is Map ? (a['name'] as String?) : null;
      if (name != null && name.isNotEmpty) {
        map.putIfAbsent(bid, () => []).add(name);
      }
    }
    return map;
  }
}
