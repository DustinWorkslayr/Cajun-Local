import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/payment_history_api.dart';
import 'package:my_app/core/data/models/payment_history_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payment_history_repository.g.dart';

/// Payment history (pricing-and-ads-cheatsheet §2.8). SELECT only; no client writes.
class PaymentHistoryRepository {
  PaymentHistoryRepository({PaymentHistoryApi? api}) : _api = api ?? PaymentHistoryApi(ApiClient.instance);
  final PaymentHistoryApi _api;

  /// List payments.
  Future<List<PaymentHistoryEntry>> list({
    String? userId,
    String? businessId,
    String? paymentType,
    int limit = 100,
  }) async {
    return _api.list(userId: userId, businessId: businessId, paymentType: paymentType, limit: limit);
  }

  Future<PaymentHistoryEntry?> getById(String id) async {
    return _api.getById(id);
  }
}

@riverpod
PaymentHistoryRepository paymentHistoryRepository(PaymentHistoryRepositoryRef ref) {
  return PaymentHistoryRepository(api: ref.watch(paymentHistoryApiProvider));
}
