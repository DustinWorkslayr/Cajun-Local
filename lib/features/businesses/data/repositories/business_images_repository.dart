import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/businesses/data/api/business_images_api.dart';
import 'package:cajun_local/features/businesses/data/models/business_image.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_images_repository.g.dart';

/// Public read: business_images approved only (§7).
class BusinessImagesRepository {
  BusinessImagesRepository({BusinessImagesApi? api}) : _api = api ?? BusinessImagesApi(ApiClient.instance);

  final BusinessImagesApi _api;

  static const _approved = 'approved';

  Future<List<BusinessImage>> getApprovedForBusiness(String businessId) async {
    final list = await _api.listImages(businessId: businessId, status: _approved);
    return list.map((e) => BusinessImage.fromJson(e)).toList();
  }

  /// Admin: get image by id (any status).
  Future<BusinessImage?> getByIdForAdmin(String id) async {
    try {
      final res = await _api.getImageById(id);
      return BusinessImage.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Admin: list images with optional status/business filter.
  Future<List<BusinessImage>> listForAdmin({String? businessId, String? status}) async {
    final list = await _api.listImages(businessId: businessId, status: status);
    return list.map((e) => BusinessImage.fromJson(e)).toList();
  }

  /// Admin: update image status. When approving, pass [approvedBy].
  Future<void> updateStatus(String id, String status, {String? approvedBy}) async {
    await _api.updateImageStatus(id, status);
  }

  /// Admin: approve multiple images in one call. [approvedBy] required (e.g. current user id).
  Future<void> approveMany(List<String> ids, {required String approvedBy}) async {
    for (final id in ids) {
      await _api.updateImageStatus(id, _approved);
    }
  }

  /// List all images for a business (any status). Used by manager/owner for reorder and add flow.
  Future<List<BusinessImage>> listForBusiness(String businessId) async {
    final list = await _api.listImages(businessId: businessId);
    return list.map((e) => BusinessImage.fromJson(e)).toList();
  }

  /// Update sort_order for images. [orderedIds] is the list of image ids in desired order (index = sort_order).
  Future<void> updateSortOrder(List<String> orderedIds) async {
    await _api.updateSortOrder(orderedIds);
  }

  /// Add a new business image.
  Future<void> insert({required String businessId, required String url, int sortOrder = 0, String? approvedBy}) async {
    await _api.createImage({
      'business_id': businessId,
      'url': url,
      'sort_order': sortOrder,
      'status': approvedBy != null ? _approved : 'pending',
    });
  }

  Future<void> delete(String id) async {
    await _api.deleteImage(id);
  }

  Future<void> reorder(String businessId, List<String> orderedIds) async {
    await _api.updateSortOrder(orderedIds);
  }
}

@riverpod
BusinessImagesRepository businessImagesRepository(BusinessImagesRepositoryRef ref) {
  return BusinessImagesRepository(api: ref.watch(businessImagesApiProvider));
}
