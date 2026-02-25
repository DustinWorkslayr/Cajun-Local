import 'package:my_app/core/data/models/business.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessRepository {
  BusinessRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  static const _approved = 'approved';
  static const _limit = 2000;

  Future<List<Business>> listApproved({String? categoryId}) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('businesses').select().eq('status', _approved);
    if (categoryId != null) q = q.eq('category_id', categoryId);
    final list = await q.order('name').limit(_limit);
    return (list as List).map((e) => Business.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Business?> getById(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('businesses').select().eq('id', id).eq('status', _approved).maybeSingle();
    if (res == null) return null;
    return Business.fromJson(Map<String, dynamic>.from(res));
  }

  /// Manager/owner: get business by id (any status). RLS allows manager to SELECT own businesses.
  Future<Business?> getByIdForManager(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('businesses').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return Business.fromJson(Map<String, dynamic>.from(res));
  }

  /// Admin: list businesses with optional status filter (pending, approved, rejected).
  Future<List<Business>> listForAdmin({String? status}) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('businesses').select();
    if (status != null) q = q.eq('status', status);
    final list = await q.order('name').limit(_limit);
    return (list as List).map((e) => Business.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Admin: get business by id (any status).
  Future<Business?> getByIdForAdmin(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('businesses').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return Business.fromJson(Map<String, dynamic>.from(res));
  }

  /// Admin: get created_by user_id for a business (for approval notifications). Null if not set.
  Future<String?> getCreatedBy(String businessId) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('businesses').select('created_by').eq('id', businessId).maybeSingle();
    if (res == null) return null;
    return res['created_by'] as String?;
  }

  /// Admin: update status. When approving, pass [approvedBy] (current user id).
  Future<void> updateStatus(String id, String status, {String? approvedBy}) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{'status': status};
    if (status == _approved && approvedBy != null) {
      data['approved_at'] = DateTime.now().toUtc().toIso8601String();
      data['approved_by'] = approvedBy;
    }
    await client.from('businesses').update(data).eq('id', id);
  }

  /// Admin: insert unclaimed business. Sets created_by; do not set status/approved_at/approved_by.
  /// Returns the new business id.
  Future<String> insertBusiness({
    required String name,
    required String categoryId,
    required String createdBy,
    String? address,
    String? city,
    String? parish,
    String? state,
    String? phone,
    String? website,
    String? description,
    String? tagline,
    double? latitude,
    double? longitude,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    final data = <String, dynamic>{
      'name': name.trim(),
      'category_id': categoryId,
      'created_by': createdBy,
      'status': 'pending',
    };
    if (address != null && address.trim().isNotEmpty) data['address'] = address.trim();
    if (city != null && city.trim().isNotEmpty) data['city'] = city.trim();
    if (parish != null && parish.trim().isNotEmpty) data['parish'] = parish.trim();
    if (state != null && state.trim().isNotEmpty) data['state'] = state.trim();
    if (phone != null && phone.trim().isNotEmpty) data['phone'] = phone.trim();
    if (website != null && website.trim().isNotEmpty) data['website'] = website.trim();
    if (description != null && description.trim().isNotEmpty) data['description'] = description.trim();
    if (tagline != null && tagline.trim().isNotEmpty) data['tagline'] = tagline.trim();
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    final res = await client.from('businesses').insert(data).select('id').single();
    return res['id'] as String;
  }

  /// Admin: update business profile fields (name, tagline, address, logo, category, etc.). Only non-null fields are updated.
  Future<void> updateBusiness(
    String id, {
    String? name,
    String? tagline,
    String? categoryId,
    String? address,
    String? city,
    String? parish,
    String? state,
    String? phone,
    String? website,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    double? latitude,
    double? longitude,
  }) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) data['name'] = name.trim();
    if (tagline != null) data['tagline'] = tagline.trim().isEmpty ? null : tagline.trim();
    if (categoryId != null && categoryId.trim().isNotEmpty) data['category_id'] = categoryId.trim();
    if (address != null) data['address'] = address.trim().isEmpty ? null : address.trim();
    if (city != null) data['city'] = city.trim().isEmpty ? null : city.trim();
    if (parish != null) data['parish'] = parish.trim().isEmpty ? null : parish.trim();
    if (state != null) data['state'] = state.trim().isEmpty ? null : state.trim();
    if (phone != null) data['phone'] = phone.trim().isEmpty ? null : phone.trim();
    if (website != null) data['website'] = website.trim().isEmpty ? null : website.trim();
    if (description != null) data['description'] = description.trim().isEmpty ? null : description.trim();
    if (logoUrl != null) data['logo_url'] = logoUrl.trim().isEmpty ? null : logoUrl.trim();
    if (bannerUrl != null) data['banner_url'] = bannerUrl.trim().isEmpty ? null : bannerUrl.trim();
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (data.isEmpty) return;
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();

    try {
      await client.from('businesses').update(data).eq('id', id);
    } catch (e) {
      // Fallback: if DB has only cover_image_url (no logo_url/banner_url), retry with that column
      final msg = e.toString().toLowerCase();
      if ((data.containsKey('logo_url') || data.containsKey('banner_url')) &&
          (msg.contains('logo_url') || msg.contains('banner_url') || msg.contains('column') || msg.contains('couldn\'t') || msg.contains('could not find'))) {
        data.remove('logo_url');
        data.remove('banner_url');
        final cover = (bannerUrl?.trim().isNotEmpty == true ? bannerUrl!.trim() : null) ??
            (logoUrl?.trim().isNotEmpty == true ? logoUrl!.trim() : null);
        if (cover != null) data['cover_image_url'] = cover;
        if (data.isNotEmpty) {
          await client.from('businesses').update(data).eq('id', id);
        }
      } else {
        rethrow;
      }
    }
  }

  /// Manager/Admin: set contact form template for a business (general_inquiry, appointment_request, quote_request, event_booking, or null to hide).
  Future<void> updateContactFormTemplate(String businessId, String? template) async {
    final client = _client;
    if (client == null) return;
    await client.from('businesses').update({
      'contact_form_template': template?.trim().isEmpty == true ? null : template,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', businessId);
  }

  /// Parish ids for "service areas" (business_parishes table). Empty if table not used.
  Future<List<String>> getBusinessParishIds(String businessId) async {
    final client = _client;
    if (client == null) return [];
    try {
      final list = await client.from('business_parishes').select('parish_id').eq('business_id', businessId);
      return (list as List).map((e) => (e as Map<String, dynamic>)['parish_id'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  /// Set service-area parishes for a business (replaces existing). No-op if table does not exist.
  Future<void> setBusinessParishes(String businessId, List<String> parishIds) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('business_parishes').delete().eq('business_id', businessId);
      if (parishIds.isEmpty) return;
      await client.from('business_parishes').insert(
        parishIds.map((id) => {'business_id': businessId, 'parish_id': id}).toList(),
      );
    } catch (_) {
      // table may not exist yet
    }
  }

  /// Admin: set subcategories for a business (replaces any existing). No-op if [subcategoryIds] is empty.
  Future<void> setBusinessSubcategories(String businessId, List<String> subcategoryIds) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_subcategories').delete().eq('business_id', businessId);
    if (subcategoryIds.isEmpty) return;
    await client.from('business_subcategories').insert(
      subcategoryIds.map((id) => {'business_id': businessId, 'subcategory_id': id}).toList(),
    );
  }

  /// Admin: permanently delete a business. RLS requires admin. Dependent rows are removed
  /// by FK ON DELETE CASCADE where configured; otherwise this may throw if constraints exist.
  Future<void> deleteBusiness(String id) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    await client.from('businesses').delete().eq('id', id);
  }
}
