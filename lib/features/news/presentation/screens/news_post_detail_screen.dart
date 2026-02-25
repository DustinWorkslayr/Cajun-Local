import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:my_app/core/data/models/blog_post.dart';
import 'package:my_app/core/data/repositories/blog_posts_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';

/// Single news post view — full article with cover, title, date, body; "Other recent blogs" at bottom.
class NewsPostDetailScreen extends StatelessWidget {
  const NewsPostDetailScreen({super.key, required this.postId});

  final String postId;

  static String formatDate(DateTime? d) {
    if (d == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    const maxContentWidth = 680.0;

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      body: FutureBuilder<(BlogPost?, List<BlogPost>)>(
        future: Future.wait([
          BlogPostsRepository().getById(postId),
          BlogPostsRepository().listApproved(limit: 20),
        ]).then((results) => (
          results[0] as BlogPost?,
          (results[1] as List<BlogPost>).where((p) => p.id != postId).take(4).toList(),
        )),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.specNavy));
          }
          var post = snapshot.data?.$1;
          final otherPosts = snapshot.data?.$2 ?? [];
          if (post != null && post.status != 'approved') post = null;
          if (post == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('Post not found', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.specNavy)),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          }

          final hasCover = post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty;
          final dateStr = formatDate(post.publishedAt ?? post.createdAt);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: hasCover ? 280 : 0,
                pinned: true,
                backgroundColor: AppTheme.specOffWhite,
                foregroundColor: AppTheme.specNavy,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: hasCover
                    ? FlexibleSpaceBar(
                        background: CachedNetworkImage(
                          imageUrl: post.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: AppTheme.specNavy.withValues(alpha: 0.06)),
                          errorWidget: (_, _, _) => Container(color: AppTheme.specNavy.withValues(alpha: 0.06)),
                        ),
                      )
                    : null,
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(padding.left, 32, padding.right, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (dateStr.isNotEmpty)
                            Text(
                              dateStr,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppTheme.specGold,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          if (dateStr.isNotEmpty) const SizedBox(height: 12),
                          Text(
                            post.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.specNavy,
                              height: 1.22,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (post.content != null && post.content!.isNotEmpty)
                            Html(
                              data: post.content!,
                              style: {
                                'body': Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  fontSize: FontSize(theme.textTheme.bodyLarge?.fontSize ?? 17),
                                  lineHeight: const LineHeight(1.7),
                                  color: AppTheme.specNavy.withValues(alpha: 0.9),
                                ),
                                'p': Style(
                                  margin: Margins.only(bottom: 18),
                                ),
                                'h2': Style(
                                  margin: Margins.only(top: 28, bottom: 12),
                                  fontSize: FontSize(theme.textTheme.titleLarge?.fontSize ?? 22),
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.specNavy,
                                ),
                                'h3': Style(
                                  margin: Margins.only(top: 22, bottom: 10),
                                  fontSize: FontSize(theme.textTheme.titleMedium?.fontSize ?? 18),
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.specNavy,
                                ),
                                'a': Style(
                                  color: AppTheme.specGold,
                                  textDecoration: TextDecoration.underline,
                                ),
                              },
                            )
                          else
                            Text(
                              'No content.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppTheme.specNavy.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (otherPosts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(padding.left, 24, padding.right, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 1,
                              color: AppTheme.specNavy.withValues(alpha: 0.1),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Other recent blogs',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.specNavy,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 32),
                        child: Column(
                          children: otherPosts.map((other) => _OtherBlogTile(
                            post: other,
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => NewsPostDetailScreen(postId: other.id),
                                ),
                              );
                            },
                          )).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

class _OtherBlogTile extends StatelessWidget {
  const _OtherBlogTile({required this.post, required this.onTap});

  final BlogPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty;
    final dateStr = NewsPostDetailScreen.formatDate(post.publishedAt ?? post.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.specNavy.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: post.coverImageUrl!,
                      width: 88,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 88,
                        height: 72,
                        color: AppTheme.specNavy.withValues(alpha: 0.06),
                        child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                      ),
                      errorWidget: (_, _, _) => Container(
                        width: 88,
                        height: 72,
                        color: AppTheme.specNavy.withValues(alpha: 0.06),
                        child: Icon(Icons.article_rounded, color: AppTheme.specNavy.withValues(alpha: 0.25)),
                      ),
                    ),
                  ),
                if (hasImage) const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (dateStr.isNotEmpty) const SizedBox(height: 4),
                      Text(
                        post.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.specNavy,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Read',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.specGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.specGold),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
