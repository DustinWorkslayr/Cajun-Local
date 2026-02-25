import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/core/data/models/business.dart';
import 'package:my_app/core/data/models/profile.dart';
import 'package:my_app/core/data/models/review.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/audit_log_repository.dart';
import 'package:my_app/core/data/repositories/reviews_repository.dart';
import 'package:my_app/core/data/services/send_email_service.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/widgets/admin_shared.dart';

/// Admin reviews: search, pagination, user-friendly cards (rating + preview, no UUIDs). Panel: approve/reject.
class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({
    super.key,
    this.status,
    this.embeddedInShell = false,
  });

  final String? status;
  final bool embeddedInShell;

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _pageIndex = 0;
  int _pageSize = defaultAdminPageSize;
  List<Review> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim()));
    // Defer _load so we don't use context/AppDataScope before initState completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, String> _businessNameById = {};
  Map<String, Profile> _profileByUserId = {};

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ReviewsRepository();
      final businessRepo = BusinessRepository();
      final authRepo = AppDataScope.of(context).authRepository;
      final results = await Future.wait([
        repo.listForAdmin(status: widget.status),
        businessRepo.listForAdmin(),
        authRepo.listProfilesForAdmin(),
      ]);
      final list = results[0] as List<Review>;
      final businesses = results[1] as List<Business>;
      final profiles = results[2] as List<Profile>;
      final nameById = {for (final b in businesses) b.id: b.name};
      final profileByUserId = {for (final p in profiles) p.userId: p};
      if (mounted) {
        setState(() {
          _all = list;
          _businessNameById = nameById;
          _profileByUserId = profileByUserId;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteReview(Review r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text(
          'This review will be permanently removed. This action cannot be undone.',
        ),
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
    if (confirmed != true || !mounted) return;
    await ReviewsRepository().deleteForAdmin(r.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted')),
      );
      _load();
    }
  }

  List<Review> get _filtered {
    if (_query.isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all.where((r) {
      final displayName = _profileByUserId[r.userId]?.displayName?.toLowerCase() ?? '';
      return '${r.rating}'.contains(q) ||
          (r.body?.toLowerCase().contains(q) ?? false) ||
          r.status.toLowerCase().contains(q) ||
          displayName.contains(q);
    }).toList();
  }

  void _openDetail(Review r) {
    final profile = _profileByUserId[r.userId];
    AdminDetailPanel.show(
      context: context,
      title: 'Review',
      child: _ReviewPanelContent(
        review: r,
        profile: profile,
        onStatusUpdated: _load,
        onDeleted: _load,
      ),
    );
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
                    widget.status != null ? 'Reviews · ${widget.status}' : 'Reviews',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.specNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == 0 ? 'No reviews' : '$total review${total == 1 ? '' : 's'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AdminSearchBar(
                    controller: _searchController,
                    hint: 'Search by name, rating or text…',
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
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      AppSecondaryButton(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_outline_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      _query.isEmpty ? 'No reviews yet.' : 'No matches for "$_query".',
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
                  final r = pageItems[index];
                  final profile = _profileByUserId[r.userId];
                  final displayName = profile?.displayName?.trim().isNotEmpty == true
                      ? profile!.displayName!
                      : 'Unknown user';
                  final avatarUrl = profile?.avatarUrl;
                  final businessName = _businessNameById[r.businessId] ?? r.businessId;
                  final preview = r.body != null && r.body!.isNotEmpty
                      ? (r.body!.length > 100 ? '${r.body!.substring(0, 100)}…' : r.body!)
                      : 'No comment';
                  final dateStr = r.createdAt != null
                      ? '${r.createdAt!.month}/${r.createdAt!.day}/${r.createdAt!.year}'
                      : null;
                  final badgeList = [
                    AdminBadgeData(r.status, color: r.status == 'pending' ? AppTheme.specRed : null),
                    if (dateStr != null) AdminBadgeData(dateStr),
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReviewListCard(
                      review: r,
                      displayName: displayName,
                      avatarUrl: avatarUrl,
                      businessName: businessName,
                      preview: preview,
                      badges: badgeList,
                      onTap: () => _openDetail(r),
                      onDelete: () => _deleteReview(r),
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
        title: Text(widget.status != null ? 'Reviews (${widget.status})' : 'Reviews'),
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
      ),
      body: body,
    );
  }
}

/// Star rating display (1–5) using theme gold.
class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, this.size = 18});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: AppTheme.specGold,
        );
      }),
    );
  }
}

/// Social/directory-style review card: avatar, name, stars, business, preview, delete.
class _ReviewListCard extends StatelessWidget {
  const _ReviewListCard({
    required this.review,
    required this.displayName,
    required this.avatarUrl,
    required this.businessName,
    required this.preview,
    required this.badges,
    required this.onTap,
    required this.onDelete,
  });

  final Review review;
  final String displayName;
  final String? avatarUrl;
  final String businessName;
  final String preview;
  final List<AdminBadgeData> badges;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.specNavy.withValues(alpha: 0.08),
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.specNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _StarRating(rating: review.rating, size: 16),
                    const SizedBox(height: 6),
                    Text(
                      businessName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (badges.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: badges
                            .map((b) => AdminBadge(
                                  label: b.label,
                                  color: b.color,
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: AppTheme.specRed, size: 22),
                onPressed: onDelete,
                tooltip: 'Delete review',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewPanelContent extends StatefulWidget {
  const _ReviewPanelContent({
    required this.review,
    required this.profile,
    required this.onStatusUpdated,
    required this.onDeleted,
  });

  final Review review;
  final Profile? profile;
  final VoidCallback onStatusUpdated;
  final VoidCallback onDeleted;

  @override
  State<_ReviewPanelContent> createState() => _ReviewPanelContentState();
}

class _ReviewPanelContentState extends State<_ReviewPanelContent> {
  String? _businessName;
  bool _loadingName = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessName();
  }

  Future<void> _loadBusinessName() async {
    final b = await BusinessRepository().getByIdForAdmin(widget.review.businessId);
    if (mounted) {
      setState(() {
        _businessName = b?.name;
        _loadingName = false;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    final repo = ReviewsRepository();
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    await repo.updateStatus(widget.review.id, status, approvedBy: uid);
    AuditLogRepository().insert(
      action: status == 'approved' ? 'review_approved' : 'review_rejected',
      userId: uid,
      targetTable: 'reviews',
      targetId: widget.review.id,
    );
    if (status == 'approved') {
      final to = widget.profile?.email?.trim();
      if (to != null && to.isNotEmpty) {
        final businessName = _businessName ?? widget.review.businessId;
        await SendEmailService().send(
          to: to,
          template: 'review_approved',
          variables: {
            'display_name': widget.profile?.displayName ?? to,
            'email': to,
            'business_name': businessName,
          },
        );
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review ${status == 'approved' ? 'approved' : 'rejected'}')),
      );
      widget.onStatusUpdated();
      setState(() => _updating = false);
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text(
          'This review will be permanently removed. This action cannot be undone.',
        ),
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
    if (confirmed != true || !mounted) return;
    setState(() => _updating = true);
    await ReviewsRepository().deleteForAdmin(widget.review.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted')),
      );
      Navigator.of(context).pop();
      widget.onDeleted();
      setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.review;
    final profile = widget.profile;
    final displayName = profile?.displayName?.trim().isNotEmpty == true
        ? profile!.displayName!
        : 'Unknown user';
    final avatarUrl = profile?.avatarUrl;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reviewer: avatar + name (social/directory style)
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.specNavy.withValues(alpha: 0.08),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.specNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StarRating(rating: r.rating, size: 20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AdminDetailLabel('Business'),
          if (_loadingName)
            const SizedBox(height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Text(_businessName ?? 'Unknown business', style: theme.textTheme.bodyLarge),
          AdminDetailLabel('Status'),
          Text(r.status, style: theme.textTheme.bodyLarge),
          if (r.body != null && r.body!.isNotEmpty) ...[
            AdminDetailLabel('Review text'),
            Text(r.body!, style: theme.textTheme.bodyMedium),
          ],
          if (r.status == 'pending') ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    onPressed: _updating ? null : () => _updateStatus('approved'),
                    icon: _updating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded, size: 20),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDangerOutlinedButton(
                    onPressed: _updating ? null : () => _updateStatus('rejected'),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          AppDangerOutlinedButton(
            onPressed: _updating ? null : _confirmAndDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: const Text('Delete review', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
