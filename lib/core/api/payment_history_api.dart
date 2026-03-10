import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/data/models/payment_history_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payment_history_api.g.dart';

class PaymentHistoryApi {
  PaymentHistoryApi(this._client);
  final ApiClient _client;

  /// Fetch payment history.
  Future<List<PaymentHistoryEntry>> list({
    String? userId,
    String? businessId,
    String? paymentType,
    int limit = 100,
  }) async {
    try {
      final response = await _client.dio.get(
        '/payment-history/',
        queryParameters: {
          if (userId != null) 'user_id': userId,
          if (businessId != null) 'business_id': businessId,
          if (paymentType != null) 'payment_type': paymentType,
          'limit': limit,
        },
      );
      final data = response.data as List;
      return data.map((json) => PaymentHistoryEntry.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list payment history');
    }
  }

  /// Get payment history entry by ID.
  Future<PaymentHistoryEntry?> getById(String id) async {
    try {
      final response = await _client.dio.get('/payment-history/$id');
      return PaymentHistoryEntry.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get payment history entry');
    }
  }
}

@riverpod
PaymentHistoryApi paymentHistoryApi(PaymentHistoryApiRef ref) {
  return PaymentHistoryApi(ApiClient.instance);
}
