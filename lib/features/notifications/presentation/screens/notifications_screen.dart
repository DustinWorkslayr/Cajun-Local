import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/models/app_notification.dart';
import 'package:my_app/core/data/repositories/notifications_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';

/// Per-user notifications list. Tap to mark as read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _list = [];
  bool _loading = true;

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
    final list = await NotificationsRepository().listForUser(uid);
    if (mounted) {
      setState(() {
        _list = list;
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (n.isRead) return;
    await NotificationsRepository().markAsRead(n.id);
    if (mounted) {
      setState(() {
        _list = _list.map((e) => e.id == n.id ? AppNotification(
          id: e.id,
          userId: e.userId,
          title: e.title,
          type: e.type,
          isRead: true,
          createdAt: e.createdAt,
        ) : e).toList();
      });
    }
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) {
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${d.month}/${d.day}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 64, color: AppTheme.specNavy.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.specNavy),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ll notify you here when something happens.',
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
                    itemCount: _list.length,
                    itemBuilder: (context, index) {
                      final n = _list[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _markAsRead(n),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: n.isRead
                                  ? AppTheme.specNavy.withValues(alpha: 0.04)
                                  : AppTheme.specNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.specNavy.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  n.isRead ? Icons.notifications_none_rounded : Icons.notifications_rounded,
                                  size: 22,
                                  color: n.isRead
                                      ? AppTheme.specNavy.withValues(alpha: 0.5)
                                      : AppTheme.specGold,
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
                                      if (n.type != null && n.type!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          n.type!,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: AppTheme.specNavy.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                      if (n.createdAt != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(n.createdAt),
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: AppTheme.specNavy.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
