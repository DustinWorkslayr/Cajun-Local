import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/businesses/data/api/business_api.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/models/featured_business.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_repository.g.dart';

class BusinessRepository {
  BusinessRepository({BusinessApi? api}) : _api = api ?? BusinessApi(ApiClient.instance);
  final BusinessApi _api;

  static const _defaultPageSize = 50;

  /// Paginated approved businesses.
  Future<List<Business>> listApproved({
    String? categoryId,
    Set<String>? parishIds,
    int limit = _defaultPageSize,
    int offset = 0,
  }) async {
    return _api.listApproved(categoryId: categoryId, parishIds: parishIds, limit: limit, offset: offset);
  }

  /// Total count of approved businesses.
  Future<int> listApprovedCount({String? categoryId, Set<String>? parishIds}) async {
    return _api.listApprovedCount(categoryId: categoryId, parishIds: parishIds);
  }

  Future<Business?> getById(String id) async {
    return _api.getById(id);
  }

  /// Manager/owner: get business by id (any status).
  Future<Business?> getByIdForManager(String id) async {
    return _api.getById(id);
  }

  /// Admin: list businesses with optional status and search. Paginated.
  Future<List<Business>> listForAdmin({
    String? status,
    String? search,
    int limit = _defaultPageSize,
    int offset = 0,
  }) async {
    return _api.listBusinesses(status: status, search: search, limit: limit, offset: offset);
  }

  /// Admin: total count with optional [status] and [search] filter.
  Future<int> listForAdminCount({String? status, String? search}) async {
    // For now, we fetch all to count if backend doesn't provide a count endpoint.
    final list = await _api.listBusinesses(status: status, search: search, limit: 10000);
    return list.length;
  }

  /// Admin: get business by id (any status).
  Future<Business?> getByIdForAdmin(String id) async {
    return _api.getById(id);
  }

  /// Admin: get created_by user_id for a business.
  Future<String?> getCreatedBy(String businessId) async {
    final business = await _api.getById(businessId);
    return business?.createdBy;
  }

  /// Admin: update status.
  Future<void> updateStatus(String id, String status, {String? approvedBy}) async {
    await _api.updateStatus(id, status);
  }

  /// Admin: insert unclaimed business.
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

    return _api.insertBusiness(data);
  }

  /// Admin: update business profile fields.
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
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (tagline != null) data['tagline'] = tagline;
    if (categoryId != null) data['category_id'] = categoryId;
    if (address != null) data['address'] = address;
    if (city != null) data['city'] = city;
    if (parish != null) data['parish'] = parish;
    if (state != null) data['state'] = state;
    if (phone != null) data['phone'] = phone;
    if (website != null) data['website'] = website;
    if (description != null) data['description'] = description;
    if (logoUrl != null) data['logo_url'] = logoUrl;
    if (bannerUrl != null) data['banner_url'] = bannerUrl;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;

    await _api.updateBusiness(id, data);
  }

  /// Manager/Admin: set contact form template.
  Future<void> updateContactFormTemplate(String businessId, String? template) async {
    await _api.updateContactFormTemplate(businessId, template);
  }

  /// Parish ids for "service areas".
  Future<List<String>> getBusinessParishIds(String businessId) async {
    return _api.getBusinessParishIds(businessId);
  }

  /// Set service-area parishes for a business.
  Future<void> setBusinessParishes(String businessId, List<String> parishIds) async {
    await _api.setBusinessParishes(businessId, parishIds);
  }

  /// Admin: set subcategories for a business.
  Future<void> setBusinessSubcategories(String businessId, List<String> subcategoryIds) async {
    await _api.setBusinessSubcategories(businessId, subcategoryIds);
  }

  /// Admin: permanently delete a business.
  Future<void> deleteBusiness(String id) async {
    await _api.deleteBusiness(id);
  }

  /// Get featured businesses with basic details and category info.
  Future<List<FeaturedBusiness>> getFeaturedBusiness({int limit = 10}) async {
    return _api.getFeaturedBusiness(limit: limit);
  }
}

@riverpod
BusinessRepository businessRepository(BusinessRepositoryRef ref) {
  return BusinessRepository(api: ref.watch(businessApiProvider));
}
