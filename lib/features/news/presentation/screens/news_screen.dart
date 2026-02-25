import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/blog_post.dart';
import 'package:my_app/core/data/repositories/blog_posts_repository.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/news/presentation/screens/news_post_detail_screen.dart';

/// Public News (blog) screen — approved posts only. News-focused, blog-style layout.
class NewsScreen extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding.left, 28, padding.right, 20),
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
                    const SizedBox(height: 8),
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
            padding: EdgeInsets.fromLTRB(padding.left, 20, padding.right, padding.right),
            sliver: FutureBuilder<List<BlogPost>>(
              future: SupabaseConfig.isConfigured
                  ? BlogPostsRepository().listApproved()
                  : Future.value(<BlogPost>[]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                    ),
                  );
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
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
                              style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Check back soon for updates.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      final isFirst = index == 0;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isFirst ? 24 : 20),
                        child: _NewsCard(
                          post: post,
                          featured: isFirst,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => NewsPostDetailScreen(postId: post.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: posts.length,
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.post,
    required this.featured,
    required this.onTap,
  });

  final BlogPost post;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty;
    final dateStr = NewsScreen._formatDate(post.publishedAt ?? post.createdAt);
    final excerpt = post.excerpt ?? NewsScreen._excerpt(post.content);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.specNavy.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                AspectRatio(
                  aspectRatio: featured ? 2.0 : 1.9,
                  child: CachedNetworkImage(
                    imageUrl: post.coverImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppTheme.specNavy.withValues(alpha: 0.06),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specGold)),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: AppTheme.specNavy.withValues(alpha: 0.06),
                      child: Icon(Icons.article_rounded, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.25)),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(featured ? 24 : 20, featured ? 20 : 16, featured ? 24 : 20, featured ? 24 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (dateStr.isNotEmpty) const SizedBox(height: 10),
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
