import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/messaging/data/api/form_submissions_api.dart';
import 'package:cajun_local/features/messaging/data/models/form_submission.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'form_submissions_repository.g.dart';

/// Form submissions (messaging-faqs-cheatsheet §5.2). User INSERT; manager SELECT/UPDATE.
class FormSubmissionsRepository {
  FormSubmissionsRepository({FormSubmissionsApi? api}) : _api = api ?? FormSubmissionsApi(ApiClient.instance);
  final FormSubmissionsApi _api;

  /// Submit a contact form.
  Future<void> insert({
    required String businessId,
    required String userId,
    required String template,
    required Map<String, dynamic> data,
  }) async {
    await _api.create({'business_id': businessId, 'user_id': userId, 'template': template, 'data': data});
  }

  /// List submissions for a single business (manager). Newest first.
  Future<List<FormSubmission>> listForBusiness(String businessId) async {
    return _api.listForBusiness(businessId);
  }

  /// List submissions for multiple businesses (manager). Newest first. Optionally set business names on each.
  Future<List<FormSubmission>> listForBusinesses(
    List<String> businessIds, {
    Map<String, String>? businessNamesById,
  }) async {
    if (businessIds.isEmpty) return [];
    // Currently API takes single ID, or we need a multi-ID endpoint.
    // For now, if we have businessIds[0], we fetch that. If more, we'd need loop or new endpoint.
    // Optimal: Backend supports in_ filter for business_id.
    // For now, we'll try to list all and filter client side if needed, or loop if small.
    // Better: use listAll with user filter if backend supports it, or just use businessIds[0].
    if (businessIds.length == 1) {
      final submissions = await _api.listForBusiness(businessIds[0]);
      if (businessNamesById != null) {
        return submissions.map((s) => _withName(s, businessNamesById)).toList();
      }
      return submissions;
    }

    // Fallback: listAll and filter (only for admin/manager with proper token)
    final all = await _api.listAll(limit: 1000);
    final submissions = all.where((s) => businessIds.contains(s.businessId)).toList();
    if (businessNamesById != null) {
      return submissions.map((s) => _withName(s, businessNamesById)).toList();
    }
    return submissions;
  }

  FormSubmission _withName(FormSubmission s, Map<String, String> names) {
    return FormSubmission(
      id: s.id,
      businessId: s.businessId,
      userId: s.userId,
      template: s.template,
      data: s.data,
      isRead: s.isRead,
      createdAt: s.createdAt,
      businessName: names[s.businessId],
      adminNote: s.adminNote,
      repliedAt: s.repliedAt,
      repliedBy: s.repliedBy,
    );
  }

  /// Update submission (manager or admin).
  Future<void> update(String id, {bool? isRead, String? adminNote, String? repliedBy}) async {
    final data = <String, dynamic>{};
    if (isRead != null) data['is_read'] = isRead;
    if (adminNote != null) data['admin_note'] = adminNote;
    if (data.isEmpty) return;
    await _api.update(id, data);
  }

  /// Admin: delete a submission.
  Future<void> deleteForAdmin(String id) async {
    await _api.delete(id);
  }

  /// Admin: list all submissions, optional filter by business. Newest first. Business names resolved.
  Future<List<FormSubmission>> listForAdmin({String? businessId, int? limit, int? offset}) async {
    return _api.listAll(businessId: businessId, skip: offset ?? 0, limit: limit ?? 50);
  }

  /// Unread count for one business.
  Future<int> unreadCountForBusiness(String businessId) async {
    return _api.getUnreadCount([businessId]);
  }

  /// Total unread count across multiple businesses.
  Future<int> unreadCountForBusinesses(List<String> businessIds) async {
    if (businessIds.isEmpty) return 0;
    return _api.getUnreadCount(businessIds);
  }

  /// Mark submission as read (manager).
  Future<void> markRead(String submissionId) async {
    await _api.update(submissionId, {'is_read': true});
  }
}

@riverpod
FormSubmissionsRepository formSubmissionsRepository(FormSubmissionsRepositoryRef ref) {
  return FormSubmissionsRepository(api: ref.watch(formSubmissionsApiProvider));
}
