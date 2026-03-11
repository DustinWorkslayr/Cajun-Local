import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/categories/data/api/category_banners_api.dart';
import 'package:cajun_local/features/categories/data/models/category_banner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_banners_repository.g.dart';

/// Category banners with moderation (backend-cheatsheet §2). Admin can list and update status.
class CategoryBannersRepository {
  CategoryBannersRepository({CategoryBannersApi? api}) : _api = api ?? CategoryBannersApi(ApiClient.instance);
  final CategoryBannersApi _api;

  static const _limit = 500;

  /// Public: list approved banners for Explore (category banner carousel).
  Future<List<CategoryBanner>> listApproved() async {
    return _api.list(status: 'approved', limit: _limit);
  }

  Future<List<CategoryBanner>> listForAdmin({String? status, String? categoryId}) async {
    return _api.list(status: status, categoryId: categoryId, limit: _limit);
  }

  Future<CategoryBanner?> getById(String id) async {
    return _api.getById(id);
  }

  Future<void> updateStatus(String id, String status, {String? approvedBy}) async {
    final data = <String, dynamic>{'status': status};
    // Note: Backend might need to handle approved_at/by automatically based on user role
    await _api.update(id, data);
  }

  /// Admin: update category_id and/or image_url.
  Future<void> update(String id, {String? categoryId, String? imageUrl}) async {
    final data = <String, dynamic>{};
    if (categoryId != null) data['category_id'] = categoryId;
    if (imageUrl != null) data['image_url'] = imageUrl;
    if (data.isEmpty) return;
    await _api.update(id, data);
  }

  /// Admin: create a new category banner (status defaults to pending).
  Future<void> insert({required String categoryId, required String imageUrl}) async {
    await _api.insert({'category_id': categoryId, 'image_url': imageUrl, 'status': 'pending'});
  }

  /// Admin: delete a category banner.
  Future<void> delete(String id) async {
    await _api.delete(id);
  }
}

@riverpod
CategoryBannersRepository categoryBannersRepository(CategoryBannersRepositoryRef ref) {
  return CategoryBannersRepository(api: ref.watch(categoryBannersApiProvider));
}
