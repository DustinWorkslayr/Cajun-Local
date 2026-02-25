import 'package:my_app/core/data/models/menu_item.dart';
import 'package:my_app/core/data/models/menu_section.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Public read: menu_sections and menu_items (§7).
class MenuRepository {
  MenuRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  Future<List<MenuSection>> getSectionsForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('menu_sections')
        .select()
        .eq('business_id', businessId)
        .order('sort_order');
    return (list as List)
        .map((e) => MenuSection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MenuItem>> getItemsForSection(String sectionId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('menu_items')
        .select()
        .eq('section_id', sectionId);
    return (list as List)
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Manager/admin: get section id by name for business, or create section and return id.
  Future<String> getOrCreateSectionId(String businessId, String name) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    final sections = await getSectionsForBusiness(businessId);
    final existing = sections.where((s) => s.name.toLowerCase() == name.trim().toLowerCase());
    if (existing.isNotEmpty) return existing.first.id;
    return createSection(businessId, name.trim().isEmpty ? 'General' : name.trim());
  }

  /// Manager/admin: create a new section and return its id.
  Future<String> createSection(String businessId, String name) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    final sections = await getSectionsForBusiness(businessId);
    final maxOrder = sections.isEmpty
        ? 0
        : (sections.map((s) => s.sortOrder ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    final id = const Uuid().v4();
    await client.from('menu_sections').insert({
      'id': id,
      'business_id': businessId,
      'name': name,
      'sort_order': maxOrder,
    });
    return id;
  }

  /// Manager/admin: update section name or sort order.
  Future<void> updateSection(String sectionId, {String? name, int? sortOrder}) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (sortOrder != null) data['sort_order'] = sortOrder;
    if (data.isEmpty) return;
    await client.from('menu_sections').update(data).eq('id', sectionId);
  }

  /// Manager/admin: update menu item fields.
  Future<void> updateItem(
    String itemId, {
    String? name,
    String? price,
    String? description,
    bool? isAvailable,
  }) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (price != null) data['price'] = price;
    if (description != null) data['description'] = description;
    if (isAvailable != null) data['is_available'] = isAvailable;
    if (data.isEmpty) return;
    await client.from('menu_items').update(data).eq('id', itemId);
  }

  /// Manager/admin: insert a new menu item in a section.
  Future<void> insertItem({
    required String sectionId,
    required String name,
    String? price,
    String? description,
    bool isAvailable = true,
  }) async {
    final client = _client;
    if (client == null) return;
    final id = const Uuid().v4();
    await client.from('menu_items').insert({
      'id': id,
      'section_id': sectionId,
      'name': name,
      'price': price,
      'description': description,
      'is_available': isAvailable,
    });
  }
}
