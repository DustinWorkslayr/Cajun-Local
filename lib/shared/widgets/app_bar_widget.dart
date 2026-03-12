import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_logo.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onBack,
    this.actions = const [],
    this.toolbarHeight = 96,
    this.leadingWidth = 120,
    this.logoHeight = 88,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final double toolbarHeight;
  final double leadingWidth;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: toolbarHeight,
      leadingWidth: leadingWidth,
      leading: showBackButton
          ? IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: onBack, tooltip: 'Back')
          : Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Center(child: AppLogo(height: logoHeight)),
            ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Brobane',
          fontSize: 26,
          fontWeight: FontWeight.normal,
          color: AppTheme.specNavy,
        ),
      ),
      centerTitle: true,
      actions: actions,
      scrolledUnderElevation: 12,
      backgroundColor: AppTheme.specOffWhite,
      foregroundColor: AppTheme.specNavy,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}

/// App bar notification bell with optional unread badge.
class NotificationsIconWidget extends StatelessWidget {
  const NotificationsIconWidget({super.key, this.unreadFuture, required this.onOpen});

  final Future<int>? unreadFuture;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (unreadFuture == null) {
      return IconButton(
        onPressed: onOpen,
        icon: const Icon(Icons.notifications_outlined),
        color: AppTheme.specNavy,
        tooltip: 'Notifications',
      );
    }
    return FutureBuilder<int>(
      future: unreadFuture,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onOpen,
              icon: const Icon(Icons.notifications_outlined),
              color: AppTheme.specNavy,
              tooltip: 'Notifications',
            ),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.specRed, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.specWhite, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
