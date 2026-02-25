import 'package:my_app/core/data/models/form_submission.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Form submissions (messaging-faqs-cheatsheet §5.2). User INSERT; manager SELECT/UPDATE.
class FormSubmissionsRepository {
  FormSubmissionsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Submit a contact form (authenticated user). RLS: user_id = auth.uid().
  Future<void> insert({
    required String businessId,
    required String userId,
    required String template,
    required Map<String, dynamic> data,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    await client.from('form_submissions').insert({
      'business_id': businessId,
      'user_id': userId,
      'template': template,
      'data': data,
    });
  }

  /// List submissions for a single business (manager). Newest first.
  Future<List<FormSubmission>> listForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('form_submissions')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return (list as List)
        .map((e) => FormSubmission.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// List submissions for multiple businesses (manager). Newest first. Optionally set business names on each.
  Future<List<FormSubmission>> listForBusinesses(
    List<String> businessIds, {
    Map<String, String>? businessNamesById,
  }) async {
    final client = _client;
    if (client == null || businessIds.isEmpty) return [];
    final list = await client
        .from('form_submissions')
        .select()
        .inFilter('business_id', businessIds)
        .order('created_at', ascending: false);
    final submissions = (list as List)
        .map((e) => FormSubmission.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (businessNamesById != null) {
      return submissions
          .map((s) => FormSubmission(
                id: s.id,
                businessId: s.businessId,
                userId: s.userId,
                template: s.template,
                data: s.data,
                isRead: s.isRead,
                createdAt: s.createdAt,
                businessName: businessNamesById[s.businessId],
                adminNote: s.adminNote,
                repliedAt: s.repliedAt,
                repliedBy: s.repliedBy,
              ))
          .toList();
    }
    return submissions;
  }

  /// Update submission (manager or admin). Set [adminNote] to add or change note; when set, [repliedBy] is stored.
  Future<void> update(
    String id, {
    bool? isRead,
    String? adminNote,
    String? repliedBy,
  }) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{};
    if (isRead != null) data['is_read'] = isRead;
    if (adminNote != null) {
      data['admin_note'] = adminNote.isEmpty ? null : adminNote;
      data['replied_at'] = DateTime.now().toUtc().toIso8601String();
      if (repliedBy != null) data['replied_by'] = repliedBy;
    }
    if (data.isEmpty) return;
    await client.from('form_submissions').update(data).eq('id', id);
  }

  /// Admin: delete a submission. RLS allows admin only.
  Future<void> deleteForAdmin(String id) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    await client.from('form_submissions').delete().eq('id', id);
  }

  /// Admin: list all submissions, optional filter by business. Newest first. Business names resolved.
  Future<List<FormSubmission>> listForAdmin({
    String? businessId,
    int? limit,
    int? offset,
  }) async {
    final client = _client;
    if (client == null) return [];
    final pageSize = limit ?? 50;
    final start = offset ?? 0;
    final list = await (businessId != null
            ? client.from('form_submissions').select().eq('business_id', businessId)
            : client.from('form_submissions').select())
        .order('created_at', ascending: false)
        .range(start, start + pageSize - 1);
    final submissions = (list as List)
        .map((e) => FormSubmission.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final businessIds = submissions.map((s) => s.businessId).toSet().toList();
    if (businessIds.isEmpty) return submissions;
    final namesById = <String, String>{};
    for (final id in businessIds) {
      final res = await client.from('businesses').select('name').eq('id', id).maybeSingle();
      if (res != null && res['name'] != null) namesById[id] = res['name'] as String;
    }
    return submissions
        .map((s) => FormSubmission(
              id: s.id,
              businessId: s.businessId,
              userId: s.userId,
              template: s.template,
              data: s.data,
              isRead: s.isRead,
              createdAt: s.createdAt,
              businessName: namesById[s.businessId],
              adminNote: s.adminNote,
              repliedAt: s.repliedAt,
              repliedBy: s.repliedBy,
            ))
        .toList();
  }

  /// Unread count for one business.
  Future<int> unreadCountForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return 0;
    final list = await client
        .from('form_submissions')
        .select('id')
        .eq('business_id', businessId)
        .eq('is_read', false);
    return (list as List).length;
  }

  /// Total unread count across multiple businesses.
  Future<int> unreadCountForBusinesses(List<String> businessIds) async {
    if (businessIds.isEmpty) return 0;
    final client = _client;
    if (client == null) return 0;
    final list = await client
        .from('form_submissions')
        .select('id')
        .inFilter('business_id', businessIds)
        .eq('is_read', false);
    return (list as List).length;
  }

  /// Mark submission as read (manager).
  Future<void> markRead(String submissionId) async {
    final client = _client;
    if (client == null) return;
    await client
        .from('form_submissions')
        .update({'is_read': true}).eq('id', submissionId);
  }
}
