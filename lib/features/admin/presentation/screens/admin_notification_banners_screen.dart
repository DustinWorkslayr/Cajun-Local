import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/notification_banner.dart';
import 'package:my_app/core/data/repositories/notification_banners_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/screens/admin_add_notification_banner_screen.dart';
import 'package:my_app/features/admin/presentation/widgets/admin_shared.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

class AdminNotificationBannersScreen extends StatefulWidget {
  const AdminNotificationBannersScreen({
    super.key,
    this.embeddedInShell = false,
    this.hideFab = false,
  });

  final bool embeddedInShell;
  /// When true and [embeddedInShell] is true, the FAB is not shown (e.g. when used inside Manage banners tabs).
  final bool hideFab;

  @override
  State<AdminNotificationBannersScreen> createState() =>
      _AdminNotificationBannersScreenState();
}

class _AdminNotificationBannersScreenState
    extends State<AdminNotificationBannersScreen> {
  int _refreshKey = 0;

  void _openAddBanner(BuildContext context) {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
              builder: (_) => const AdminAddNotificationBannerScreen()),
        )
        .then((_) => setState(() => _refreshKey++));
  }

  void _openDetail(BuildContext context, NotificationBanner b) {
    AdminDetailPanel.show(
      context: context,
      title: 'Notification banner',
      child: _NotificationBannerPanelContent(
        banner: b,
        onUpdated: () => setState(() => _refreshKey++),
      ),
    ).then((_) => setState(() => _refreshKey++));
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final repo = NotificationBannersRepository();
    return FutureBuilder<List<NotificationBanner>>(
      key: ValueKey(_refreshKey),
      future: repo.list(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.specNavy));
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No notification banners.',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final b = list[index];
            final messagePreview = b.message.length > 90
                ? '${b.message.substring(0, 90)}…'
                : b.message;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AdminListCard(
                title: b.title,
                subtitle: messagePreview,
                badges: [
                  AdminBadgeData(
                    b.isActive ? 'Active' : 'Inactive',
                    color: b.isActive ? null : AppTheme.specRed,
                  ),
                ],
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.specGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: AppTheme.specNavy,
                    size: 26,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openDetail(context, b),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInShell) {
      return Stack(
        children: [
          _buildBody(context),
          if (!widget.hideFab)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () => _openAddBanner(context),
                tooltip: 'Add notification banner',
                child: const Icon(Icons.add_rounded),
              ),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification banners'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add notification banner',
            onPressed: () => _openAddBanner(context),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }
}

/// Detail/edit panel for a single notification banner (Save + Delete).
class _NotificationBannerPanelContent extends StatefulWidget {
  const _NotificationBannerPanelContent({
    required this.banner,
    required this.onUpdated,
  });

  final NotificationBanner banner;
  final VoidCallback onUpdated;

  @override
  State<_NotificationBannerPanelContent> createState() =>
      _NotificationBannerPanelContentState();
}

class _NotificationBannerPanelContentState
    extends State<_NotificationBannerPanelContent> {
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.banner.title);
    _messageController =
        TextEditingController(text: widget.banner.message);
    _isActive = widget.banner.isActive;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await NotificationBannersRepository().update(widget.banner.id, {
        'title': title,
        'message': message,
        'is_active': _isActive,
      });
      if (mounted) {
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner updated')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteBanner() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete banner?'),
        content: const Text(
          'This notification banner will be removed. This cannot be undone.',
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
    setState(() => _saving = true);
    try {
      await NotificationBannersRepository().delete(widget.banner.id);
      if (mounted) {
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner deleted')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = widget.banner;

    return SingleChildScrollView(
      padding: AppLayout.padding(context, top: 20, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminDetailLabel('Status'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminBadge(
                label: b.isActive ? 'Active' : 'Inactive',
                color: b.isActive ? null : AppTheme.specRed,
              ),
              if (b.createdAt != null)
                AdminBadge(
                  label:
                      'Created ${b.createdAt!.month}/${b.createdAt!.day}/${b.createdAt!.year}',
                ),
            ],
          ),
          const SizedBox(height: 24),
          AdminDetailLabel('Title'),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: AppTheme.specWhite,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          AdminDetailLabel('Message'),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: AppTheme.specWhite,
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Active',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.specNavy,
              ),
            ),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeThumbColor: AppTheme.specGold,
          ),
          const SizedBox(height: 24),
          AppSecondaryButton(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(_saving ? 'Saving…' : 'Save changes'),
          ),
          const SizedBox(height: 16),
          AppDangerOutlinedButton(
            onPressed: _saving ? null : _deleteBanner,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: const Text('Delete banner'),
          ),
        ],
      ),
    );
  }
}
