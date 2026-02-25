import 'package:my_app/core/data/models/business_category.dart';
import 'package:my_app/core/data/models/subcategory.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryRepository {
  CategoryRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  static const _limit = 1000;

  Future<List<BusinessCategory>> listCategories() async {
    final client = _client;
    if (client == null) return [];
    final list = await client.from('business_categories').select().order('sort_order').limit(_limit);
    return (list as List).map((e) => BusinessCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get category by id (for bucket lookup). Returns null if not found.
  Future<BusinessCategory?> getById(String categoryId) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('business_categories').select().eq('id', categoryId).maybeSingle();
    if (res == null) return null;
    return BusinessCategory.fromJson(res as Map<String, dynamic>);
  }

  Future<List<Subcategory>> listSubcategories({String? categoryId}) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('subcategories').select();
    if (categoryId != null) q = q.eq('category_id', categoryId);
    final list = await q.limit(_limit);
    return (list as List).map((e) => Subcategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<String>> getSubcategoryIdsForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client.from('business_subcategories').select('subcategory_id').eq('business_id', businessId);
    return (list as List).map((e) => (e as Map<String, dynamic>)['subcategory_id'] as String).toList();
  }

  /// Resolve category by name (case-insensitive match). Returns null if not found.
  Future<BusinessCategory?> getCategoryByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final list = await listCategories();
    return list.where((c) => c.name.trim().toLowerCase() == trimmed.toLowerCase()).firstOrNull;
  }

  /// Resolve comma-separated subcategory names to IDs for the given category.
  /// Only returns IDs for names that match (case-insensitive); unknown names are skipped.
  Future<List<String>> resolveSubcategoryIdsByNames(String categoryId, String commaSeparatedNames) async {
    if (commaSeparatedNames.trim().isEmpty) return [];
    final names = commaSeparatedNames.split(',').map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toSet().toList();
    if (names.isEmpty) return [];
    final subcategories = await listSubcategories(categoryId: categoryId);
    final ids = <String>[];
    for (final n in names) {
      final sub = subcategories.where((s) => s.name.trim().toLowerCase() == n).firstOrNull;
      if (sub != null) ids.add(sub.id);
    }
    return ids;
  }

  /// Admin: create category.
  Future<void> insertCategory(Map<String, dynamic> data) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_categories').insert(data);
  }

  /// Admin: update category.
  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_categories').update(data).eq('id', id);
  }

  /// Admin: delete category.
  Future<void> deleteCategory(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_categories').delete().eq('id', id);
  }

  /// Admin: create subcategory.
  Future<void> insertSubcategory(Map<String, dynamic> data) async {
    final client = _client;
    if (client == null) return;
    await client.from('subcategories').insert(data);
  }

  /// Admin: update subcategory.
  Future<void> updateSubcategory(String id, Map<String, dynamic> data) async {
    final client = _client;
    if (client == null) return;
    await client.from('subcategories').update(data).eq('id', id);
  }

  /// Admin: delete subcategory.
  Future<void> deleteSubcategory(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('subcategories').delete().eq('id', id);
  }
}
