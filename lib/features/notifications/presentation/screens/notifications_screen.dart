import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/models/app_notification.dart';
import 'package:my_app/core/data/repositories/notifications_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Per-user notifications list: filter by type, mark read, delete, open action links.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _list = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _typeFilter; // null = All, or deal, reminder, listing, system

  static const int _pageSize = 50;
  static const List<String?> _filterOptions = [null, 'deal', 'reminder', 'listing', 'system'];
  static const List<String> _filterLabels = ['All', 'Deals', 'Reminders', 'Listings', 'System'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _list.isEmpty) _load();
  }

  Future<void> _load() async {
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final list = await NotificationsRepository().listForUser(
      uid,
      typeFilter: _typeFilter,
      limit: _pageSize,
      offset: 0,
    );
    if (mounted) {
      setState(() {
        _list = list;
        _offset = list.length;
        _hasMore = list.length >= _pageSize;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final list = await NotificationsRepository().listForUser(
      uid,
      typeFilter: _typeFilter,
      limit: _pageSize,
      offset: _offset,
    );
    if (mounted) {
      setState(() {
        _list = [..._list, ...list];
        _offset += list.length;
        _hasMore = list.length >= _pageSize;
        _loadingMore = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (n.isRead) return;
    await NotificationsRepository().markAsRead(n.id);
    if (mounted) {
      setState(() {
        _list = _list.map((e) => e.id == n.id ? e.copyWith(isRead: true) : e).toList();
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null) return;
    await NotificationsRepository().markAllAsRead(uid);
    if (mounted) {
      setState(() {
        _list = _list.map((e) => e.copyWith(isRead: true)).toList();
      });
    }
  }

  Future<void> _delete(AppNotification n) async {
    await NotificationsRepository().deleteForUser(n.id);
    if (mounted) setState(() => _list = _list.where((e) => e.id != n.id).toList());
  }

  void _onAction(AppNotification n) {
    _markAsRead(n);
    final url = n.actionUrl;
    if (url != null && url.isNotEmpty) _openUrl(url);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  static String _timeAgo(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.month}/${d.day}/${d.year}';
  }

  static IconData _iconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'deal':
        return Icons.local_offer_rounded;
      case 'reminder':
        return Icons.schedule_rounded;
      case 'listing':
        return Icons.store_rounded;
      case 'system':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    final hasUnread = _list.any((e) => !e.isRead);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppTheme.specNavy,
        ),
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
        actions: [
          if (!_loading && _list.isNotEmpty && hasUnread && uid != null)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 20),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.specNavy),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_loading && _list.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 8),
              child: Row(
                children: List.generate(_filterOptions.length, (i) {
                  final selected = _typeFilter == _filterOptions[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_filterLabels[i]),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          _typeFilter = _filterOptions[i];
                          _loading = true;
                        });
                        _load();
                      },
                      selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                      checkmarkColor: AppTheme.specNavy,
                    ),
                  );
                }),
              ),
            ),
          ],
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none_rounded, size: 64, color: AppTheme.specNavy.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              _typeFilter == null ? 'No notifications' : 'No ${_filterLabels[_filterOptions.indexOf(_typeFilter)].toLowerCase()}',
                              style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.specNavy),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _typeFilter == null
                                  ? 'We\'ll notify you here when something happens. Use Profile → Preferences to choose which types you get.'
                                  : 'Try "All" to see every notification.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 24),
                          itemCount: _list.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _list.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: _loadingMore
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : TextButton.icon(
                                          onPressed: _loadMore,
                                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                          label: const Text('Load more'),
                                        ),
                                ),
                              );
                            }
                            final n = _list[index];
                            return _NotificationTile(
                              notification: n,
                              onTap: () => _markAsRead(n),
                              onAction: n.actionUrl != null ? () => _onAction(n) : null,
                              onDelete: () => _delete(n),
                              timeAgo: _timeAgo(n.createdAt),
                              icon: _iconForType(n.type),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    this.onAction,
    required this.onDelete,
    required this.timeAgo,
    required this.icon,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final VoidCallback onDelete;
  final String timeAgo;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = notification;

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.specRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppTheme.specRed),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: n.isRead
                  ? AppTheme.specNavy.withValues(alpha: 0.04)
                  : AppTheme.specNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  n.isRead ? Icons.notifications_none_rounded : icon,
                  size: 22,
                  color: n.isRead ? AppTheme.specNavy.withValues(alpha: 0.5) : AppTheme.specGold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
                          color: AppTheme.specNavy,
                        ),
                      ),
                      if (n.body != null && n.body!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          n.body!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.specNavy.withValues(alpha: 0.75),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (n.type != null && n.type!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.specNavy.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                n.type!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.specNavy.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            if (timeAgo.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                timeAgo,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.specNavy.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ] else if (timeAgo.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specNavy.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                      if (onAction != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: onAction,
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('View'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppTheme.specGold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: AppTheme.specNavy.withValues(alpha: 0.5)),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Dismiss',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
