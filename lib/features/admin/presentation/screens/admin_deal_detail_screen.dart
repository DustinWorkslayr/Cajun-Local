import 'package:flutter/material.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/models/deal.dart';
import 'package:my_app/core/data/repositories/business_managers_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/audit_log_repository.dart';
import 'package:my_app/core/data/repositories/deals_repository.dart';
import 'package:my_app/core/data/services/send_email_service.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin detail: show deal and Approve/Reject actions (full-screen route).
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

/// Slide-out view for deal detail (admin business edit → Deals tab). Matches app slideout style.
class AdminDealDetailSlideOut extends StatefulWidget {
  const AdminDealDetailSlideOut({
    super.key,
    required this.dealId,
    required this.onClose,
    required this.onUpdated,
  });

  final String dealId;
  final VoidCallback onClose;
  final VoidCallback onUpdated;

  static void show(
    BuildContext context, {
    required String dealId,
    required VoidCallback onUpdated,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      transitionBuilder: (ctx, a1, a2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      pageBuilder: (ctx, _, __) {
        final panelWidth = (MediaQuery.sizeOf(ctx).width * 0.92).clamp(0.0, 420.0);
        return Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: AppTheme.specOffWhite,
              elevation: 24,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: panelWidth,
                  maxWidth: panelWidth,
                  minHeight: 0,
                  maxHeight: double.infinity,
                ),
                child: AdminDealDetailSlideOut(
                  dealId: dealId,
                  onClose: () => Navigator.of(ctx).pop(),
                  onUpdated: onUpdated,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<AdminDealDetailSlideOut> createState() => _AdminDealDetailSlideOutState();
}

class _AdminDealDetailSlideOutState extends State<AdminDealDetailSlideOut> {
  Deal? _deal;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await DealsRepository().getByIdForAdmin(widget.dealId);
    if (mounted) {
      setState(() {
        _deal = d;
        _loading = false;
        _error = d == null ? 'Deal not found' : null;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _saving = true);
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    try {
      await DealsRepository().updateStatus(widget.dealId, status, approvedBy: uid);
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
        widget.onUpdated();
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.month}/${d.day}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _deal?.title ?? 'Deal',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: widget.onClose,
                color: AppTheme.specNavy,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.specNavy))
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy)),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SlideOutRow(label: 'Status', value: _deal!.status),
                          _SlideOutRow(label: 'Title', value: _deal!.title),
                          _SlideOutRow(label: 'Deal type', value: _deal!.dealType),
                          if (_deal!.description != null && _deal!.description!.isNotEmpty)
                            _SlideOutRow(label: 'Description', value: _deal!.description!),
                          if (_deal!.startDate != null)
                            _SlideOutRow(label: 'Start', value: _formatDate(_deal!.startDate)),
                          if (_deal!.endDate != null)
                            _SlideOutRow(label: 'End', value: _formatDate(_deal!.endDate)),
                          _SlideOutRow(label: 'Active', value: (_deal!.isActive == true) ? 'Yes' : 'No'),
                          const SizedBox(height: 24),
                          if (_deal!.status == 'pending') ...[
                            Row(
                              children: [
                                Expanded(
                                  child: AppPrimaryButton(
                                    onPressed: _saving ? null : () => _updateStatus('approved'),
                                    icon: const Icon(Icons.check_rounded, size: 20),
                                    label: const Text('Approve'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppDangerOutlinedButton(
                                    onPressed: _saving ? null : () => _updateStatus('rejected'),
                                    icon: const Icon(Icons.close_rounded, size: 20),
                                    label: const Text('Reject'),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: (_deal!.status == 'approved' ? Colors.green : AppTheme.specRed).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _deal!.status.toUpperCase(),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _deal!.status == 'approved' ? Colors.green : AppTheme.specRed,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

class _SlideOutRow extends StatelessWidget {
  const _SlideOutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.specNavy.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy),
          ),
        ],
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
