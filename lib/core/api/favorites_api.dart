import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorites_api.g.dart';

class FavoritesApi {
  FavoritesApi(this._client);
  final ApiClient _client;

  Future<List<Map<String, dynamic>>> listFavorites() async {
    try {
      final response = await _client.dio.get('/favorites/');
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list favorites');
    }
  }

  Future<Map<String, dynamic>> addFavorite(String businessId) async {
    try {
      final response = await _client.dio.post('/favorites/', data: {'business_id': businessId});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to add favorite');
    }
  }

  Future<void> removeFavorite(String businessId) async {
    try {
      await _client.dio.delete('/favorites/$businessId');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to remove favorite');
    }
  }

  Future<int> getFavoriteCount(String businessId) async {
    try {
      final response = await _client.dio.get('/favorites/count/$businessId');
      return response.data as int;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get favorite count');
    }
  }

  Future<Map<String, int>> getBulkFavoriteCounts(List<String> businessIds) async {
    if (businessIds.isEmpty) return {};
    try {
      final response = await _client.dio.get('/favorites/bulk-counts', queryParameters: {'business_ids': businessIds});
      final data = response.data as Map<String, dynamic>;
      return data.map((key, value) => MapEntry(key, value as int));
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get bulk favorite counts');
    }
  }
}

@riverpod
FavoritesApi favoritesApi(FavoritesApiRef ref) {
  return FavoritesApi(ApiClient.instance);
}
