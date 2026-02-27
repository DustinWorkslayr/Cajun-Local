import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/models/business.dart';
import 'package:my_app/core/data/models/business_event.dart';
import 'package:my_app/core/data/models/business_image.dart';
import 'package:my_app/core/data/models/deal.dart';
import 'package:my_app/core/data/repositories/audit_log_repository.dart';
import 'package:my_app/core/data/repositories/business_events_repository.dart';
import 'package:my_app/core/data/repositories/business_images_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/deals_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/screens/admin_business_detail_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_image_detail_screen.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Per-business pending items (images, deals, events).
class _BusinessPending {
  _BusinessPending({
    required this.businessId,
    required this.businessName,
    required this.images,
    required this.deals,
    required this.events,
  });

  final String businessId;
  final String businessName;
  final List<BusinessImage> images;
  final List<Deal> deals;
  final List<BusinessEvent> events;

  int get totalCount => images.length + deals.length + events.length;
}

/// Admin: one business-centric screen for all pending approvals (images + deals + events).
/// Slide-out per business with Approve / Reject / Request info; bulk approval.
class AdminPendingApprovalsScreen extends StatefulWidget {
  const AdminPendingApprovalsScreen({
    super.key,
    this.status,
    this.embeddedInShell = false,
  });

  final String? status;
  final bool embeddedInShell;

  @override
  State<AdminPendingApprovalsScreen> createState() =>
      _AdminPendingApprovalsScreenState();
}

class _AdminPendingApprovalsScreenState extends State<AdminPendingApprovalsScreen> {
  List<_BusinessPending>? _businesses;
  bool _loading = true;
  String? _error;
  bool _approving = false;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final imagesRepo = BusinessImagesRepository();
    final dealsRepo = DealsRepository();
    final eventsRepo = BusinessEventsRepository();
    final businessRepo = BusinessRepository();

    try {
      final results = await Future.wait([
        imagesRepo.listForAdmin(status: 'pending'),
        dealsRepo.listForAdmin(status: 'pending'),
        eventsRepo.listForAdmin(status: 'pending'),
        businessRepo.listForAdmin(),
      ]);
      final pendingImages = results[0] as List<BusinessImage>;
      final pendingDeals = results[1] as List<Deal>;
      final pendingEvents = results[2] as List<BusinessEvent>;
      final allBusinesses = results[3] as List<Business>;
      final nameById = {for (final b in allBusinesses) b.id: b.name};

      final byBusiness = <String, _BusinessPending>{};
      void addImage(BusinessImage img) {
        byBusiness.putIfAbsent(
          img.businessId,
          () => _BusinessPending(
            businessId: img.businessId,
            businessName: nameById[img.businessId] ?? img.businessId,
            images: [],
            deals: [],
            events: [],
          ),
        ).images.add(img);
      }
      void addDeal(Deal d) {
        byBusiness.putIfAbsent(
          d.businessId,
          () => _BusinessPending(
            businessId: d.businessId,
            businessName: nameById[d.businessId] ?? d.businessId,
            images: [],
            deals: [],
            events: [],
          ),
        ).deals.add(d);
      }
      void addEvent(BusinessEvent e) {
        byBusiness.putIfAbsent(
          e.businessId,
          () => _BusinessPending(
            businessId: e.businessId,
            businessName: nameById[e.businessId] ?? e.businessId,
            images: [],
            deals: [],
            events: [],
          ),
        ).events.add(e);
      }
      for (final img in pendingImages) {
        addImage(img);
      }
      for (final d in pendingDeals) {
        addDeal(d);
      }
      for (final e in pendingEvents) {
        addEvent(e);
      }

      final list = byBusiness.values.where((b) => b.totalCount > 0).toList();
      list.sort((a, b) => b.totalCount.compareTo(a.totalCount));

      if (mounted) {
        setState(() {
          _businesses = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
          _businesses = null;
        });
      }
    }
  }

  int get _totalPending {
    final list = _businesses ?? [];
    return list.fold<int>(0, (sum, b) => sum + b.totalCount);
  }

  Future<void> _bulkApproveAll() async {
    final list = _businesses ?? [];
    if (list.isEmpty) return;
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null) return;
    setState(() => _approving = true);
    final imagesRepo = BusinessImagesRepository();
    final dealsRepo = DealsRepository();
    final eventsRepo = BusinessEventsRepository();
    final auditRepo = AuditLogRepository();
    try {
      for (final b in list) {
        if (b.images.isNotEmpty) {
          await imagesRepo.approveMany(
            b.images.map((i) => i.id).toList(),
            approvedBy: uid,
          );
          auditRepo.insert(
            action: 'images_bulk_approved',
            userId: uid,
            targetTable: 'business_images',
            details: b.images.map((i) => i.id).join(','),
          );
        }
        for (final d in b.deals) {
          await dealsRepo.updateStatus(d.id, 'approved', approvedBy: uid);
          auditRepo.insert(
            action: 'deal_approved',
            userId: uid,
            targetTable: 'deals',
            targetId: d.id,
          );
        }
        for (final e in b.events) {
          await eventsRepo.updateStatus(e.id, 'approved', approvedBy: uid);
          auditRepo.insert(
            action: 'event_approved',
            userId: uid,
            targetTable: 'business_events',
            targetId: e.id,
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approved $_totalPending pending item${_totalPending == 1 ? '' : 's'}')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  void _openSlideOut(_BusinessPending business) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PendingSlideOut(
        business: business,
        onClose: () => Navigator.of(ctx).pop(),
        onApproveAll: () async {
          final uid = AppDataScope.of(context).authRepository.currentUserId;
          if (uid == null) return;
          final imagesRepo = BusinessImagesRepository();
          final dealsRepo = DealsRepository();
          final eventsRepo = BusinessEventsRepository();
          final auditRepo = AuditLogRepository();
          try {
            if (business.images.isNotEmpty) {
              await imagesRepo.approveMany(
                business.images.map((i) => i.id).toList(),
                approvedBy: uid,
              );
              auditRepo.insert(
                action: 'images_bulk_approved',
                userId: uid,
                targetTable: 'business_images',
                targetId: business.businessId,
                details: business.images.length.toString(),
              );
            }
            for (final d in business.deals) {
              await dealsRepo.updateStatus(d.id, 'approved', approvedBy: uid);
              auditRepo.insert(
                action: 'deal_approved',
                userId: uid,
                targetTable: 'deals',
                targetId: d.id,
              );
            }
            for (final e in business.events) {
              await eventsRepo.updateStatus(e.id, 'approved', approvedBy: uid);
              auditRepo.insert(
                action: 'event_approved',
                userId: uid,
                targetTable: 'business_events',
                targetId: e.id,
              );
            }
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('All approved for this business')),
              );
              Navigator.of(ctx).pop();
              _load();
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
        onRefresh: _load,
      ),
    ).then((_) => _load());
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    if (widget.embeddedInShell) {
      return _buildBody(context, theme, padding);
    }
    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: const Text('Pending approvals'),
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(context, theme, padding),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    EdgeInsets padding,
  ) {
    if (_loading && _businesses == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.specNavy));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final list = _businesses ?? [];
    final total = _totalPending;

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding.left, 20, padding.right, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pending by business',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.specNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    list.isEmpty
                        ? 'No pending items'
                        : '$total pending in ${list.length} business${list.length == 1 ? '' : 'es'}. Open a business to approve individually or in bulk.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.75),
                    ),
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: AppPrimaryButton(
                        onPressed: _approving ? null : _bulkApproveAll,
                        expanded: true,
                        icon: _approving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 22),
                        label: Text('Approve all pending ($total)'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No pending approvals')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final business = list[index];
                  final scaffoldContext = this.context;
                  return _BusinessPendingCard(
                    business: business,
                    approving: _approving,
                    onOpen: () => _openSlideOut(business),
                    onApproveAll: () async {
                      final state = this;
                      setState(() => _approving = true);
                      try {
                        final uid = AppDataScope.of(scaffoldContext).authRepository.currentUserId;
                        if (uid == null) return;
                        final imagesRepo = BusinessImagesRepository();
                        final dealsRepo = DealsRepository();
                        final eventsRepo = BusinessEventsRepository();
                        final auditRepo = AuditLogRepository();
                        if (business.images.isNotEmpty) {
                          await imagesRepo.approveMany(
                            business.images.map((i) => i.id).toList(),
                            approvedBy: uid,
                          );
                          auditRepo.insert(
                            action: 'images_bulk_approved',
                            userId: uid,
                            targetTable: 'business_images',
                            details: business.images.map((i) => i.id).join(','),
                          );
                        }
                        for (final d in business.deals) {
                          await dealsRepo.updateStatus(d.id, 'approved', approvedBy: uid);
                          auditRepo.insert(
                            action: 'deal_approved',
                            userId: uid,
                            targetTable: 'deals',
                            targetId: d.id,
                          );
                        }
                        for (final e in business.events) {
                          await eventsRepo.updateStatus(e.id, 'approved', approvedBy: uid);
                          auditRepo.insert(
                            action: 'event_approved',
                            userId: uid,
                            targetTable: 'business_events',
                            targetId: e.id,
                          );
                        }
                        if (state.mounted) {
                          ScaffoldMessenger.maybeOf(state.context)?.showSnackBar(
                            SnackBar(content: Text('Approved ${business.totalCount} for ${business.businessName}')),
                          );
                          _load();
                        }
                      } finally {
                        if (state.mounted) setState(() => _approving = false);
                      }
                    },
                  );
                },
                childCount: list.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _BusinessPendingCard extends StatelessWidget {
  const _BusinessPendingCard({
    required this.business,
    required this.approving,
    required this.onOpen,
    required this.onApproveAll,
  });

  final _BusinessPending business;
  final bool approving;
  final VoidCallback onOpen;
  final VoidCallback onApproveAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final parts = <String>[];
    if (business.images.isNotEmpty) parts.add('${business.images.length} image${business.images.length == 1 ? '' : 's'}');
    if (business.deals.isNotEmpty) parts.add('${business.deals.length} deal${business.deals.length == 1 ? '' : 's'}');
    if (business.events.isNotEmpty) parts.add('${business.events.length} event${business.events.length == 1 ? '' : 's'}');
    final subtitle = parts.join(', ');

    return Padding(
      padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.1)),
        ),
        color: AppTheme.specWhite,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.businessName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.specNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.specNavy.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open'),
                  ),
                  const SizedBox(width: 8),
                  AppSecondaryButton(
                    onPressed: approving ? null : onApproveAll,
                    icon: approving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text('Approve all (${business.totalCount})'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingSlideOut extends StatefulWidget {
  const _PendingSlideOut({
    required this.business,
    required this.onClose,
    required this.onApproveAll,
    required this.onRefresh,
  });

  final _BusinessPending business;
  final VoidCallback onClose;
  final VoidCallback onApproveAll;
  final VoidCallback onRefresh;

  @override
  State<_PendingSlideOut> createState() => _PendingSlideOutState();
}

class _PendingSlideOutState extends State<_PendingSlideOut> {
  bool _approving = false;

  Future<void> _requestInfo({
    required String targetTable,
    required String targetId,
    required String label,
  }) async {
    final controller = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Message for business owner about "$label":',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Please upload a clearer proof of ownership.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send request'),
          ),
        ],
      ),
    );
    if (submitted == true && controller.text.trim().isNotEmpty) {
      if (!mounted) return;
      final userId = AppDataScope.of(context).authRepository.currentUserId;
      await AuditLogRepository().insert(
        action: 'approval_request_info',
        userId: userId,
        targetTable: targetTable,
        targetId: targetId,
        details: controller.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent')),
        );
      }
    }
  }

  Future<void> _approveImage(String id) async {
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null) return;
    setState(() => _approving = true);
    try {
      await BusinessImagesRepository().approveMany([id], approvedBy: uid);
      AuditLogRepository().insert(
        action: 'image_approved',
        userId: uid,
        targetTable: 'business_images',
        targetId: id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image approved')));
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _rejectImage(String id) async {
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null) return;
    setState(() => _approving = true);
    try {
      await BusinessImagesRepository().updateStatus(id, 'rejected', approvedBy: uid);
      AuditLogRepository().insert(
        action: 'image_rejected',
        userId: uid,
        targetTable: 'business_images',
        targetId: id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image rejected')));
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _approveDeal(String id) async {
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null) return;
    setState(() => _approving = true);
    try {
      await DealsRepository().updateStatus(id, 'approved', approvedBy: uid);
      AuditLogRepository().insert(
        action: 'deal_approved',
        userId: uid,
        targetTable: 'deals',
        targetId: id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deal approved')));
        widget.onRefresh();
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _rejectDeal(String id) async {
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null) return;
    setState(() => _approving = true);
    try {
      await DealsRepository().updateStatus(id, 'rejected', approvedBy: uid);
      AuditLogRepository().insert(
        action: 'deal_rejected',
        userId: uid,
        targetTable: 'deals',
        targetId: id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deal rejected')));
        widget.onRefresh();
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _approveEvent(String id) async {
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null) return;
    setState(() => _approving = true);
    try {
      await BusinessEventsRepository().updateStatus(id, 'approved', approvedBy: uid);
      AuditLogRepository().insert(
        action: 'event_approved',
        userId: uid,
        targetTable: 'business_events',
        targetId: id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event approved')));
        widget.onRefresh();
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _rejectEvent(String id) async {
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null) return;
    setState(() => _approving = true);
    try {
      await BusinessEventsRepository().updateStatus(id, 'rejected', approvedBy: uid);
      AuditLogRepository().insert(
        action: 'event_rejected',
        userId: uid,
        targetTable: 'business_events',
        targetId: id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event rejected')));
        widget.onRefresh();
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = widget.business;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.specOffWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.specNavy.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.businessName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.specNavy,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: widget.onClose,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AdminBusinessDetailScreen(businessId: b.businessId),
                          ),
                        );
                      },
                      child: const Text('Business'),
                    ),
                    AppPrimaryButton(
                      onPressed: _approving ? null : widget.onApproveAll,
                      expanded: false,
                      icon: _approving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text('Approve all'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    if (b.images.isNotEmpty) ...[
                      Text(
                        'Images',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.specNavy.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...b.images.map((img) => _ItemRow(
                            label: 'Image',
                            onView: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => AdminImageDetailScreen(imageId: img.id),
                                ),
                              ).then((_) => widget.onRefresh());
                            },
                            approve: () => _approveImage(img.id),
                            reject: () => _rejectImage(img.id),
                            requestInfo: () => _requestInfo(
                              targetTable: 'business_images',
                              targetId: img.id,
                              label: 'Image',
                            ),
                            approving: _approving,
                            thumbnail: Image.network(
                              img.url,
                              fit: BoxFit.cover,
                              width: 48,
                              height: 48,
                              errorBuilder: (_, _, _) => const Icon(Icons.image_rounded, size: 48),
                            ),
                          )),
                      const SizedBox(height: 20),
                    ],
                    if (b.deals.isNotEmpty) ...[
                      Text(
                        'Deals',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.specNavy.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...b.deals.map((d) => _ItemRow(
                            label: d.title,
                            onView: null,
                            approve: () => _approveDeal(d.id),
                            reject: () => _rejectDeal(d.id),
                            requestInfo: () => _requestInfo(
                              targetTable: 'deals',
                              targetId: d.id,
                              label: d.title,
                            ),
                            approving: _approving,
                            thumbnail: null,
                          )),
                      const SizedBox(height: 20),
                    ],
                    if (b.events.isNotEmpty) ...[
                      Text(
                        'Events',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.specNavy.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...b.events.map((e) => _ItemRow(
                            label: '${e.title} (${e.eventDate.day}/${e.eventDate.month}/${e.eventDate.year})',
                            onView: null,
                            approve: () => _approveEvent(e.id),
                            reject: () => _rejectEvent(e.id),
                            requestInfo: () => _requestInfo(
                              targetTable: 'business_events',
                              targetId: e.id,
                              label: e.title,
                            ),
                            approving: _approving,
                            thumbnail: null,
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.label,
    required this.onView,
    required this.approve,
    required this.reject,
    required this.requestInfo,
    required this.approving,
    this.thumbnail,
  });

  final String label;
  final VoidCallback? onView;
  final VoidCallback approve;
  final VoidCallback reject;
  final VoidCallback requestInfo;
  final bool approving;
  final Widget? thumbnail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (thumbnail != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: thumbnail,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.specNavy,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onView != null)
              TextButton(
                onPressed: onView,
                child: const Text('View'),
              ),
            AppDangerOutlinedButton(
              onPressed: approving ? null : reject,
              child: const Text('Reject'),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: approving ? null : requestInfo,
              child: const Text('Request info'),
            ),
            const SizedBox(width: 6),
            AppSecondaryButton(
              onPressed: approving ? null : approve,
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }
}
