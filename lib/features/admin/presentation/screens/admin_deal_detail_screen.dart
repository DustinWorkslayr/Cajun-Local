import 'package:flutter/material.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/models/deal.dart';
import 'package:my_app/core/data/repositories/business_managers_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/audit_log_repository.dart';
import 'package:my_app/core/data/repositories/deals_repository.dart';
import 'package:my_app/core/data/services/send_email_service.dart';

/// Admin detail: show deal and Approve/Reject actions.
class AdminDealDetailScreen extends StatefulWidget {
  const AdminDealDetailScreen({super.key, required this.dealId});

  final String dealId;

  @override
  State<AdminDealDetailScreen> createState() => _AdminDealDetailScreenState();
}

class _AdminDealDetailScreenState extends State<AdminDealDetailScreen> {
  Deal? _deal;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = DealsRepository();
    final d = await repo.getByIdForAdmin(widget.dealId);
    if (mounted) {
      setState(() {
        _deal = d;
        _loading = false;
        if (d == null) _error = 'Deal not found';
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    final repo = DealsRepository();
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    await repo.updateStatus(widget.dealId, status, approvedBy: uid);
    AuditLogRepository().insert(
      action: status == 'approved' ? 'deal_approved' : 'deal_rejected',
      userId: uid,
      targetTable: 'deals',
      targetId: widget.dealId,
    );
    if (status == 'approved' && _deal != null) {
      final businessRepo = BusinessRepository();
      final business = await businessRepo.getByIdForAdmin(_deal!.businessId);
      final businessName = business?.name ?? _deal!.businessId;
      final userId = await BusinessManagersRepository().getFirstManagerUserId(_deal!.businessId) ??
          await businessRepo.getCreatedBy(_deal!.businessId);
      if (userId != null) {
        final profile = await AuthRepository().getProfileForAdmin(userId);
        final to = profile?.email?.trim();
        if (to != null && to.isNotEmpty) {
          await SendEmailService().send(
            to: to,
            template: 'deal_approved',
            variables: {
              'display_name': profile?.displayName ?? to,
              'email': to,
              'deal_title': _deal!.title,
              'business_name': businessName,
            },
          );
        }
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status set to $status')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_deal?.title ?? 'Deal')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: theme.textTheme.bodyLarge))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DetailRow(label: 'Status', value: _deal!.status),
                      _DetailRow(label: 'Title', value: _deal!.title),
                      _DetailRow(label: 'Deal type', value: _deal!.dealType),
                      _DetailRow(label: 'Business ID', value: _deal!.businessId),
                      if (_deal!.description != null) _DetailRow(label: 'Description', value: _deal!.description!),
                      if (_deal!.startDate != null) _DetailRow(label: 'Start', value: _deal!.startDate!.toIso8601String()),
                      if (_deal!.endDate != null) _DetailRow(label: 'End', value: _deal!.endDate!.toIso8601String()),
                      _DetailRow(label: 'Active', value: '${_deal!.isActive ?? false}'),
                      const SizedBox(height: 24),
                      if (_deal!.status == 'pending') ...[
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _updateStatus('approved'),
                                icon: const Icon(Icons.check_rounded, size: 20),
                                label: const Text('Approve'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _updateStatus('rejected'),
                                icon: const Icon(Icons.close_rounded, size: 20),
                                label: const Text('Reject'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
