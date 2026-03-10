import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/data/models/deal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deals_api.g.dart';

class DealsApi {
  DealsApi(this._client);
  final ApiClient _client;

  /// Fetch approved deals with optional filters.
  Future<List<Deal>> listDeals({String? businessId, String status = 'approved', int skip = 0, int limit = 50}) async {
    try {
      final response = await _client.dio.get(
        '/deals/',
        queryParameters: {
          if (businessId != null) 'business_id': businessId,
          'status': status,
          'skip': skip,
          'limit': limit,
        },
      );
      final data = response.data as List;
      return data.map((json) => Deal.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list deals');
    }
  }

  /// Get deal by ID.
  Future<Deal?> getById(String id) async {
    try {
      final response = await _client.dio.get('/deals/$id');
      return Deal.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get deal');
    }
  }

  /// Fetch deals claimed by the current user.
  Future<List<Map<String, dynamic>>> listClaimedDeals({int skip = 0, int limit = 50}) async {
    try {
      final response = await _client.dio.get('/deals/my/claimed', queryParameters: {'skip': skip, 'limit': limit});
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list claimed deals');
    }
  }

  /// Claim a deal for the current user.
  Future<Map<String, dynamic>> claimDeal(String dealId) async {
    try {
      final response = await _client.dio.post('/deals/$dealId/claim');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to claim deal');
    }
  }

  /// Mark a deal as used (redeemed).
  Future<Map<String, dynamic>> markDealAsUsed(String dealId) async {
    try {
      final response = await _client.dio.patch('/deals/$dealId/use');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to mark deal as used');
    }
  }

  /// Create a new deal (Manager/Admin).
  Future<void> insertDeal(Map<String, dynamic> data) async {
    try {
      await _client.dio.post('/deals/', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create deal');
    }
  }

  /// Delete a deal (Manager/Admin).
  Future<void> deleteDeal(String id) async {
    try {
      await _client.dio.delete('/deals/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete deal');
    }
  }

  /// Update deal status (Admin).
  Future<void> updateStatus(String id, String status) async {
    try {
      await _client.dio.patch('/deals/$id/status', data: {'status': status});
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update deal status');
    }
  }
}

@riverpod
DealsApi dealsApi(DealsApiRef ref) {
  return DealsApi(ApiClient.instance);
}
