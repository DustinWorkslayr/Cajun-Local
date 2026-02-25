import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/models/business_category.dart';
import 'package:my_app/core/data/models/category_banner.dart';
import 'package:my_app/core/data/repositories/audit_log_repository.dart';
import 'package:my_app/core/data/repositories/category_banners_repository.dart';
import 'package:my_app/core/data/repositories/category_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/screens/admin_add_category_banner_screen.dart';
import 'package:my_app/features/admin/presentation/widgets/admin_shared.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

class AdminCategoryBannersScreen extends StatefulWidget {
  const AdminCategoryBannersScreen({
    super.key,
    this.status,
    this.embeddedInShell = false,
    this.hideFab = false,
  });

  final String? status;
  final bool embeddedInShell;
  /// When true and [embeddedInShell] is true, the FAB is not shown (e.g. when used inside Manage banners tabs).
  final bool hideFab;

  @override
  State<AdminCategoryBannersScreen> createState() => _AdminCategoryBannersScreenState();
}

class _AdminCategoryBannersScreenState extends State<AdminCategoryBannersScreen> {
  int _refreshKey = 0;

  void _openAddBanner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AdminAddCategoryBannerScreen()),
    ).then((_) => setState(() => _refreshKey++));
  }

  void _openDetail(CategoryBanner b, [String? categoryName]) {
    AdminDetailPanel.show(
      context: context,
      title: categoryName != null ? 'Banner · $categoryName' : 'Category banner',
      child: _CategoryBannerPanelContent(
        banner: b,
        onUpdated: () => setState(() => _refreshKey++),
      ),
    ).then((_) => setState(() => _refreshKey++));
  }

  Future<({List<BusinessCategory> categories, List<CategoryBanner> banners})> _loadData() async {
    final bannersRepo = CategoryBannersRepository();
    final categoriesRepo = CategoryRepository();
    final results = await Future.wait([
      categoriesRepo.listCategories(),
      bannersRepo.listForAdmin(status: widget.status),
    ]);
    return (
      categories: results[0] as List<BusinessCategory>,
      banners: results[1] as List<CategoryBanner>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    Widget body = Container(
      color: AppTheme.specOffWhite,
      child: FutureBuilder<({List<BusinessCategory> categories, List<CategoryBanner> banners})>(
        key: ValueKey(_refreshKey),
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.specNavy));
          }
          final data = snapshot.data;
          final categories = data?.categories ?? [];
          final list = data?.banners ?? [];
          final categoryNames = {for (final c in categories) c.id: c.name};

          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dashboard_customize_rounded, size: 64, color: AppTheme.specNavy.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      widget.status != null ? 'No ${widget.status} banners' : 'No category banners yet',
                      style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.specNavy),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a banner to show on category explore screens.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Group banners by categoryId; sort categories by name, uncategorized last
          final grouped = <String, List<CategoryBanner>>{};
          for (final b in list) {
            grouped.putIfAbsent(b.categoryId, () => []).add(b);
          }
          final categoryOrder = categories.map((c) => c.id).toList();
          final sortedCategoryIds = grouped.keys.toList()
            ..sort((a, b) {
              final aInOrder = categoryOrder.indexOf(a);
              final bInOrder = categoryOrder.indexOf(b);
              if (aInOrder >= 0 && bInOrder >= 0) return aInOrder.compareTo(bInOrder);
              if (aInOrder >= 0) return -1;
              if (bInOrder >= 0) return 1;
              return (categoryNames[a] ?? a).compareTo(categoryNames[b] ?? b);
            });

          return Column(
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
                        widget.status != null ? 'Banners · ${widget.status}' : 'All category banners',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.specNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${list.length} banner${list.length == 1 ? '' : 's'} in ${sortedCategoryIds.length} categor${sortedCategoryIds.length == 1 ? 'y' : 'ies'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 24),
                  itemCount: sortedCategoryIds.length,
                  itemBuilder: (context, groupIndex) {
                    final categoryId = sortedCategoryIds[groupIndex];
                    final banners = grouped[categoryId]!;
                    final categoryLabel = categoryNames[categoryId] ?? categoryId;
                    final isUncategorized = !categoryNames.containsKey(categoryId);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 10),
                            child: Row(
                              children: [
                                Icon(
                                  isUncategorized ? Icons.category_rounded : Icons.label_rounded,
                                  size: 20,
                                  color: AppTheme.specGold,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isUncategorized ? 'Uncategorized' : categoryLabel,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.specNavy,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.specNavy.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${banners.length}',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.specNavy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...banners.map((b) => _BannerCard(
                                banner: b,
                                categoryLabel: categoryLabel,
                                onTap: () => _openDetail(b, categoryLabel),
                                onStatusUpdated: () => setState(() => _refreshKey++),
                              )),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );

    if (widget.embeddedInShell) {
      return Stack(
        children: [
          body,
          if (!widget.hideFab)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _openAddBanner,
                tooltip: 'Add category banner',
                backgroundColor: AppTheme.specNavy,
                child: const Icon(Icons.add_rounded),
              ),
            ),
        ],
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: Text(widget.status != null ? 'Category banners (${widget.status})' : 'Category banners'),
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add category banner',
            onPressed: _openAddBanner,
          ),
        ],
      ),
      body: body,
    );
  }
}

/// Single banner card: image, status, date, quick actions when pending.
class _BannerCard extends StatefulWidget {
  const _BannerCard({
    required this.banner,
    required this.categoryLabel,
    required this.onTap,
    required this.onStatusUpdated,
  });

  final CategoryBanner banner;
  final String categoryLabel;
  final VoidCallback onTap;
  final VoidCallback onStatusUpdated;

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  bool _updating = false;

  Future<void> _setStatus(String status) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      final repo = CategoryBannersRepository();
      final uid = AppDataScope.of(context).authRepository.currentUserId;
      await repo.updateStatus(widget.banner.id, status, approvedBy: uid);
      AuditLogRepository().insert(
        action: status == 'approved' ? 'banner_approved' : 'banner_rejected',
        userId: uid,
        targetTable: 'category_banners',
        targetId: widget.banner.id,
      );
      if (mounted) {
        widget.onStatusUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banner ${status == 'approved' ? 'approved' : 'rejected'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = widget.banner;
    final dateStr = b.createdAt != null
        ? '${b.createdAt!.month}/${b.createdAt!.day}/${b.createdAt!.year}'
        : null;
    final statusColor = b.status == 'pending'
        ? AppTheme.specGold
        : b.status == 'approved'
            ? Colors.green.shade700
            : AppTheme.specRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    b.imageUrl,
                    width: 80,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 80,
                      height: 56,
                      color: AppTheme.specGold.withValues(alpha: 0.2),
                      child: Icon(Icons.perm_media_rounded, color: AppTheme.specNavy, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              b.status.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                          if (dateStr != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              dateStr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.specNavy.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (b.status == 'pending') ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            SizedBox(
                              height: 32,
                              child: FilledButton.tonalIcon(
                                onPressed: _updating ? null : () => _setStatus('approved'),
                                icon: _updating
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                                      )
                                    : const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Approve'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 32,
                              child: AppDangerOutlinedButton(
                                onPressed: _updating ? null : () => _setStatus('rejected'),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text('Reject'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slide-out panel content: user-friendly info, status badge, image preview, inline edit.
class _CategoryBannerPanelContent extends StatefulWidget {
  const _CategoryBannerPanelContent({
    required this.banner,
    required this.onUpdated,
  });

  final CategoryBanner banner;
  final VoidCallback onUpdated;

  @override
  State<_CategoryBannerPanelContent> createState() => _CategoryBannerPanelContentState();
}

class _CategoryBannerPanelContentState extends State<_CategoryBannerPanelContent> {
  late TextEditingController _categoryIdController;
  late TextEditingController _imageUrlController;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _categoryIdController = TextEditingController(text: widget.banner.categoryId);
    _imageUrlController = TextEditingController(text: widget.banner.imageUrl);
  }

  @override
  void dispose() {
    _categoryIdController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveFields() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final repo = CategoryBannersRepository();
      await repo.update(
        widget.banner.id,
        categoryId: _categoryIdController.text.trim().isEmpty ? null : _categoryIdController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      );
      if (mounted) {
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
      }
    } catch (e) {
      if (mounted) setState(() => _saveError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    final repo = CategoryBannersRepository();
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    await repo.updateStatus(widget.banner.id, status, approvedBy: uid);
    AuditLogRepository().insert(
      action: status == 'approved' ? 'banner_approved' : 'banner_rejected',
      userId: uid,
      targetTable: 'category_banners',
      targetId: widget.banner.id,
    );
    if (mounted) {
      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status set to $status')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteBanner() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete banner?'),
        content: const Text(
          'This category banner will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          AppDangerButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await CategoryBannersRepository().delete(widget.banner.id);
      if (mounted) {
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner deleted')));
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final b = widget.banner;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status badge
          AdminDetailLabel('Status'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminBadge(
                label: b.status,
                color: b.status == 'pending' ? AppTheme.specRed : (b.status == 'rejected' ? AppTheme.specRed : null),
              ),
              if (b.createdAt != null)
                AdminBadge(
                  label: 'Added ${b.createdAt!.month}/${b.createdAt!.day}/${b.createdAt!.year}',
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Preview
          AdminDetailLabel('Preview'),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: b.imageUrl.isNotEmpty
                ? Image.network(
                    b.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _PreviewPlaceholder(message: 'Image failed to load'),
                  )
                : const _PreviewPlaceholder(message: 'No image URL'),
          ),
          const SizedBox(height: 24),

          // Inline edit: Category
          AdminDetailLabel('Category ID'),
          TextFormField(
            controller: _categoryIdController,
            decoration: InputDecoration(
              hintText: 'e.g. restaurants',
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: theme.textTheme.bodyLarge,
            onChanged: (_) => setState(() => _saveError = null),
          ),
          const SizedBox(height: 16),

          // Inline edit: Image URL
          AdminDetailLabel('Image URL'),
          TextFormField(
            controller: _imageUrlController,
            decoration: InputDecoration(
              hintText: 'https://…',
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
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
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          AppSecondaryButton(
            onPressed: _saving ? null : _saveFields,
            icon: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary),
                  )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(_saving ? 'Saving…' : 'Save changes'),
          ),

          // Approve / Reject when pending
          if (b.status == 'pending') ...[
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),
            AdminDetailLabel('Moderation'),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    onPressed: () => _updateStatus('approved'),
                    expanded: true,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDangerOutlinedButton(
                    onPressed: () => _updateStatus('rejected'),
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
            onPressed: _saving ? null : _deleteBanner,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: const Text('Delete banner'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.specNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.perm_media_rounded, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.specNavy.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
