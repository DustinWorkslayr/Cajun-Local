import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/auth/providers/auth_provider.dart';
import 'package:my_app/core/data/models/business_claim.dart';
import 'package:my_app/core/data/models/profile.dart';
import 'package:my_app/core/data/repositories/audit_log_repository.dart';
import 'package:my_app/core/data/repositories/business_claims_repository.dart';
import 'package:my_app/core/data/repositories/business_managers_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/profiles_repository.dart';

class AdminClaimDetailScreen extends ConsumerStatefulWidget {
  const AdminClaimDetailScreen({super.key, required this.claimId});

  final String claimId;

  @override
  ConsumerState<AdminClaimDetailScreen> createState() => _AdminClaimDetailScreenState();
}

class _AdminClaimDetailScreenState extends ConsumerState<AdminClaimDetailScreen> {
  BusinessClaim? _claim;
  String? _businessName;
  Profile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = BusinessClaimsRepository();
    final c = await repo.getById(widget.claimId);
    if (!mounted) return;
    if (c == null) {
      setState(() {
        _claim = null;
        _loading = false;
        _error = 'Claim not found';
      });
      return;
    }
    final b = await BusinessRepository().getByIdForAdmin(c.businessId);
    final p = await ref.read(profilesRepositoryProvider).getProfile(c.userId);
    if (mounted) {
      setState(() {
        _claim = c;
        _businessName = b?.name;
        _profile = p;
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    final repo = BusinessClaimsRepository();
    await repo.updateStatus(widget.claimId, status);
    final uid = ref.read(authNotifierProvider).valueOrNull?.id;
    if (uid != null) {
      AuditLogRepository().insert(
        action: status == 'approved' ? 'claim_approved' : 'claim_rejected',
        userId: uid,
        targetTable: 'business_claims',
        targetId: widget.claimId,
      );
    }
    if (status == 'approved' && _claim != null) {
      try {
        await BusinessManagersRepository().insert(_claim!.businessId, _claim!.userId);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Claim approved but grant access failed. Add manager manually.')),
          );
        }
      }
    }
    final to = _profile?.email?.trim();
    if (to != null && to.isNotEmpty) {
      // TODO: Backend should handle email notifications for claim approval/rejection.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved' ? 'Claim approved; user granted manager access.' : 'Status set to $status',
          ),
        ),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Business claim')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: theme.textTheme.bodyLarge))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailRow(label: 'Status', value: _claim!.status),
                  _DetailRow(label: 'Business', value: _businessName ?? _claim!.businessId),
                  _DetailRow(
                    label: 'User',
                    value: _profile != null
                        ? (_profile!.displayName ?? _profile!.email ?? _claim!.userId)
                        : _claim!.userId,
                  ),
                  if (_claim!.claimDetails != null) _DetailRow(label: 'Details', value: _claim!.claimDetails!),
                  const SizedBox(height: 24),
                  if (_claim!.status == 'pending') ...[
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
                    const SizedBox(height: 16),
                    Text(
                      'Approve will add the user to business_managers.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
