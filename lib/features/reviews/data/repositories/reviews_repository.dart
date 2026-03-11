import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/reviews/data/api/reviews_api.dart';
import 'package:cajun_local/features/reviews/data/models/review.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reviews_repository.g.dart';

/// Reviews with moderation (backend-cheatsheet §2). Admin can list any status and update.
class ReviewsRepository {
  ReviewsRepository({ReviewsApi? api}) : _api = api ?? ReviewsApi(ApiClient.instance);

  final ReviewsApi _api;

  static const _limit = 500;

  Future<List<Review>> listForAdmin({String? status, String? businessId}) async {
    final list = await _api.listReviews(status: status, businessId: businessId, limit: _limit);
    return list.map((e) => Review.fromJson(e)).toList();
  }

  Future<Review?> getById(String id) async {
    try {
      final res = await _api.getReviewById(id);
      return Review.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateStatus(String id, String status, {String? approvedBy}) async {
    if (status == 'approved') {
      await _api.approveReview(id);
    } else if (status == 'rejected') {
      await _api.rejectReview(id);
    } else {
      // For other statuses we might need a generic update if implemented
    }
  }

  /// Admin: delete a review.
  Future<void> deleteForAdmin(String id) async {
    await _api.deleteReview(id);
  }
}

@riverpod
ReviewsRepository reviewsRepository(ReviewsRepositoryRef ref) {
  return ReviewsRepository(api: ref.watch(reviewsApiProvider));
}
