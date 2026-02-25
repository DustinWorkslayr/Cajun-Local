import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/notification_banner.dart';
import 'package:my_app/core/data/repositories/notification_banners_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';

/// Dismissible alert banner for home: light gold card, icon, title/message, View button, close (X).
/// Session-scoped dismiss (dismissed IDs stored in state for rest of session).
class DismissibleAlertBanner extends StatefulWidget {
  const DismissibleAlertBanner({super.key, this.horizontalPadding, this.compact = false});

  /// When set (e.g. from HomeScreen), aligns with page padding; otherwise uses AppLayout.
  final EdgeInsets? horizontalPadding;
  /// When true, reduces height (smaller padding, icon, and spacing) for placement below topbar.
  final bool compact;

  @override
  State<DismissibleAlertBanner> createState() => _DismissibleAlertBannerState();
}

class _DismissibleAlertBannerState extends State<DismissibleAlertBanner> {
  final Set<String> _dismissedIds = {};
  Future<List<NotificationBanner>>? _activeBannersFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _activeBannersFuture ??= NotificationBannersRepository().listActive();
  }

  void _dismiss(String id) {
    setState(() => _dismissedIds.add(id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<NotificationBanner>>(
      future: _activeBannersFuture,
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        final visible = list.where((b) => !_dismissedIds.contains(b.id)).toList();
        if (visible.isEmpty) return const SizedBox.shrink();

        final padding = widget.horizontalPadding ?? AppLayout.horizontalPadding(context);
        final top = widget.compact ? 4.0 : 16.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(padding.left, top, padding.right, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: visible.map((banner) => _buildCard(context, theme, banner)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    NotificationBanner banner,
  ) {
    final compact = widget.compact;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 12),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 6 : 12,
          ),
          decoration: BoxDecoration(
            color: AppTheme.specGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(compact ? 10 : 14),
            border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 28 : 36,
                height: compact ? 28 : 36,
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.specNavy,
                  size: compact ? 16 : 20,
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      banner.title,
                      style: (compact ? theme.textTheme.labelLarge : theme.textTheme.titleSmall)?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: compact ? 1 : 2),
                    Text(
                      banner.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.85),
                        fontSize: compact ? 12 : null,
                      ),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              // Optional: open link when model has link field
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.specNavy,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                            child: Text(
                              'VIEW',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.specNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: compact ? 18 : 20,
                  color: AppTheme.specNavy.withValues(alpha: 0.7),
                ),
                onPressed: () => _dismiss(banner.id),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: compact ? 28 : 32,
                  minHeight: compact ? 28 : 32,
                ),
                tooltip: 'Dismiss',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
