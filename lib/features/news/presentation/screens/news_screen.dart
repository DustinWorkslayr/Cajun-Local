import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/news/presentation/providers/news_providers.dart';
import 'package:cajun_local/shared/widgets/app_refresh_indicator.dart';

/// Public News (blog) screen — approved posts only. News-focused, blog-style layout.
class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String _excerpt(String? body, {int maxLen = 160}) {
    if (body == null || body.isEmpty) return '';
    final trimmed = body.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.length <= maxLen) return trimmed;
    return '${trimmed.substring(0, maxLen).trim()}…';
  }

  static String _parishLabel(BlogPost post, Map<String, String> idToName) {
    if (post.isAllParishes) return 'All parishes';
    if (post.parishIds == null) return '';
    return post.parishIds!.map((id) => idToName[id] ?? id).join(', ');
  }

  static const double _bannerAspectRatio = 2.1; // Wide banner

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bannerHeight = (screenWidth - padding.left - padding.right) / _bannerAspectRatio;

    final postsAsync = ref.watch(newsPostsProvider);
    final parishesAsync = ref.watch(newsParishesProvider);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      body: AppRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(newsPostsProvider);
          ref.invalidate(newsParishesProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding.left, 24, padding.right, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'News & Stories',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.specNavy,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stories and updates from around Cajun country.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.72),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, padding.right),
              sliver: postsAsync.when(
                data: (posts) {
                  return parishesAsync.when(
                    data: (parishes) {
                      final idToName = {for (final p in parishes) p.id: p.name};
                      if (posts.isEmpty) {
                        return _buildEmptyState(theme);
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final post = posts[index];
                          final isFirst = index == 0;
                          return Padding(
                            padding: EdgeInsets.only(bottom: isFirst ? 28 : 24),
                            child: _NewsCard(
                              post: post,
                              parishLabel: _parishLabel(post, idToName),
                              featured: isFirst,
                              bannerHeight: bannerHeight,
                              onTap: () {
                                context.push('/news/${post.id}');
                              },
                            ),
                          );
                        }, childCount: posts.length),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                      ),
                    ),
                    error: (_, _) => _buildEmptyState(theme),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                  ),
                ),
                error: (err, stack) => _buildErrorState(theme, ref),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 110 + MediaQuery.paddingOf(context).bottom)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.article_outlined, size: 56, color: AppTheme.specNavy.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'No news yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Check back soon for updates.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Text('Failed to load news.', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                   ref.invalidate(newsPostsProvider);
                   ref.invalidate(newsParishesProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.post,
    required this.parishLabel,
    required this.featured,
    required this.bannerHeight,
    required this.onTap,
  });

  final BlogPost post;
  final String parishLabel;
  final bool featured;
  final double bannerHeight;
  final VoidCallback onTap;

  static Widget _bannerPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.specNavy.withValues(alpha: 0.12), AppTheme.specGold.withValues(alpha: 0.15)],
        ),
      ),
      child: Center(child: Icon(Icons.article_rounded, size: 56, color: AppTheme.specNavy.withValues(alpha: 0.2))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty;
    final dateStr = NewsScreen._formatDate(post.publishedAt ?? post.createdAt);
    final excerpt = post.excerpt ?? NewsScreen._excerpt(post.content);
    const radius = 20.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(color: AppTheme.specNavy.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: bannerHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      CachedNetworkImage(
                        imageUrl: post.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _bannerPlaceholder(),
                        errorWidget: (_, _, _) => _bannerPlaceholder(),
                      )
                    else
                      _bannerPlaceholder(),
                    if (featured)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  featured ? 24 : 20,
                  featured ? 22 : 18,
                  featured ? 24 : 20,
                  featured ? 24 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (dateStr.isNotEmpty)
                          Text(
                            dateStr,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.specGold,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        if (dateStr.isNotEmpty && parishLabel.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.specNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              parishLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.specNavy.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (dateStr.isEmpty && parishLabel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.specNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              parishLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.specNavy.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (dateStr.isNotEmpty || parishLabel.isNotEmpty) const SizedBox(height: 10),
                    Text(
                      post.title,
                      style: (featured ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                        height: 1.28,
                      ),
                      maxLines: featured ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        excerpt,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.78),
                          height: 1.5,
                        ),
                        maxLines: featured ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Read article',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.specGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.specGold),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
