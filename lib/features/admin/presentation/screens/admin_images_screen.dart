import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/models/business_image.dart';
import 'package:my_app/core/data/repositories/audit_log_repository.dart';
import 'package:my_app/core/data/repositories/business_images_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/screens/admin_add_image_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_business_detail_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_image_detail_screen.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin images: grouped by business. Pending first; approve per image, per business, or all.
class AdminImagesScreen extends StatefulWidget {
  const AdminImagesScreen({
    super.key,
    this.status,
    this.embeddedInShell = false,
  });

  final String? status;
  final bool embeddedInShell;

  @override
  State<AdminImagesScreen> createState() => _AdminImagesScreenState();
}

class _AdminImagesScreenState extends State<AdminImagesScreen> {
  List<BusinessImage>? _images;
  Map<String, String> _businessNameById = {};
  String? _businessesError;
  bool _loading = true;
  String? _error;
  bool _approving = false;

  /// Load images first so we can show something even if businesses fetch fails (e.g. Failed to fetch).
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _businessesError = null;
    });
    final imagesRepo = BusinessImagesRepository();
    final businessRepo = BusinessRepository();

    List<BusinessImage> list;
    try {
      list = await imagesRepo.listForAdmin(status: widget.status);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
          _images = null;
        });
      }
      return;
    }

    Map<String, String> nameById = {};
    try {
      final businesses = await businessRepo.listForAdmin();
      nameById = {for (final b in businesses) b.id: b.name};
    } catch (e) {
      if (mounted) _businessesError = e.toString();
    }

    if (mounted) {
      setState(() {
        _images = list;
        _businessNameById = nameById;
        _loading = false;
      });
    }
  }

  void _openAddImage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AdminAddImageScreen()),
    ).then((_) => _load());
  }

  Future<void> _approveImages(List<String> ids) async {
    if (ids.isEmpty) return;
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null) return;
    setState(() => _approving = true);
    try {
      await BusinessImagesRepository().approveMany(ids, approvedBy: uid);
      AuditLogRepository().insert(
        action: 'images_bulk_approved',
        userId: uid,
        targetTable: 'business_images',
        details: ids.join(','),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ids.length} image${ids.length == 1 ? '' : 's'} approved')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  /// Group images by business; optionally only pending. Returns map businessId -> list of images.
  Map<String, List<BusinessImage>> _groupByBusiness(List<BusinessImage> list, {bool pendingOnly = false}) {
    final filtered = pendingOnly ? list.where((i) => i.status == 'pending').toList() : list;
    final map = <String, List<BusinessImage>>{};
    for (final img in filtered) {
      map.putIfAbsent(img.businessId, () => []).add(img);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInShell) {
      return Stack(
        children: [
          _buildBody(context),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _openAddImage,
              tooltip: 'Add image',
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: Text(widget.status != null ? 'Images (${widget.status})' : 'Images'),
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add image',
            onPressed: _openAddImage,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    if (_loading && _images == null) {
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

    final list = _images ?? [];
    final groupedPending = _groupByBusiness(list, pendingOnly: true);
    final totalPending = list.where((i) => i.status == 'pending').length;

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
                    'Images by business',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.specNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    list.isEmpty
                        ? 'No images'
                        : totalPending > 0
                            ? '$totalPending pending in ${groupedPending.length} business${groupedPending.length == 1 ? '' : 'es'}. Approve per business or all at once.'
                            : '${list.length} image${list.length == 1 ? '' : 's'} total.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.75),
                    ),
                  ),
                  if (_businessesError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Business names unavailable: $_businessesError',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (totalPending > 0) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: AppPrimaryButton(
                        onPressed: _approving
                            ? null
                            : () => _approveImages(list.where((i) => i.status == 'pending').map((i) => i.id).toList()),
                        expanded: true,
                        icon: _approving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 22),
                        label: Text('Approve all pending ($totalPending)'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  widget.status != null ? 'No ${widget.status} images.' : 'No images.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else if (groupedPending.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding.left, 24, padding.right, 24),
                child: Center(
                  child: Text(
                    'No pending images. All ${list.length} image${list.length == 1 ? '' : 's'} approved.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final businessIds = groupedPending.keys.toList();
                  if (index >= businessIds.length) return null;
                  final businessId = businessIds[index];
                  final groupImages = groupedPending[businessId]!;
                  final businessName = _businessNameById[businessId] ?? businessId;
                  return _BusinessImageGroup(
                    businessId: businessId,
                    businessName: businessName,
                    images: groupImages,
                    approving: _approving,
                    onApproveOne: (id) => _approveImages([id]),
                    onApproveAll: () => _approveImages(groupImages.map((i) => i.id).toList()),
                    onTapImage: (img) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AdminImageDetailScreen(imageId: img.id),
                        ),
                      ).then((_) => _load());
                    },
                    onOpenBusiness: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AdminBusinessDetailScreen(businessId: businessId),
                        ),
                      );
                    },
                  );
                },
                childCount: groupedPending.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _BusinessImageGroup extends StatelessWidget {
  const _BusinessImageGroup({
    required this.businessId,
    required this.businessName,
    required this.images,
    required this.approving,
    required this.onApproveOne,
    required this.onApproveAll,
    required this.onTapImage,
    required this.onOpenBusiness,
  });

  final String businessId;
  final String businessName;
  final List<BusinessImage> images;
  final bool approving;
  final void Function(String id) onApproveOne;
  final VoidCallback onApproveAll;
  final void Function(BusinessImage img) onTapImage;
  final VoidCallback onOpenBusiness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.1)),
            ),
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
                            businessName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.specNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${images.length} pending image${images.length == 1 ? '' : 's'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.specNavy.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onOpenBusiness,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Business'),
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
                      label: Text('Approve all (${images.length})'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossCount = width > 600 ? 4 : (width > 400 ? 3 : 2);
                    const gap = 8.0;
                    final size = (width - (crossCount - 1) * gap) / crossCount;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: images.map((img) {
                        return SizedBox(
                          width: size,
                          height: size + 36,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => onTapImage(img),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          img.url,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            color: AppTheme.specGold.withValues(alpha: 0.2),
                                            child: Icon(Icons.broken_image_rounded, color: AppTheme.specNavy, size: 28),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Material(
                                          color: AppTheme.specGold,
                                          borderRadius: BorderRadius.circular(20),
                                          child: InkWell(
                                            onTap: approving ? null : () => onApproveOne(img.id),
                                            borderRadius: BorderRadius.circular(20),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Icon(Icons.check_rounded, size: 18, color: AppTheme.specNavy),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Approve',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.specNavy.withValues(alpha: 0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
