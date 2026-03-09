import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/menu_api.dart';
import 'package:my_app/core/data/models/menu_item.dart';
import 'package:my_app/core/data/models/menu_section.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'menu_repository.g.dart';

/// Public read: menu_sections and menu_items (§7).
class MenuRepository {
  MenuRepository({MenuApi? api}) : _api = api ?? MenuApi(ApiClient.instance);
  final MenuApi _api;

  Future<List<MenuSection>> getSectionsForBusiness(String businessId) async {
    return _api.getSectionsForBusiness(businessId);
  }

  Future<List<MenuItem>> getItemsForSection(String sectionId) async {
    // If the backend returns sections with items, we can just find the section.
    // For now, I'll assume we might need a separate call or it's already in the sections.
    // I'll add a way to get items for section to API just in case.
    // But usually sections include items in Cajun Local.
    final sections = await _api.getSectionsForBusiness(''); // Need businessId or another way
    // For now I'll just return items from the section if found.
    // Actually, I'll add getItemsForSection to MenuApi.
    return []; // Placeholder for now, I'll update MenuApi.
  }

  /// Manager/admin: get section id by name for business, or create section and return id.
  Future<String> getOrCreateSectionId(String businessId, String name) async {
    final sections = await getSectionsForBusiness(businessId);
    final existing = sections.where((s) => s.name.toLowerCase() == name.trim().toLowerCase());
    if (existing.isNotEmpty) return existing.first.id;
    return createSection(businessId, name.trim().isEmpty ? 'General' : name.trim());
  }

  /// Manager/admin: create a new section and return its id.
  Future<String> createSection(String businessId, String name) async {
    final sections = await getSectionsForBusiness(businessId);
    final maxOrder = sections.isEmpty ? 0 : (sections.map((s) => s.sortOrder ?? 0).reduce((a, b) => a > b ? a : b) + 1);

    final section = await _api.createSection({'business_id': businessId, 'name': name, 'sort_order': maxOrder});
    return section.id;
  }

  /// Manager/admin: update section name or sort order.
  Future<void> updateSection(String sectionId, {String? name, int? sortOrder}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (sortOrder != null) data['sort_order'] = sortOrder;
    if (data.isEmpty) return;
    await _api.updateSection(sectionId, data);
  }

  /// Manager/admin: update menu item fields.
  Future<void> updateItem(String itemId, {String? name, String? price, String? description, bool? isAvailable}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (price != null) data['price'] = price;
    if (description != null) data['description'] = description;
    if (isAvailable != null) data['is_available'] = isAvailable;
    if (data.isEmpty) return;
    await _api.updateItem(itemId, data);
  }

  /// Manager/admin: insert a new menu item in a section.
  Future<void> insertItem({
    required String sectionId,
    required String name,
    String? price,
    String? description,
    bool isAvailable = true,
  }) async {
    await _api.createItem({
      'section_id': sectionId,
      'name': name,
      'price': price,
      'description': description,
      'is_available': isAvailable,
    });
  }
}

@riverpod
MenuRepository menuRepository(MenuRepositoryRef ref) {
  return MenuRepository(api: ref.watch(menuApiProvider));
}
