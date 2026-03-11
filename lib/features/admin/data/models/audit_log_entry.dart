/// Schema-aligned model for `audit_log` (backend-cheatsheet §1). Admin read-only.
library;

import 'dart:convert';

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    this.userId,
    this.targetTable,
    this.targetId,
    this.details,
    this.createdAt,
  });

  final String id;
  final String action;
  final String? userId;
  final String? targetTable;
  final String? targetId;
  final String? details;
  final DateTime? createdAt;

  static String? _stringFromJson(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map || v is List) return jsonEncode(v);
    return v.toString();
  }

  static String _stringRequired(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Map || v is List) return jsonEncode(v);
    return v.toString();
  }

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: _stringRequired(json['id']),
      action: _stringRequired(json['action']),
      userId: _stringFromJson(json['user_id']),
      targetTable: _stringFromJson(json['target_table']),
      targetId: _stringFromJson(json['target_id']),
      details: _stringFromJson(json['details']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(_stringFromJson(json['created_at']) ?? '')
          : null,
    );
  }
}
