import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/ad_package.dart';
import 'package:my_app/core/data/models/business_ad.dart';
import 'package:my_app/core/data/repositories/business_ads_repository.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/widgets/admin_shared.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin: list business ads, filter by status. Tap to open detail slide-out with full admin control.
class AdminBusinessAdsScreen extends StatefulWidget {
  const AdminBusinessAdsScreen({
    super.key,
    this.embeddedInShell = false,
    this.status,
  });

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
    const statuses = [
      'draft',
      'pending_payment',
      'active',
      'paused',
      'expired',
      'rejected'
    ];

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Business ads',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
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
                ...statuses.map((s) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: FilterChip(
                        label: Text(BusinessAd.statusLabel(s)),
                        selected: _statusFilter == s,
                        onSelected: (_) => setState(() => _statusFilter = s),
                        selectedColor:
                            AppTheme.specGold.withValues(alpha: 0.4),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<BusinessAd>>(
        future: repo.listAll(status: _statusFilter),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.specNavy),
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Text(
                _statusFilter != null
                    ? 'No ads with status ${BusinessAd.statusLabel(_statusFilter!)}.'
                    : 'No ads.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.8),
                ),
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
                  title: ad.headline?.isNotEmpty == true
                      ? ad.headline!
                      : 'Ad ${ad.id.substring(0, 8)}',
                  subtitle:
                      '${ad.packageName ?? 'Package'} · ${ad.placement ?? ''} · ${BusinessAd.statusLabel(ad.status)}\n'
                      'Business: ${ad.businessId.substring(0, 8)}… · Impressions: ${ad.impressions} · Clicks: ${ad.clicks}',
                  badges: [
                    AdminBadgeData(BusinessAd.statusLabel(ad.status)),
                  ],
                  leading: ad.imageUrl != null && ad.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            ad.imageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholderIcon(),
                          ),
                        )
                      : _placeholderIcon(),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.specNavy,
                    size: 24,
                  ),
                  onTap: () => _openAdDetail(context, ad),
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
      child: const Icon(Icons.campaign_rounded,
          color: AppTheme.specNavy, size: 26),
    );
  }
}

/// Admin ad detail slide-out: same view as business owner (details, analytics, time remaining) + full admin controls.
class AdminAdDetailSlideOut extends StatefulWidget {
  const AdminAdDetailSlideOut({
    super.key,
    required this.ad,
    required this.onClose,
    required this.onUpdated,
  });

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
      transitionBuilder: (ctx, a1, a2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: a1, curve: Curves.easeOutCubic),
          ),
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
                child: AdminAdDetailSlideOut(
                ad: ad,
                onClose: onClose,
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
  State<AdminAdDetailSlideOut> createState() => _AdminAdDetailSlideOutState();
}

class _AdminAdDetailSlideOutState extends State<AdminAdDetailSlideOut> {
  late BusinessAd _ad;
  bool _updating = false;
  late TextEditingController _headlineController;
  late TextEditingController _imageUrlController;
  late TextEditingController _targetUrlController;
  bool _savingFields = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _ad = widget.ad;
    _headlineController = TextEditingController(text: _ad.headline ?? '');
    _imageUrlController = TextEditingController(text: _ad.imageUrl ?? '');
    _targetUrlController = TextEditingController(text: _ad.targetUrl ?? '');
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _imageUrlController.dispose();
    _targetUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveFields() async {
    setState(() {
      _savingFields = true;
      _saveError = null;
    });
    try {
      await BusinessAdsRepository().updateDraft(
        _ad.id,
        headline: _headlineController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        targetUrl: _targetUrlController.text.trim(),
      );
      final updated = await BusinessAdsRepository().getById(_ad.id);
      if (mounted) {
        setState(() {
          _savingFields = false;
          if (updated != null) {
            _ad = updated;
            _headlineController.text = _ad.headline ?? '';
            _imageUrlController.text = _ad.imageUrl ?? '';
            _targetUrlController.text = _ad.targetUrl ?? '';
          }
        });
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad details saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _savingFields = false;
          _saveError = e.toString();
        });
      }
    }
  }

  Future<void> _updateStatus(String status) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ad ${BusinessAd.statusLabel(status)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          AppDangerButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
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
        return AppTheme.specGold;
      default:
        return AppTheme.specNavy;
    }
  }

  static String _formatDate(DateTime d) {
    return '${d.month}/${d.day}/${d.year}';
  }

  Widget _sectionTitle(ThemeData theme, Color nav, String label) {
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: nav,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);
    final now = DateTime.now();
    final end = _ad.endDate;
    final start = _ad.startDate ?? _ad.createdAt;
    int? daysTotal;
    int? daysLeft;
    double progress = 0;
    if (start != null && end != null) {
      daysTotal = end.difference(start).inDays;
      if (daysTotal > 0) {
        if (now.isAfter(end)) {
          daysLeft = 0;
          progress = 0;
        } else {
          daysLeft = end.difference(now).inDays;
          final elapsed = now.difference(start).inDays;
          final elapsedFraction = (elapsed / daysTotal).clamp(0.0, 1.0);
          progress = 1.0 - elapsedFraction;
        }
      }
    }
    final ctr = _ad.impressions > 0
        ? (_ad.clicks / _ad.impressions * 100).toStringAsFixed(1)
        : null;

    final canApprove = _ad.status == 'pending_payment';
    final canReject = _ad.status == 'pending_payment' || _ad.status == 'draft';
    final canPause = _ad.status == 'active';
    final canResume = _ad.status == 'paused';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Ad details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded),
                color: nav,
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
                const SizedBox(height: 8),
                _AdPreviewCard(ad: _ad),
                const SizedBox(height: 20),
                _sectionTitle(theme, nav, 'Details'),
                const SizedBox(height: 10),
                Text(
                  _ad.headline?.isNotEmpty == true ? _ad.headline! : 'Ad',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: nav,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_ad.packageName ?? 'Package'} · ${_ad.placement != null ? AdPackage.placementLabel(_ad.placement!) : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(color: sub),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(_ad.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    BusinessAd.statusLabel(_ad.status),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _statusColor(_ad.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Business ID: ${_ad.businessId}',
                  style: theme.textTheme.labelSmall?.copyWith(color: sub),
                ),
                const SizedBox(height: 24),
                _sectionTitle(theme, nav, 'Edit details'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _headlineController,
                  decoration: InputDecoration(
                    labelText: 'Headline',
                    hintText: 'Ad headline',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: theme.textTheme.bodyLarge,
                  onChanged: (_) => setState(() => _saveError = null),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://…',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: theme.textTheme.bodyLarge,
                  maxLines: 2,
                  onChanged: (_) => setState(() => _saveError = null),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetUrlController,
                  decoration: InputDecoration(
                    labelText: 'Target URL',
                    hintText: 'https://…',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: theme.textTheme.bodyLarge,
                  maxLines: 2,
                  onChanged: (_) => setState(() => _saveError = null),
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _saveError!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                AppSecondaryButton(
                  onPressed: _savingFields ? null : _saveFields,
                  icon: _savingFields
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(_savingFields ? 'Saving…' : 'Save changes'),
                ),
                if (daysLeft != null || daysTotal != null) ...[
                if (_ad.startDate != null || _ad.endDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Dates: ${_ad.startDate != null ? _formatDate(_ad.startDate!) : '—'} → ${_ad.endDate != null ? _formatDate(_ad.endDate!) : '—'}',
                    style: theme.textTheme.labelSmall?.copyWith(color: sub),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Time remaining',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: nav.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  daysLeft != null && daysLeft > 0
                                      ? AppTheme.specGold
                                      : nav.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              daysLeft != null
                                  ? (daysLeft > 0
                                      ? '$daysLeft of $daysTotal days left'
                                      : 'Ad ended')
                                  : (daysTotal != null ? '$daysTotal days total' : '—'),
                              style: theme.textTheme.labelSmall?.copyWith(color: sub),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        daysLeft != null
                            ? (daysLeft > 0 ? '$daysLeft days left' : 'Ended')
                            : (daysTotal != null ? '$daysTotal days' : '—'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: nav,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                _sectionTitle(theme, nav, 'Analytics'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        label: 'Impressions',
                        value: '${_ad.impressions}',
                        theme: theme,
                        nav: nav,
                        sub: sub,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatChip(
                        label: 'Clicks',
                        value: '${_ad.clicks}',
                        theme: theme,
                        nav: nav,
                        sub: sub,
                      ),
                    ),
                  ],
                ),
                if (ctr != null) ...[
                  const SizedBox(height: 10),
                  _StatChip(
                    label: 'Click-through rate',
                    value: '$ctr%',
                    theme: theme,
                    nav: nav,
                    sub: sub,
                  ),
                ],
                const SizedBox(height: 24),
                _sectionTitle(theme, nav, 'Change status'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.specWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: nav.withValues(alpha: 0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _ad.status,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      items: const ['draft', 'pending_payment', 'active', 'paused', 'expired', 'rejected']
                          .map((s) => DropdownMenuItem(value: s, child: Text(BusinessAd.statusLabel(s))))
                          .toList(),
                      onChanged: _updating
                          ? null
                          : (String? value) {
                              if (value != null && value != _ad.status) _updateStatus(value);
                            },
                    ),
                  ),
                ),
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

/// Preview card showing how the ad looks in the app.
class _AdPreviewCard extends StatelessWidget {
  const _AdPreviewCard({required this.ad});

  final BusinessAd ad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nav.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
            color: AppTheme.specGold.withValues(alpha: 0.15),
            child: ad.imageUrl != null && ad.imageUrl!.isNotEmpty
                ? Image.network(
                    ad.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.campaign_rounded, color: AppTheme.specNavy, size: 40),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.campaign_rounded, color: AppTheme.specNavy, size: 40),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sponsored',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: nav.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ad.headline?.isNotEmpty == true ? ad.headline! : 'Ad headline',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: nav,
                  ),
                ),
                if (ad.placement != null && ad.placement!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    AdPackage.placementLabel(ad.placement!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: nav.withValues(alpha: 0.6),
                    ),
                  ),
                ],
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
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: sub),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: nav,
            ),
          ),
        ],
      ),
    );
  }
}
