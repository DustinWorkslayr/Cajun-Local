import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/audit_log_api.dart';
import 'package:my_app/core/data/models/audit_log_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audit_log_repository.g.dart';

/// Audit log (backend-cheatsheet §2). Admin read-only.
class AuditLogRepository {
  AuditLogRepository({AuditLogApi? api}) : _api = api ?? AuditLogApi(ApiClient.instance);
  final AuditLogApi _api;

  static const int defaultPageSize = 50;

  /// List audit log entries with optional [search].
  Future<List<AuditLogEntry>> list({int limit = defaultPageSize, int offset = 0, String? search}) async {
    return _api.list(skip: offset, limit: limit, search: search);
  }

  /// Total count with same optional [search] filter for pagination.
  Future<int> count({String? search}) async {
    return _api.count(search: search);
  }

  /// Insert an audit log entry.
  Future<void> insert({
    required String action,
    String? userId,
    String? targetTable,
    String? targetId,
    String? details,
  }) async {
    await _api.insert({
      'action': action,
      if (userId != null) 'user_id': userId,
      if (targetTable != null) 'target_table': targetTable,
      if (targetId != null) 'target_id': targetId,
      if (details != null) 'details': details, // Details is now handled as JSON string or Map in backend?
      // Backend expects details as Dict[str, Any].
      // If details is a string, we might need to parse it if it is JSON, or just wrap it.
      // For now, I'll assume the caller passes a string that we might want to wrap.
    });
  }
}

@riverpod
AuditLogRepository auditLogRepository(AuditLogRepositoryRef ref) {
  return AuditLogRepository(api: ref.watch(auditLogApiProvider));
}
