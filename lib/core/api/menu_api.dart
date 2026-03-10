import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/data/models/menu_item.dart';
import 'package:cajun_local/core/data/models/menu_section.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'menu_api.g.dart';

class MenuApi {
  MenuApi(this._client);
  final ApiClient _client;

  /// Fetch full menu for a business.
  Future<List<MenuSection>> getSectionsForBusiness(String businessId) async {
    try {
      final response = await _client.dio.get('/menus/business/$businessId');
      final data = response.data as List;
      return data.map((json) => MenuSection.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get menu sections');
    }
  }

  /// Create a menu section.
  Future<MenuSection> createSection(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/menus/sections', data: data);
      return MenuSection.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create menu section');
    }
  }

  /// Update a menu section.
  Future<MenuSection> updateSection(String sectionId, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/menus/sections/$sectionId', data: data);
      return MenuSection.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update menu section');
    }
  }

  /// Create a menu item.
  Future<MenuItem> createItem(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/menus/items', data: data);
      return MenuItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create menu item');
    }
  }

  /// Update a menu item.
  Future<MenuItem> updateItem(String itemId, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/menus/items/$itemId', data: data);
      return MenuItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update menu item');
    }
  }
}

@riverpod
MenuApi menuApi(MenuApiRef ref) {
  return MenuApi(ApiClient.instance);
}
