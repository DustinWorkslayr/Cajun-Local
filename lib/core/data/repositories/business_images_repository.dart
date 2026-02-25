import 'package:my_app/core/data/models/business_image.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Public read: business_images approved only (§7).
class BusinessImagesRepository {
  BusinessImagesRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  static const _approved = 'approved';

  Future<List<BusinessImage>> getApprovedForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('business_images')
        .select()
        .eq('business_id', businessId)
        .eq('status', _approved)
        .order('sort_order');
    return (list as List)
        .map((e) => BusinessImage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin: get image by id (any status).
  Future<BusinessImage?> getByIdForAdmin(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('business_images').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return BusinessImage.fromJson(Map<String, dynamic>.from(res));
  }

  /// Admin: list images with optional status/business filter.
  Future<List<BusinessImage>> listForAdmin({String? businessId, String? status}) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('business_images').select();
    if (businessId != null) q = q.eq('business_id', businessId);
    if (status != null) q = q.eq('status', status);
    final list = await q.order('sort_order');
    return (list as List)
        .map((e) => BusinessImage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin: update image status. When approving, pass [approvedBy].
  Future<void> updateStatus(String id, String status, {String? approvedBy}) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{'status': status};
    if (status == _approved && approvedBy != null) {
      data['approved_at'] = DateTime.now().toUtc().toIso8601String();
      data['approved_by'] = approvedBy;
    }
    await client.from('business_images').update(data).eq('id', id);
  }

  /// Admin: approve multiple images in one call. [approvedBy] required (e.g. current user id).
  Future<void> approveMany(List<String> ids, {required String approvedBy}) async {
    final client = _client;
    if (client == null || ids.isEmpty) return;
    final data = <String, dynamic>{
      'status': _approved,
      'approved_at': DateTime.now().toUtc().toIso8601String(),
      'approved_by': approvedBy,
    };
    await client.from('business_images').update(data).inFilter('id', ids);
  }

  /// List all images for a business (any status). Used by manager/owner for reorder and add flow.
  Future<List<BusinessImage>> listForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('business_images')
        .select()
        .eq('business_id', businessId)
        .order('sort_order');
    return (list as List)
        .map((e) => BusinessImage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Update sort_order for images. [orderedIds] is the list of image ids in desired order (index = sort_order).
  Future<void> updateSortOrder(List<String> orderedIds) async {
    final client = _client;
    if (client == null || orderedIds.isEmpty) return;
    for (var i = 0; i < orderedIds.length; i++) {
      await client
          .from('business_images')
          .update({'sort_order': i}).eq('id', orderedIds[i]);
    }
  }

  /// Add a new business image. When [approvedBy] is set (e.g. current user id when they are admin),
  /// the image is inserted as approved. Otherwise it is inserted as pending (business owner upload).
  Future<void> insert({
    required String businessId,
    required String url,
    int sortOrder = 0,
    String? approvedBy,
  }) async {
    final client = _client;
    if (client == null) return;
    final id = const Uuid().v4();
    final isApproved = approvedBy != null;
    final data = <String, dynamic>{
      'id': id,
      'business_id': businessId,
      'url': url,
      'status': isApproved ? _approved : 'pending',
      'sort_order': sortOrder,
    };
    if (isApproved) {
      data['approved_at'] = DateTime.now().toUtc().toIso8601String();
      data['approved_by'] = approvedBy;
    }
    await client.from('business_images').insert(data);
  }
}
