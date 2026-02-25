import 'package:flutter/material.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/services/process_email_queue_service.dart';
import 'package:my_app/core/data/repositories/business_claims_repository.dart';
import 'package:my_app/core/data/repositories/business_images_repository.dart';
import 'package:my_app/core/data/repositories/blog_posts_repository.dart';
import 'package:my_app/core/data/repositories/category_banners_repository.dart';
import 'package:my_app/core/data/repositories/reviews_repository.dart';
import 'package:my_app/core/data/repositories/user_roles_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/screens/admin_sections.dart';
import 'package:my_app/features/admin/presentation/screens/admin_businesses_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_reviews_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_claims_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_pending_approvals_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_blog_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_manage_banners_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_user_roles_screen.dart';

/// Analytics data: totals and pending counts for dashboard.
class _DashboardStats {
  const _DashboardStats({
    required this.businessesTotal,
    required this.businessesPending,
    required this.reviewsTotal,
    required this.reviewsPending,
    required this.claimsTotal,
    required this.claimsPending,
    required this.imagesTotal,
    required this.imagesPending,
    required this.blogTotal,
    required this.blogPending,
    required this.bannersTotal,
    required this.bannersPending,
    required this.usersTotal,
  });

  final int businessesTotal;
  final int businessesPending;
  final int reviewsTotal;
  final int reviewsPending;
  final int claimsTotal;
  final int claimsPending;
  final int imagesTotal;
  final int imagesPending;
  final int blogTotal;
  final int blogPending;
  final int bannersTotal;
  final int bannersPending;
  final int usersTotal;
}

/// Admin dashboard: analytics overview and quick links. Styled like homepage (spec colors, cards).
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    this.embeddedInShell = false,
    this.onNavigateToSection,
  });

  final bool embeddedInShell;
  final OnNavigateToSection? onNavigateToSection;

  static const double _cardRadius = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final isTablet = AppLayout.isTablet(context);

    final businessRepo = BusinessRepository();
    final reviewsRepo = ReviewsRepository();
    final claimsRepo = BusinessClaimsRepository();
    final imagesRepo = BusinessImagesRepository();
    final blogRepo = BlogPostsRepository();
    final bannersRepo = CategoryBannersRepository();
    final userRolesRepo = UserRolesRepository();

    final future = Future.wait([
      businessRepo.listForAdmin(),
      businessRepo.listForAdmin(status: 'pending'),
      reviewsRepo.listForAdmin(),
      reviewsRepo.listForAdmin(status: 'pending'),
      claimsRepo.listForAdmin(),
      claimsRepo.listForAdmin(status: 'pending'),
      imagesRepo.listForAdmin(),
      imagesRepo.listForAdmin(status: 'pending'),
      blogRepo.listForAdmin(),
      blogRepo.listForAdmin(status: 'pending'),
      bannersRepo.listForAdmin(),
      bannersRepo.listForAdmin(status: 'pending'),
      userRolesRepo.listForAdmin(),
    ]).then((r) => _DashboardStats(
          businessesTotal: r[0].length,
          businessesPending: r[1].length,
          reviewsTotal: r[2].length,
          reviewsPending: r[3].length,
          claimsTotal: r[4].length,
          claimsPending: r[5].length,
          imagesTotal: r[6].length,
          imagesPending: r[7].length,
          blogTotal: r[8].length,
          blogPending: r[9].length,
          bannersTotal: r[10].length,
          bannersPending: r[11].length,
          usersTotal: r[12].length,
        ));

    return Container(
      color: AppTheme.specOffWhite,
      child: FutureBuilder<_DashboardStats>(
        future: future,
        builder: (context, snapshot) {
          final stats = snapshot.data;
          final loading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

          return CustomScrollView(
            slivers: [
              // ——— Header: modern, spacious ———
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding.left, 28, padding.right, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.specNavy,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Content overview and items needing your attention.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.specNavy.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 4,
                          width: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.specGold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (loading)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                  ),
                )
              else ...[
                // ——— Stat cards: grid with generous spacing ———
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossCount = isTablet ? 3 : 2;
                        const spacing = 16.0;
                        final childWidth = (constraints.maxWidth - (crossCount - 1) * spacing) / crossCount;
                        final statsList = [
                          _StatItem('Businesses', stats?.businessesTotal ?? 0, stats?.businessesPending ?? 0, Icons.store_rounded),
                          _StatItem('Reviews', stats?.reviewsTotal ?? 0, stats?.reviewsPending ?? 0, Icons.star_rounded),
                          _StatItem('Claims', stats?.claimsTotal ?? 0, stats?.claimsPending ?? 0, Icons.handshake_rounded),
                          _StatItem('Pending approvals', stats?.imagesTotal ?? 0, stats?.imagesPending ?? 0, Icons.pending_actions_rounded),
                          _StatItem('Blog posts', stats?.blogTotal ?? 0, stats?.blogPending ?? 0, Icons.article_rounded),
                          _StatItem('Category banners', stats?.bannersTotal ?? 0, stats?.bannersPending ?? 0, Icons.perm_media_rounded),
                        ];
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: statsList.map((s) => SizedBox(
                            width: childWidth,
                            child: _StatCard(
                              label: s.label,
                              total: s.total,
                              pending: s.pending,
                              icon: s.icon,
                              cardRadius: _cardRadius,
                            ),
                          )).toList(),
                        );
                      },
                    ),
                  ),
                ),

                // ——— Needs attention ———
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding.left, 32, padding.right, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Needs attention',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.specNavy,
                          ),
                        ),
                        Text(
                          'Tap to review',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.specNavy.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(left: padding.left, right: padding.right, bottom: 16),
                    child: Row(
                      children: [
                        _AttentionCard(
                          title: 'Pending businesses',
                          count: stats?.businessesPending ?? 0,
                          icon: Icons.store_rounded,
                          cardRadius: _cardRadius,
                          onTap: () => _navigate(context, 1, status: 'pending'),
                        ),
                        _AttentionCard(
                          title: 'Pending reviews',
                          count: stats?.reviewsPending ?? 0,
                          icon: Icons.star_rounded,
                          cardRadius: _cardRadius,
                          onTap: () => _navigate(context, 2, status: 'pending'),
                        ),
                        _AttentionCard(
                          title: 'Pending claims',
                          count: stats?.claimsPending ?? 0,
                          icon: Icons.handshake_rounded,
                          cardRadius: _cardRadius,
                          onTap: () => _navigate(context, 3, status: 'pending'),
                        ),
                        _AttentionCard(
                          title: 'Pending approvals',
                          count: stats?.imagesPending ?? 0,
                          icon: Icons.pending_actions_rounded,
                          cardRadius: _cardRadius,
                          onTap: () => _navigate(context, 4, status: 'pending'),
                        ),
                        _AttentionCard(
                          title: 'Pending blog',
                          count: stats?.blogPending ?? 0,
                          icon: Icons.article_rounded,
                          cardRadius: _cardRadius,
                          onTap: () => _navigate(context, 5, status: 'pending'),
                        ),
                        _AttentionCard(
                          title: 'Pending banners',
                          count: stats?.bannersPending ?? 0,
                          icon: Icons.perm_media_rounded,
                          cardRadius: _cardRadius,
                          onTap: () => _navigate(context, 6, status: 'pending'),
                        ),
                      ].map((w) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: w,
                      )).toList(),
                    ),
                  ),
                ),

                // ——— Quick actions: grid of cards (no long list) ———
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding.left, 32, padding.right, 12),
                    child: Text(
                      'Quick actions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 32),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 12.0;
                        final crossCount = isTablet ? 4 : 2;
                        final itemWidth = (constraints.maxWidth - (crossCount - 1) * spacing) / crossCount;
                        final actions = [
                          _ActionCard(icon: Icons.store_outlined, label: 'Businesses', onTap: () => _navigate(context, 1)),
                          _ActionCard(icon: Icons.star_outline_rounded, label: 'Reviews', onTap: () => _navigate(context, 2)),
                          _ActionCard(icon: Icons.handshake_outlined, label: 'Claims', onTap: () => _navigate(context, 3)),
                          _ActionCard(icon: Icons.image_outlined, label: 'Images', onTap: () => _navigate(context, 4)),
                          _ActionCard(icon: Icons.article_outlined, label: 'Blog posts', onTap: () => _navigate(context, 5)),
                          _ActionCard(icon: Icons.perm_media_outlined, label: 'Banners', onTap: () => _navigate(context, 6)),
                          _ActionCard(icon: Icons.people_outline_rounded, label: 'Users', onTap: () => _navigate(context, 9)),
                          _ActionCard(icon: Icons.email_outlined, label: 'Process email queue', onTap: () => _processEmailQueue(context)),
                        ];
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: actions.map((a) => SizedBox(
                            width: itemWidth,
                            child: a,
                          )).toList(),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          );
        },
      ),
    );
  }

  static Future<void> _processEmailQueue(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final result = await ProcessEmailQueueService().processQueue();
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            result.processed == 0
                ? 'No pending emails.'
                : 'Processed: ${result.processed} — sent: ${result.sent}, failed: ${result.failed}',
          ),
          backgroundColor: result.failed > 0 ? Colors.orange : null,
        ),
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigate(BuildContext context, int index, {String? status}) {
    if (onNavigateToSection != null) {
      onNavigateToSection!(index, status: status);
    } else {
      switch (index) {
        case 1:
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => AdminBusinessesScreen(status: status)),
          );
          break;
        case 2:
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => AdminReviewsScreen(status: status)),
          );
          break;
        case 3:
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => AdminClaimsScreen(status: status)),
          );
          break;
        case 4:
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => AdminPendingApprovalsScreen(status: status)),
          );
          break;
        case 5:
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => AdminBlogScreen(status: status)),
          );
          break;
        case 6:
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => AdminManageBannersScreen(status: status)),
          );
          break;
        case 9:
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AdminUserRolesScreen()),
          );
          break;
        default:
          break;
      }
    }
  }
}

class _StatItem {
  const _StatItem(this.label, this.total, this.pending, this.icon);
  final String label;
  final int total;
  final int pending;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.total,
    required this.pending,
    required this.icon,
    required this.cardRadius,
  });

  final String label;
  final int total;
  final int pending;
  final IconData icon;
  final double cardRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AppTheme.specNavy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.specNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$total',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.specNavy,
            ),
          ),
          if (pending > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$pending pending',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.specRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 28,
            decoration: BoxDecoration(
              color: AppTheme.specGold.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.cardRadius,
    required this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
  final double cardRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: AppTheme.specNavy),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.specNavy,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: count > 0 ? AppTheme.specRed : AppTheme.specNavy,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Review',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.specRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.specRed),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact action card for dashboard quick actions (replaces long list).
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: AppTheme.specNavy),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.specNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.specNavy.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
