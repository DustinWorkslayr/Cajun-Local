import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_bar_widget.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: const AppBarWidget(title: 'Notifications', showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // "Today" Section
          _buildSectionHeader('Today', theme),
          const SizedBox(height: 16),
          _buildNotificationCard(
            title: 'Review Approved',
            body: 'Your detailed review for "The Glass Bistro" has been verified and published by our curators.',
            timeAgo: '2h',
            icon: Icons.check_circle_outline,
            isUnread: true,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            title: 'New Member Deal',
            body: 'Exclusive 15% off at "Nordic Scents" for Top Curators this weekend. Don\'t miss out!',
            timeAgo: '5h',
            icon: Icons.local_offer_outlined,
            isUnread: true,
            theme: theme,
          ),

          const SizedBox(height: 32),

          // "Yesterday" Section
          _buildSectionHeader('Yesterday', theme),
          const SizedBox(height: 16),
          _buildNotificationCard(
            title: 'New Reply',
            body: 'The owner of "Velvet Brew" replied to your feedback: "We\'re so glad you enjoyed the roast..."',
            timeAgo: '1d',
            icon: Icons.reply_rounded,
            isUnread: false,
            theme: theme,
          ),

          const SizedBox(height: 32),

          // "Older" Section
          _buildSectionHeader('Older', theme),
          const SizedBox(height: 16),
          _buildNotificationCard(
            title: 'Review Milestone',
            body: 'Your curation of "Minimalist Morning" has reached 500 helpful votes! You\'ve earned a new badge.',
            timeAgo: '3d',
            icon: Icons.emoji_events_outlined,
            isUnread: false,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            title: 'New Follower',
            body: 'Julian Rivers started following your taste profile.',
            timeAgo: '1w',
            icon: Icons.person_add_outlined,
            isUnread: false,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.specOnSurfaceVariant, // on_surface_variant
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String body,
    required String timeAgo,
    required IconData icon,
    required bool isUnread,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      // No-Line Rule: Layout boundaries must be established solely through background shifts
      decoration: BoxDecoration(
        color: AppTheme.specWhite, // surface_container_lowest
        borderRadius: BorderRadius.circular(16), // sm or greater
        boxShadow: [
          BoxShadow(color: AppTheme.specOnSurface.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Hub circular icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.specSurfaceContainerLow, // surface_container_low
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppTheme.specNavy, // primary
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                          color: AppTheme.specOnSurface, // on_surface
                        ),
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.specOnSurfaceVariant, // on_surface_variant
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.specOnSurfaceVariant, // on_surface_variant
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 12),
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.specNavy, // primary
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
