import 'package:my_app/core/data/models/category_banner.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Category banners with moderation (backend-cheatsheet §2). Admin can list and update status.
class CategoryBannersRepository {
  CategoryBannersRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  static const _limit = 500;

  /// Public: list approved banners for Explore (category banner carousel).
  Future<List<CategoryBanner>> listApproved() async {
    return listForAdmin(status: 'approved');
  }

  Future<List<CategoryBanner>> listForAdmin({String? status, String? categoryId}) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('category_banners').select();
    if (status != null) q = q.eq('status', status);
    if (categoryId != null) q = q.eq('category_id', categoryId);
    final list = await q.limit(_limit);
    return (list as List).map((e) => CategoryBanner.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CategoryBanner?> getById(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('category_banners').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return CategoryBanner.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> updateStatus(String id, String status, {String? approvedBy}) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{'status': status};
    if (status == 'approved' && approvedBy != null) {
      data['approved_at'] = DateTime.now().toUtc().toIso8601String();
      data['approved_by'] = approvedBy;
    }
    await client.from('category_banners').update(data).eq('id', id);
  }

  /// Admin: update category_id and/or image_url.
  Future<void> update(String id, {String? categoryId, String? imageUrl}) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{};
    if (categoryId != null) data['category_id'] = categoryId;
    if (imageUrl != null) data['image_url'] = imageUrl;
    if (data.isEmpty) return;
    await client.from('category_banners').update(data).eq('id', id);
  }

  /// Admin: create a new category banner (status defaults to pending).
  Future<void> insert({required String categoryId, required String imageUrl}) async {
    final client = _client;
    if (client == null) return;
    final id = 'cb-${DateTime.now().millisecondsSinceEpoch}-${categoryId.hashCode}';
    await client.from('category_banners').insert({
      'id': id,
      'category_id': categoryId,
      'image_url': imageUrl,
      'status': 'pending',
    });
  }

  /// Admin: delete a category banner.
  Future<void> delete(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('category_banners').delete().eq('id', id);
  }
}
