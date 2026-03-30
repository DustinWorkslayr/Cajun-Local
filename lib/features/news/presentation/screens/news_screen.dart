import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/news/presentation/providers/news_providers.dart';
import 'package:cajun_local/shared/widgets/app_bar_widget.dart';
import 'package:cajun_local/shared/widgets/animated_entrance.dart';
import 'package:cajun_local/shared/widgets/app_refresh_indicator.dart';

/// Public News (blog) screen — redesigned with a premium editorial aesthetic.
class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String _excerpt(String? body, {int maxLen = 140}) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

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
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // --- Editorial Header ---
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding.left, 24, padding.right, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOCAL STORIES',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.specGold,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'News & Narratives',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.specNavy,
                        fontFamily: 'Libre Baskerville',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Journal entries from across Cajun country.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.specNavy.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // --- Main List ---
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 0),
              sliver: postsAsync.when(
                data: (posts) {
                  return parishesAsync.when(
                    data: (parishes) {
                      final idToName = {for (final p in parishes) p.id: p.name};
                      if (posts.isEmpty) return _buildEmptyState(theme);

                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final post = posts[index];
                          final isFeatured = index == 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: AnimatedEntrance(
                              delay: Duration(milliseconds: 100 * (index % 5)),
                              child: _NewsCard(
                                post: post,
                                parishLabel: _parishLabel(post, idToName),
                                featured: isFeatured,
                                onTap: () => context.push('/news/${post.id}'),
                              ),
                            ),
                          );
                        }, childCount: posts.length),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                      ),
                    ),
                    error: (_, _) => _buildEmptyState(theme),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                  ),
                ),
                error: (err, stack) => _buildErrorState(theme, ref),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppTheme.specNavy.withOpacity(0.05), shape: BoxShape.circle),
                child: Icon(Icons.auto_stories_outlined, size: 48, color: AppTheme.specNavy.withOpacity(0.3)),
              ),
              const SizedBox(height: 20),
              Text(
                'No stories yet',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.specNavy),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for local narratives.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withOpacity(0.6)),
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
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.specRed),
              const SizedBox(height: 16),
              Text('Failed to load news.', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.invalidate(newsPostsProvider);
                  ref.invalidate(newsParishesProvider);
                },
                style: FilledButton.styleFrom(backgroundColor: AppTheme.specNavy),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.post, required this.parishLabel, required this.featured, required this.onTap});

  final BlogPost post;
  final String parishLabel;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverUrl = post.coverImageUrl;
    final dateStr = NewsScreen._formatDate(post.publishedAt ?? post.createdAt);
    final excerpt = post.excerpt ?? NewsScreen._excerpt(post.content);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.specNavy.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (coverUrl != null && coverUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: featured ? 16 / 9 : 2.2,
                  child: CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppTheme.specNavy.withOpacity(0.05)),
                    errorWidget: (_, _, _) => Container(color: AppTheme.specNavy.withOpacity(0.05)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (dateStr.isNotEmpty)
                          Text(
                            dateStr.toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.specGold,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              fontSize: 11,
                            ),
                          ),
                        if (dateStr.isNotEmpty && parishLabel.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.circle, size: 4, color: AppTheme.specNavy.withOpacity(0.2)),
                          ),
                        if (parishLabel.isNotEmpty)
                          Expanded(
                            child: Text(
                              parishLabel.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.specNavy.withOpacity(0.4),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post.title,
                      style: (featured ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.specNavy,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        excerpt,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.specNavy.withOpacity(0.7),
                          height: 1.5,
                        ),
                        maxLines: featured ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.arrow_right_alt_rounded, color: AppTheme.specGold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Read Article',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.specGold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
