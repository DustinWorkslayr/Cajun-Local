import 'package:flutter/material.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/models/business.dart';
import 'package:my_app/core/data/repositories/audit_log_repository.dart';
import 'package:my_app/core/data/models/business_claim.dart';
import 'package:my_app/core/data/models/profile.dart';
import 'package:my_app/core/data/repositories/business_claims_repository.dart';
import 'package:my_app/core/data/repositories/business_managers_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/user_roles_repository.dart';
import 'package:my_app/core/data/services/send_email_service.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/widgets/admin_shared.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin claims: search, pagination, user-friendly cards (no UUIDs). Panel: business name, approve/reject.
class AdminClaimsScreen extends StatefulWidget {
  const AdminClaimsScreen({
    super.key,
    this.status,
    this.embeddedInShell = false,
  });

  final String? status;
  final bool embeddedInShell;

  @override
  State<AdminClaimsScreen> createState() => _AdminClaimsScreenState();
}

class _AdminClaimsScreenState extends State<AdminClaimsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _pageIndex = 0;
  int _pageSize = defaultAdminPageSize;
  List<BusinessClaim> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim()));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, String> _businessNameById = {};

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = BusinessClaimsRepository();
    final businessRepo = BusinessRepository();
    final results = await Future.wait([
      repo.listForAdmin(status: widget.status),
      businessRepo.listForAdmin(),
    ]);
    final list = results[0] as List<BusinessClaim>;
    final businesses = results[1] as List<Business>;
    final nameById = {for (final b in businesses) b.id: b.name};
    if (mounted) {
      setState(() {
        _all = list;
        _businessNameById = nameById;
        _loading = false;
      });
    }
  }

  List<BusinessClaim> get _filtered {
    if (_query.isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all.where((c) {
      final businessName = (_businessNameById[c.businessId] ?? '').toLowerCase();
      return businessName.contains(q) ||
          c.status.toLowerCase().contains(q) ||
          (c.claimDetails?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _openDetail(BusinessClaim c) {
    final businessName = _businessNameById[c.businessId] ?? 'Claim';
    AdminDetailPanel.show(
      context: context,
      title: businessName,
      child: _ClaimPanelContent(
        claim: c,
        businessName: businessName,
        onStatusUpdated: _load,
      ),
    );
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.month}/${d.day}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final filtered = _filtered;
    final total = filtered.length;
    final pageItems = paginate(filtered, _pageIndex, _pageSize);

    Widget body = Container(
      color: AppTheme.specOffWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding.left, 20, padding.right, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.status != null ? 'Claims · ${widget.status}' : 'Claims',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.specNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == 0 ? 'No claims' : '$total claim${total == 1 ? '' : 's'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AdminSearchBar(
                    controller: _searchController,
                    hint: 'Search by status or details…',
                    onChanged: (_) => setState(() => _pageIndex = 0),
                  ),
                  if (widget.status != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Filter: ${widget.status}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(_error!, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error)),
              ),
            )
          else if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.handshake_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      _query.isEmpty ? 'No claims yet.' : 'No matches for "$_query".',
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 8),
                itemCount: pageItems.length,
                itemBuilder: (context, index) {
                  final c = pageItems[index];
                  final businessName = _businessNameById[c.businessId] ?? 'Unknown business';
                  final detailsPreview = c.claimDetails != null && c.claimDetails!.isNotEmpty
                      ? (c.claimDetails!.length > 80 ? '${c.claimDetails!.substring(0, 80)}…' : c.claimDetails)
                      : null;
                  final dateStr = _formatDate(c.createdAt);
                  final subtitle = [?detailsPreview, ?(dateStr.isNotEmpty ? 'Submitted $dateStr' : null)].join(' · ');
                  final badgeList = [
                    AdminBadgeData(c.status, color: c.status == 'pending' ? AppTheme.specRed : null),
                    if (dateStr.isNotEmpty) AdminBadgeData(dateStr),
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AdminListCard(
                      title: businessName,
                      subtitle: subtitle.isEmpty ? null : subtitle,
                      badges: badgeList,
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.specGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.handshake_rounded, color: AppTheme.specNavy, size: 26),
                      ),
                      onTap: () => _openDetail(c),
                    ),
                  );
                },
              ),
            ),
            AdminPaginationFooter(
              totalCount: total,
              pageIndex: _pageIndex,
              pageSize: _pageSize,
              onPageChanged: (p) => setState(() => _pageIndex = p),
              onPageSizeChanged: (s) => setState(() {
                _pageSize = s;
                _pageIndex = 0;
              }),
            ),
          ],
        ],
      ),
    );

    if (widget.embeddedInShell) return body;
    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: Text(widget.status != null ? 'Claims (${widget.status})' : 'Claims'),
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
      ),
      body: body,
    );
  }
}

class _ClaimPanelContent extends StatefulWidget {
  const _ClaimPanelContent({
    required this.claim,
    required this.businessName,
    required this.onStatusUpdated,
  });

  final BusinessClaim claim;
  final String businessName;
  final VoidCallback onStatusUpdated;

  @override
  State<_ClaimPanelContent> createState() => _ClaimPanelContentState();
}

class _ClaimPanelContentState extends State<_ClaimPanelContent> {
  Profile? _claimantProfile;
  bool _loadingClaimant = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _loadClaimant();
  }

  Future<void> _loadClaimant() async {
    final p = await AuthRepository().getProfileForAdmin(widget.claim.userId);
    if (mounted) {
      setState(() {
        _claimantProfile = p;
        _loadingClaimant = false;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    final repo = BusinessClaimsRepository();
    await repo.updateStatus(widget.claim.id, status);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    AuditLogRepository().insert(
      action: status == 'approved' ? 'claim_approved' : 'claim_rejected',
      userId: uid,
      targetTable: 'business_claims',
      targetId: widget.claim.id,
    );
    if (status == 'approved') {
      try {
        await BusinessManagersRepository().insert(widget.claim.businessId, widget.claim.userId);
        await UserRolesRepository().setRole(widget.claim.userId, 'business_owner');
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Claim approved; grant access failed. Add manager manually if needed.')),
          );
        }
      }
    }
    final to = _claimantProfile?.email?.trim();
    if (to != null && to.isNotEmpty) {
      final businessName = widget.businessName;
      final displayName = _claimantProfile?.displayName ?? to;
      if (status == 'approved') {
        await SendEmailService().send(
          to: to,
          template: 'claim_approved',
          variables: {
            'display_name': displayName,
            'email': to,
            'business_name': businessName,
          },
        );
      } else if (status == 'rejected') {
        await SendEmailService().send(
          to: to,
          template: 'claim_rejected',
          variables: {
            'display_name': displayName,
            'business_name': businessName,
          },
        );
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'approved' ? 'Claim approved; user granted manager access.' : 'Claim rejected.')),
      );
      widget.onStatusUpdated();
      setState(() => _updating = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.claim;
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Claimant (user-facing only: name, email)
        Text(
          'Claimant',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: sub,
          ),
        ),
        const SizedBox(height: 4),
        if (_loadingClaimant)
          const SizedBox(height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy)))
        else
          Text(
            _claimantProfile != null
                ? (_claimantProfile!.displayName?.isNotEmpty == true
                    ? _claimantProfile!.displayName!
                    : _claimantProfile!.email ?? 'Unknown')
                : 'Loading…',
            style: theme.textTheme.bodyLarge?.copyWith(color: nav, fontWeight: FontWeight.w600),
          ),
        if (_claimantProfile?.email != null && _claimantProfile!.email!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            _claimantProfile!.email!,
            style: theme.textTheme.bodyMedium?.copyWith(color: sub),
          ),
        ],
        const SizedBox(height: 16),
        // Status
        Row(
          children: [
            Text(
              'Status',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: sub),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.status == 'pending'
                    ? AppTheme.specRed.withValues(alpha: 0.12)
                    : c.status == 'approved'
                        ? AppTheme.specGold.withValues(alpha: 0.2)
                        : nav.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                c.status.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.status == 'pending' ? AppTheme.specRed : nav,
                ),
              ),
            ),
          ],
        ),
        if (c.createdAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Submitted ${c.createdAt!.month}/${c.createdAt!.day}/${c.createdAt!.year}',
            style: theme.textTheme.bodySmall?.copyWith(color: sub),
          ),
        ],
        const SizedBox(height: 20),
        // Proof / document details (uploaded proof from business owner)
        Text(
          'Proof submitted',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: sub,
          ),
        ),
        const SizedBox(height: 6),
        if (c.claimDetails != null && c.claimDetails!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.specOffWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: nav.withValues(alpha: 0.15)),
            ),
            child: SelectableText(
              c.claimDetails!,
              style: theme.textTheme.bodyMedium?.copyWith(color: nav, height: 1.45),
            ),
          )
        else
          Text(
            'No proof details provided.',
            style: theme.textTheme.bodyMedium?.copyWith(color: sub),
          ),
        if (c.status == 'pending') ...[
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  onPressed: _updating ? null : () => _updateStatus('approved'),
                  expanded: true,
                  icon: _updating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 20),
                  label: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppOutlinedButton(
                  onPressed: _updating ? null : () => _updateStatus('rejected'),
                  expanded: true,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: const Text('Reject'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Approve will add the user as manager and grant business owner role.',
            style: theme.textTheme.bodySmall?.copyWith(color: sub),
          ),
        ],
      ],
    );
  }
}
