import 'package:my_app/core/data/models/audit_log_entry.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Audit log (backend-cheatsheet §2). Admin read-only.
class AuditLogRepository {
  AuditLogRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  static const int defaultPageSize = 50;
  static const int maxPageSize = 500;

  /// List audit log entries with optional [search]. Search filters on action, target_table, target_id, and details (case-insensitive).
  Future<List<AuditLogEntry>> list({
    int limit = defaultPageSize,
    int offset = 0,
    String? search,
  }) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('audit_log').select();
    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      q = q.or('action.ilike.$term,details.ilike.$term,target_table.ilike.$term,target_id.ilike.$term');
    }
    final list = await q.order('created_at', ascending: false).range(offset, offset + limit - 1);
    return (list as List).map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Total count with same optional [search] filter for pagination.
  Future<int> count({String? search}) async {
    final client = _client;
    if (client == null) return 0;
    var q = client.from('audit_log').select();
    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      q = q.or('action.ilike.$term,details.ilike.$term,target_table.ilike.$term,target_id.ilike.$term');
    }
    try {
      final res = await q.count();
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  /// Insert an audit log entry. Use current user id from auth when calling from the app.
  /// Does not throw; call after the main action so failures do not block approve/reject.
  Future<void> insert({
    required String action,
    String? userId,
    String? targetTable,
    String? targetId,
    String? details,
  }) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('audit_log').insert({
        'action': action,
        ...? (userId != null ? {'user_id': userId} : null),
        ...? (targetTable != null ? {'target_table': targetTable} : null),
        ...? (targetId != null ? {'target_id': targetId} : null),
        ...? (details != null ? {'details': details} : null),
      });
    } catch (_) {
      // Fire-and-forget: do not block or rethrow
    }
  }
}
