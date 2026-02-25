import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/audit_log_entry.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';

/// Full-page audit log entry detail: all fields, user-friendly labels and backend data (UUID, timestamp).
class AdminAuditLogDetailScreen extends StatelessWidget {
  const AdminAuditLogDetailScreen({super.key, required this.entry});

  final AuditLogEntry entry;

  static String _formatFriendly(DateTime? d) {
    if (d == null) return '—';
    final month = d.month;
    final day = d.day;
    final year = d.year;
    final h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final s = d.second.toString().padLeft(2, '0');
    final am = h < 12;
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$month/$day/$year at $hour12:$m:$s ${am ? 'AM' : 'PM'}';
  }

  static String _formatIso(DateTime? d) {
    if (d == null) return '—';
    return d.toIso8601String();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final nav = AppTheme.specNavy;
    const labelStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: AppTheme.specNavy,
      fontSize: 12,
    );

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        title: Text(
          entry.action,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: nav,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.specNavy),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(padding.left, 20, padding.right, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailBlock(
              label: 'Entry ID (UUID)',
              value: entry.id,
              labelStyle: labelStyle,
              subtitle: 'Backend primary key',
            ),
            _DetailBlockDual(
              label: 'Timestamp',
              friendly: _formatFriendly(entry.createdAt),
              backend: _formatIso(entry.createdAt),
              labelStyle: labelStyle,
            ),
            _DetailBlock(
              label: 'Action',
              value: entry.action,
              labelStyle: labelStyle,
            ),
            _DetailBlock(
              label: 'User ID',
              value: entry.userId ?? '—',
              labelStyle: labelStyle,
              subtitle: entry.userId != null ? 'UUID of user who performed the action' : null,
            ),
            _DetailBlock(
              label: 'Target table',
              value: entry.targetTable ?? '—',
              labelStyle: labelStyle,
              subtitle: 'Database table affected',
            ),
            _DetailBlock(
              label: 'Target ID',
              value: entry.targetId ?? '—',
              labelStyle: labelStyle,
              subtitle: entry.targetId != null ? 'Row ID (e.g. UUID) in target table' : null,
            ),
            _DetailBlock(
              label: 'Details',
              value: entry.details ?? '—',
              labelStyle: labelStyle,
              subtitle: 'Optional JSON or text payload',
            ),
          ],
        ),
      ),
    );
  }
}

/// Block with optional subtitle (user-friendly hint).
class _DetailBlockDual extends StatelessWidget {
  const _DetailBlockDual({
    required this.label,
    required this.friendly,
    required this.backend,
    required this.labelStyle,
  });

  final String label;
  final String friendly;
  final String backend;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nav.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 8),
          SelectableText(
            friendly,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: nav,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (backend != '—' && backend != friendly) ...[
            const SizedBox(height: 6),
            Text('ISO / backend', style: theme.textTheme.labelSmall?.copyWith(color: sub)),
            const SizedBox(height: 2),
            SelectableText(
              backend,
              style: theme.textTheme.bodySmall?.copyWith(
                color: sub,
                fontFamily: 'monospace',
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.label,
    required this.value,
    required this.labelStyle,
    this.subtitle,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = AppTheme.specNavy.withValues(alpha: 0.7);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: theme.textTheme.labelSmall?.copyWith(color: sub)),
          ],
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.specNavy,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
