import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/data/models/audit_log_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audit_log_api.g.dart';

class AuditLogApi {
  AuditLogApi(this._client);
  final ApiClient _client;

  /// Fetch audit logs.
  Future<List<AuditLogEntry>> list({int skip = 0, int limit = 100, String? search}) async {
    try {
      final response = await _client.dio.get(
        '/audit-log/',
        queryParameters: {'skip': skip, 'limit': limit, if (search != null) 'search': search},
      );
      final data = response.data as List;
      return data.map((json) => AuditLogEntry.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list audit logs');
    }
  }

  /// Get audit logs count.
  Future<int> count({String? search}) async {
    try {
      final response = await _client.dio.get(
        '/audit-log/count',
        queryParameters: {if (search != null) 'search': search},
      );
      return response.data as int;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get audit logs count');
    }
  }

  /// Insert an audit log entry.
  Future<void> insert(Map<String, dynamic> data) async {
    try {
      await _client.dio.post('/audit-log/', data: data);
    } on DioException catch (_) {
      // Fire-and-forget logic from repository
    }
  }
}

@riverpod
AuditLogApi auditLogApi(AuditLogApiRef ref) {
  return AuditLogApi(ApiClient.instance);
}
