import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_ads_api.g.dart';

class BusinessAdsApi {
  BusinessAdsApi(this._client);
  final ApiClient _client;

  Future<List<Map<String, dynamic>>> listPackages({bool activeOnly = true}) async {
    try {
      final response = await _client.dio.get('/business-ads/packages', queryParameters: {'active_only': activeOnly});
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list ad packages');
    }
  }

  Future<Map<String, dynamic>> getPackageById(String id) async {
    try {
      final response = await _client.dio.get('/business-ads/packages/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get ad package');
    }
  }

  Future<Map<String, dynamic>> createPackage(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/business-ads/packages', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create ad package');
    }
  }

  Future<Map<String, dynamic>> updatePackage(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/business-ads/packages/$id', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update ad package');
    }
  }

  Future<void> deletePackage(String id) async {
    try {
      await _client.dio.delete('/business-ads/packages/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete ad package');
    }
  }

  Future<List<Map<String, dynamic>>> listAds({
    String? status,
    String? businessId,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _client.dio.get(
        '/business-ads/',
        queryParameters: {
          if (status != null) 'status': status,
          if (businessId != null) 'business_id': businessId,
          'skip': skip,
          'limit': limit,
        },
      );
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list business ads');
    }
  }

  Future<List<Map<String, dynamic>>> listActiveAds({String? placement}) async {
    try {
      final response = await _client.dio.get(
        '/business-ads/active',
        queryParameters: {if (placement != null) 'placement': placement},
      );
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list active ads');
    }
  }

  Future<Map<String, dynamic>> getAdById(String id) async {
    try {
      final response = await _client.dio.get('/business-ads/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get business ad');
    }
  }

  Future<Map<String, dynamic>> createAd(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/business-ads/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create business ad');
    }
  }

  Future<Map<String, dynamic>> updateAd(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.patch('/business-ads/$id', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update business ad');
    }
  }

  Future<Map<String, dynamic>> updateAdStatus(String id, String status) async {
    try {
      final response = await _client.dio.patch('/business-ads/$id/status', queryParameters: {'status': status});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update ad status');
    }
  }

  Future<void> deleteAd(String id) async {
    try {
      await _client.dio.delete('/business-ads/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete business ad');
    }
  }
}

@riverpod
BusinessAdsApi businessAdsApi(BusinessAdsApiRef ref) {
  return BusinessAdsApi(ApiClient.instance);
}
