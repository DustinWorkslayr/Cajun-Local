import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'amenities_api.g.dart';

class AmenitiesApi {
  AmenitiesApi(this._client);
  final ApiClient _client;

  Future<List<Map<String, dynamic>>> listAmenities({String? bucket}) async {
    try {
      final response = await _client.dio.get(
        '/amenities/',
        queryParameters: bucket != null ? {'bucket': bucket} : null,
      );
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list amenities');
    }
  }

  Future<List<Map<String, dynamic>>> getBusinessAmenities(String businessId) async {
    try {
      final response = await _client.dio.get('/amenities/business/$businessId');
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get business amenities');
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getBulkBusinessAmenities(List<String> businessIds) async {
    if (businessIds.isEmpty) return {};
    try {
      final response = await _client.dio.get('/amenities/bulk', queryParameters: {'business_ids': businessIds});
      final data = response.data as Map<String, dynamic>;
      final result = <String, List<Map<String, dynamic>>>{};
      data.forEach((key, value) {
        final list = value as List;
        result[key] = list.cast<Map<String, dynamic>>();
      });
      return result;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get bulk business amenities');
    }
  }

  Future<void> toggleBusinessAmenities(String businessId, List<String> amenityIds) async {
    try {
      await _client.dio.post('/amenities/business/$businessId/toggle', data: {'amenity_ids': amenityIds});
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to toggle amenities');
    }
  }

  Future<Map<String, dynamic>> createAmenity(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/amenities/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create amenity');
    }
  }
}

@riverpod
AmenitiesApi amenitiesApi(AmenitiesApiRef ref) {
  return AmenitiesApi(ApiClient.instance);
}
