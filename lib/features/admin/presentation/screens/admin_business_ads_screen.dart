import 'package:flutter/material.dart';
import 'package:cajun_local/features/businesses/data/models/business_ad.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_ads_repository.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/admin/presentation/widgets/admin_shared.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';

/// Admin: list business ads, filter by status. Tap to open detail slide-out with full admin control.
class AdminBusinessAdsScreen extends StatefulWidget {
  const AdminBusinessAdsScreen({super.key, this.embeddedInShell = false, this.status});

  final bool embeddedInShell;
  final String? status;

  @override
  State<AdminBusinessAdsScreen> createState() => _AdminBusinessAdsScreenState();
}

class _AdminBusinessAdsScreenState extends State<AdminBusinessAdsScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.status;
  }

  void _refresh() => setState(() {});

  void _openAdDetail(BuildContext context, BusinessAd ad) {
    AdminAdDetailSlideOut.show(
      context,
      ad: ad,
      onClose: () => Navigator.of(context).pop(),
      onUpdated: () {
        _refresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = BusinessAdsRepository();
    const statuses = ['draft', 'pending_payment', 'pending_approval', 'active', 'paused', 'expired', 'rejected'];

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Business ads',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
        ),
        iconTheme: const IconThemeData(color: AppTheme.specNavy),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _statusFilter == null,
                  onSelected: (_) => setState(() => _statusFilter = null),
                  selectedColor: AppTheme.specGold.withValues(alpha: 0.4),
                ),
                ...statuses.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      label: Text(BusinessAd.statusLabel(s)),
                      selected: _statusFilter == s,
                      onSelected: (_) => setState(() => _statusFilter = s),
                      selectedColor: AppTheme.specGold.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<BusinessAd>>(
        future: repo.listAll(status: _statusFilter),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.specNavy));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Text(
                _statusFilter != null ? 'No ads with status ${BusinessAd.statusLabel(_statusFilter!)}.' : 'No ads.',
                style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final ad = list[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminListCard(
                  title: (ad.headline != null && ad.headline!.trim().isNotEmpty) ? ad.headline! : 'Untitled Ad',
                  subtitle:
                      '${ad.packageName ?? 'Package ${ad.packageId.substring(0, 8)}…'} · ${ad.businessId.substring(0, 8)}…',
                  badges: [AdminBadgeData(BusinessAd.statusLabel(ad.status), color: _statusColor(ad.status))],
                  onTap: () => _openAdDetail(context, ad),
                  leading: _placeholderIcon(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.specGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.campaign_rounded, color: AppTheme.specNavy, size: 26),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'rejected':
      case 'expired':
        return AppTheme.specRed;
      case 'pending_payment':
      case 'pending_approval':
        return AppTheme.specGold;
      default:
        return AppTheme.specNavy;
    }
  }
}

/// Admin ad detail slide-out: same view as business owner (details, analytics, time remaining) + full admin controls.
class AdminAdDetailSlideOut extends StatefulWidget {
  const AdminAdDetailSlideOut({super.key, required this.ad, required this.onClose, required this.onUpdated});

  final BusinessAd ad;
  final VoidCallback onClose;
  final VoidCallback onUpdated;

  static void show(
    BuildContext context, {
    required BusinessAd ad,
    required VoidCallback onClose,
    required VoidCallback onUpdated,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionBuilder: (ctx, a1, a2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      pageBuilder: (ctx, _, _) {
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
                child: AdminAdDetailSlideOut(ad: ad, onClose: onClose, onUpdated: onUpdated),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<AdminAdDetailSlideOut> createState() => _AdminAdDetailSlideOutState();
}

class _AdminAdDetailSlideOutState extends State<AdminAdDetailSlideOut> {
  late BusinessAd _ad;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _ad = widget.ad;
  }

  Future<void> _updateStatus(String status) async {
    if (!mounted) return;
    setState(() => _updating = true);
    try {
      await BusinessAdsRepository().updateStatus(_ad.id, status);
      final updated = await BusinessAdsRepository().getById(_ad.id);
      if (mounted) {
        setState(() {
          _updating = false;
          if (updated != null) _ad = updated;
        });
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ad ${BusinessAd.statusLabel(status)}')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _deleteAd() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ad?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          AppDangerButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _updating = true);
    try {
      await BusinessAdsRepository().delete(_ad.id);
      if (mounted) {
        widget.onUpdated();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad deleted')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'rejected':
      case 'expired':
        return AppTheme.specRed;
      case 'pending_payment':
      case 'pending_approval':
        return AppTheme.specGold;
      default:
        return AppTheme.specNavy;
    }
  }

  Widget _sectionTitle(ThemeData theme, Color nav, String label) {
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: nav),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);
    final ctr = _ad.impressions > 0 ? (_ad.clicks / _ad.impressions * 100).toStringAsFixed(1) : null;

    final canApprove = _ad.status == 'pending_payment' || _ad.status == 'pending_approval';
    final canReject = _ad.status == 'pending_payment' || _ad.status == 'pending_approval' || _ad.status == 'draft';
    final canPause = _ad.status == 'active';
    final canResume = _ad.status == 'paused';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Ad details',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: nav),
                    ),
                    const SizedBox(width: 12),
                    AdminBadge(label: BusinessAd.statusLabel(_ad.status), color: _statusColor(_ad.status)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onUpdated();
                },
                icon: const Icon(Icons.close_rounded),
                color: nav,
                tooltip: 'Close',
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle(theme, nav, 'Preview'),
                const SizedBox(height: 4),
                Text(
                  'This is how the ad will look when shown to users (only Active ads are showcased).',
                  style: theme.textTheme.bodySmall?.copyWith(color: sub),
                ),
                const SizedBox(height: 8),
                _AdPreviewCard(ad: _ad),
                const SizedBox(height: 20),
                _sectionTitle(theme, nav, 'Details'),
                const SizedBox(height: 10),
                Text(
                  (_ad.headline != null && _ad.headline!.trim().isNotEmpty)
                      ? _ad.headline!
                      : 'Untitled Ad (no headline)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: nav),
                ),
                const SizedBox(height: 12),
                _StatChip(label: 'Package', value: _ad.packageName ?? '—', theme: theme, nav: nav, sub: sub),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        label: 'Impressions',
                        value: _ad.impressions.toString(),
                        theme: theme,
                        nav: nav,
                        sub: sub,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(label: 'Clicks', value: _ad.clicks.toString(), theme: theme, nav: nav, sub: sub),
                    ),
                  ],
                ),
                if (ctr != null) ...[
                  const SizedBox(height: 8),
                  _StatChip(label: 'Click-through rate', value: '$ctr%', theme: theme, nav: nav, sub: sub),
                ],
                const SizedBox(height: 20),
                _sectionTitle(theme, nav, 'Admin actions'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canApprove)
                      AppSecondaryButton(
                        onPressed: _updating ? null : () => _updateStatus('active'),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Approve'),
                      ),
                    if (canReject)
                      AppDangerButton(
                        onPressed: _updating ? null : () => _updateStatus('rejected'),
                        icon: const Icon(Icons.cancel_rounded, size: 18),
                        label: const Text('Reject'),
                      ),
                    if (canPause)
                      AppOutlinedButton(
                        onPressed: _updating ? null : () => _updateStatus('paused'),
                        icon: const Icon(Icons.pause_rounded, size: 18),
                        label: const Text('Pause'),
                      ),
                    if (canResume)
                      AppPrimaryButton(
                        onPressed: _updating ? null : () => _updateStatus('active'),
                        expanded: false,
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Resume'),
                      ),
                    AppDangerOutlinedButton(
                      onPressed: _updating ? null : _deleteAd,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
                if (_updating)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
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

/// Preview card showing how the ad looks in the app (matches Explore sponsored style).
class _AdPreviewCard extends StatelessWidget {
  const _AdPreviewCard({required this.ad});

  final BusinessAd ad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.specNavy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: ad.imageUrl != null && ad.imageUrl!.isNotEmpty
                ? Image.network(
                    ad.imageUrl!,
                    fit: BoxFit.cover,
                    width: 64,
                    height: 64,
                    errorBuilder: (_, _, _) => const Icon(Icons.campaign_rounded, color: AppTheme.specGold, size: 32),
                  )
                : const Icon(Icons.campaign_rounded, color: AppTheme.specGold, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sponsored',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: nav.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  (ad.headline != null && ad.headline!.trim().isNotEmpty) ? ad.headline! : 'Untitled sponsored',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: nav),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.theme,
    required this.nav,
    required this.sub,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final Color nav;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nav.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: sub)),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: nav),
          ),
        ],
      ),
    );
  }
}
