import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reviews_api.g.dart';

class ReviewsApi {
  ReviewsApi(this._client);
  final ApiClient _client;

  Future<List<Map<String, dynamic>>> listReviews({
    String? businessId,
    String? userId,
    String? status = 'approved',
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _client.dio.get(
        '/reviews/',
        queryParameters: {
          if (businessId != null) 'business_id': businessId,
          if (userId != null) 'user_id': userId,
          if (status != null) 'status': status,
          'skip': skip,
          'limit': limit,
        },
      );
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list reviews');
    }
  }

  Future<Map<String, dynamic>> getReviewById(String id) async {
    try {
      final response = await _client.dio.get('/reviews/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get review');
    }
  }

  Future<Map<String, dynamic>> createReview(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/reviews/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create review');
    }
  }

  Future<Map<String, dynamic>> approveReview(String id) async {
    try {
      final response = await _client.dio.post('/reviews/$id/approve');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to approve review');
    }
  }

  Future<Map<String, dynamic>> rejectReview(String id) async {
    try {
      final response = await _client.dio.post('/reviews/$id/reject');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to reject review');
    }
  }

  Future<void> deleteReview(String id) async {
    try {
      await _client.dio.delete('/reviews/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete review');
    }
  }
}

@riverpod
ReviewsApi reviewsApi(ReviewsApiRef ref) {
  return ReviewsApi(ApiClient.instance);
}
