import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/businesses/data/api/amenities_api.dart';
import 'package:cajun_local/features/businesses/data/models/amenity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'amenities_repository.g.dart';

/// Amenities master list + business_amenities. Show only Global + category bucket.
class AmenitiesRepository {
  AmenitiesRepository({AmenitiesApi? api}) : _api = api ?? AmenitiesApi(ApiClient.instance);

  final AmenitiesApi _api;

  /// Amenities available for a category bucket: global + that bucket.
  /// Pass null to get only global amenities.
  Future<List<Amenity>> getAmenitiesForBucket(String? categoryBucket) async {
    final list = await _api.listAmenities(bucket: categoryBucket);
    return list.map((e) => Amenity.fromJson(e)).toList();
  }

  /// All 50 amenities (e.g. for admin). Optional filter by bucket.
  Future<List<Amenity>> getAll({String? bucket}) async {
    final list = await _api.listAmenities(bucket: bucket);
    return list.map((e) => Amenity.fromJson(e)).toList();
  }

  /// Admin: all amenities.
  Future<List<Amenity>> getAllForAdmin({String? bucket}) async {
    final list = await _api.listAmenities(bucket: bucket);
    return list.map((e) => Amenity.fromJson(e)).toList();
  }

  /// Selected amenity IDs for a business (from business_amenities).
  Future<List<String>> getSelectedAmenityIdsForBusiness(String businessId) async {
    final list = await _api.getBusinessAmenities(businessId);
    return list.map((e) => e['id'] as String).toList();
  }

  /// Selected amenities with details for a business.
  Future<List<Amenity>> getSelectedAmenitiesForBusiness(String businessId) async {
    final list = await _api.getBusinessAmenities(businessId);
    return list.map((e) => Amenity.fromJson(e)).toList();
  }

  /// Replace business amenities.
  Future<void> setBusinessAmenities(String businessId, List<String> amenityIds) async {
    await _api.toggleBusinessAmenities(businessId, amenityIds);
  }

  /// Add one amenity.
  Future<void> addBusinessAmenity(String businessId, String amenityId) async {
    final existing = await getSelectedAmenityIdsForBusiness(businessId);
    if (!existing.contains(amenityId)) {
      await setBusinessAmenities(businessId, [...existing, amenityId]);
    }
  }

  /// Remove one amenity.
  Future<void> removeBusinessAmenity(String businessId, String amenityId) async {
    final existing = await getSelectedAmenityIdsForBusiness(businessId);
    if (existing.contains(amenityId)) {
      await setBusinessAmenities(businessId, existing.where((id) => id != amenityId).toList());
    }
  }

  /// Business IDs that have at least one of the given amenity IDs (for directory filter).
  Future<Set<String>> getBusinessIdsWithAnyAmenity(Set<String> amenityIds) async {
    // Current backend doesn't have a direct reverse lookup for amenities but we can add or fetch all and filter
    // For now returning empty or we could adding a search endpoint
    return {};
  }

  /// Amenity names per business ID (for building MockListing.amenities).
  Future<Map<String, List<String>>> getAmenityNamesForBusinesses(List<String> businessIds) async {
    if (businessIds.isEmpty) return {};
    final bulkMap = await _api.getBulkBusinessAmenities(businessIds);
    return bulkMap.map((bid, list) {
      return MapEntry(bid, list.map((a) => a['name'] as String).toList());
    });
  }

  /// Admin: insert a new amenity.
  Future<void> insertAmenity(Map<String, dynamic> data) async {
    await _api.createAmenity(data);
  }

  /// Admin: update an amenity by id.
  Future<void> updateAmenity(String id, Map<String, dynamic> data) async {
    // current backend createAmenity is defined, but update is not. We can use same pattern.
  }

  /// Admin: batch update sort_order.
  Future<void> updateAmenitiesSortOrder(List<Map<String, dynamic>> orders) async {
    // Not implemented in backend yet
  }

  /// Admin: delete an amenity.
  Future<void> deleteAmenity(String id) async {
    // Not implemented in backend yet
  }
}

@riverpod
AmenitiesRepository amenitiesRepository(AmenitiesRepositoryRef ref) {
  return AmenitiesRepository(api: ref.watch(amenitiesApiProvider));
}
