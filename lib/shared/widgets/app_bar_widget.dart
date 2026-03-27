import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/theme.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onBack,
    this.actions = const [],
    this.toolbarHeight = 60,
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
      toolbarHeight: 60,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Platform.isIOS || Platform.isMacOS ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_rounded,
              ),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
              tooltip: 'Back',
              color: AppTheme.specNavy,
            )
          : Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Menu',
                color: AppTheme.specNavy,
              ),
            ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppTheme.specNavy,
        ),
      ),
      centerTitle: false,
      actions: actions,
      scrolledUnderElevation: 1,
      shadowColor: const Color(0xFF191C1D).withValues(alpha: 0.04),
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.specNavy,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: showBackButton ? 0 : 8,
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
