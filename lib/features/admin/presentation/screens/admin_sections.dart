import 'package:flutter/material.dart';
import 'package:my_app/features/admin/presentation/screens/admin_ad_packages_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_audit_log_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_blog_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_business_ads_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_businesses_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_categories_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_parishes_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_claims_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_email_templates_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_form_submissions_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_pending_approvals_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_manage_banners_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_payment_history_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_send_notification_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_reviews_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_subscriptions_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_user_roles_screen.dart';

/// Callback for in-shell navigation: index and optional status filter (e.g. 'pending').
typedef OnNavigateToSection = void Function(int index, {String? status});

/// One admin section: label, icon, optional group (for rail), and builder.
class AdminSectionItem {
  const AdminSectionItem({
    required this.label,
    required this.icon,
    this.group,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final String? group;
  final Widget Function(
    BuildContext context, {
    required bool embedded,
    String? status,
    OnNavigateToSection? onNavigateToSection,
  }) builder;
}

/// Ordered list of admin sections. Index 0 = Dashboard, 1 = Businesses, etc.
List<AdminSectionItem> buildAdminSections() {
  return [
    AdminSectionItem(
      label: 'Dashboard',
      icon: Icons.dashboard_rounded,
      group: 'Overview',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminDashboardScreen(
        embeddedInShell: embedded,
        onNavigateToSection: onNavigateToSection,
      ),
    ),
    AdminSectionItem(
      label: 'Businesses',
      icon: Icons.store_rounded,
      group: 'Listings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminBusinessesScreen(
        status: status,
        embeddedInShell: embedded,
      ),
    ),
    AdminSectionItem(
      label: 'Reviews',
      icon: Icons.star_rounded,
      group: 'Listings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminReviewsScreen(
        status: status,
        embeddedInShell: embedded,
      ),
    ),
    AdminSectionItem(
      label: 'Claims',
      icon: Icons.handshake_rounded,
      group: 'Listings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminClaimsScreen(
        status: status,
        embeddedInShell: embedded,
      ),
    ),
    AdminSectionItem(
      label: 'Pending approvals',
      icon: Icons.pending_actions_rounded,
      group: 'Listings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminPendingApprovalsScreen(
        status: status,
        embeddedInShell: embedded,
      ),
    ),
    AdminSectionItem(
      label: 'Form submissions',
      icon: Icons.inbox_rounded,
      group: 'Listings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminFormSubmissionsScreen(
        embeddedInShell: embedded,
      ),
    ),
    AdminSectionItem(
      label: 'Blog posts',
      icon: Icons.article_rounded,
      group: 'Content',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminBlogScreen(
        status: status,
        embeddedInShell: embedded,
      ),
    ),
    AdminSectionItem(
      label: 'Manage banners',
      icon: Icons.perm_media_rounded,
      group: 'Content',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminManageBannersScreen(
        status: status,
        embeddedInShell: embedded,
      ),
    ),
    AdminSectionItem(
      label: 'Categories',
      icon: Icons.category_rounded,
      group: 'Settings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminCategoriesScreen(embeddedInShell: embedded),
    ),
    AdminSectionItem(
      label: 'Parishes',
      icon: Icons.map_rounded,
      group: 'Settings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminParishesScreen(embeddedInShell: embedded),
    ),
    AdminSectionItem(
      label: 'Subscriptions',
      icon: Icons.card_membership_rounded,
      group: 'Settings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminSubscriptionsScreen(embeddedInShell: embedded),
    ),
    AdminSectionItem(
      label: 'Ad packages',
      icon: Icons.campaign_rounded,
      group: 'Settings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminAdPackagesScreen(embeddedInShell: embedded),
    ),
    AdminSectionItem(
      label: 'Business ads',
      icon: Icons.ads_click_rounded,
      group: 'Settings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminBusinessAdsScreen(embeddedInShell: embedded, status: status),
    ),
    AdminSectionItem(
      label: 'Payment history',
      icon: Icons.receipt_long_rounded,
      group: 'Settings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminPaymentHistoryScreen(embeddedInShell: embedded),
    ),
    AdminSectionItem(
      label: 'Users',
      icon: Icons.people_rounded,
      group: 'Settings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminUserRolesScreen(embeddedInShell: embedded),
    ),
    AdminSectionItem(
      label: 'Send notification',
      icon: Icons.notifications_active_rounded,
      group: 'Settings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminSendNotificationScreen(embeddedInShell: embedded),
    ),
    AdminSectionItem(
      label: 'Email templates',
      icon: Icons.email_rounded,
      group: 'Settings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminEmailTemplatesScreen(embeddedInShell: embedded),
    ),
    AdminSectionItem(
      label: 'Audit log',
      icon: Icons.history_rounded,
      group: 'Settings',
      builder: (context, {required embedded, status, onNavigateToSection}) =>
          AdminAuditLogScreen(embeddedInShell: embedded),
    ),
  ];
}
