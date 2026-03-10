import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cajun_local/core/data/models/blog_post.dart';
import 'package:cajun_local/core/data/models/parish.dart';
import 'package:cajun_local/core/data/repositories/blog_posts_repository.dart';
import 'package:cajun_local/core/data/repositories/parish_repository.dart';
import 'package:cajun_local/core/preferences/user_parish_preferences.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';

/// Single news post view — hero banner, title, date, body; "Other recent blogs" at bottom.
class NewsPostDetailScreen extends StatelessWidget {
  const NewsPostDetailScreen({super.key, required this.postId});

  final String postId;

  /// Hero banner height: ~40% of viewport, min 220, max 380.
  /// Uses [viewportHeight] to avoid reading RenderBox.size before layout.
  static double _heroBannerHeight(double viewportHeight) {
    final value = viewportHeight * 0.40;
    return value.clamp(220.0, 380.0);
  }

  static Widget _heroBannerPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.specNavy.withValues(alpha: 0.18), AppTheme.specGold.withValues(alpha: 0.2)],
        ),
      ),
      child: Center(child: Icon(Icons.article_rounded, size: 72, color: AppTheme.specNavy.withValues(alpha: 0.25))),
    );
  }

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          return FutureBuilder<(BlogPost?, List<BlogPost>, List<Parish>)>(
            future:
                Future.wait([
                  BlogPostsRepository().getById(postId),
                  UserParishPreferences.getPreferredParishIds().then(
                    (ids) =>
                        BlogPostsRepository().listApproved(limit: 20, forParishIds: ids.isEmpty ? null : ids.toSet()),
                  ),
                  ParishRepository().listParishes(),
                ]).then(
                  (results) => (
                    results[0] as BlogPost?,
                    (results[1] as List<BlogPost>).where((p) => p.id != postId).take(4).toList(),
                    results[2] as List<Parish>,
                  ),
                ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.specNavy));
              }
              var post = snapshot.data?.$1;
              final otherPosts = snapshot.data?.$2 ?? [];
              final parishes = snapshot.data?.$3 ?? [];
              final idToName = {for (final p in parishes) p.id: p.name};
              if (post != null && post.status != 'approved' && post.status != 'published') post = null;
              if (post == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('Post not found', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.specNavy)),
                      const SizedBox(height: 24),
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
                    ],
                  ),
                );
              }

              final hasCover = post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty;
              final dateStr = formatDate(post.publishedAt ?? post.createdAt);
              final heroHeight = _heroBannerHeight(viewportHeight);

              return CustomScrollView(
                slivers: [
                  // Hero banner — always present (image or placeholder)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: heroHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          hasCover
                              ? CachedNetworkImage(
                                  imageUrl: post.coverImageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => _heroBannerPlaceholder(),
                                  errorWidget: (_, _, _) => _heroBannerPlaceholder(),
                                )
                              : _heroBannerPlaceholder(),
                          // Gradient overlay for back button contrast
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.5),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.25),
                                ],
                                stops: const [0.0, 0.12, 0.7, 1.0],
                              ),
                            ),
                          ),
                          // Back button
                          Positioned(
                            top: MediaQuery.paddingOf(context).top + 8,
                            left: 8,
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(24),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                              _ParishChip(post: post, idToName: idToName),
                              const SizedBox(height: 12),
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
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxHeight: viewportHeight * 3),
                                  child: Html(
                                    data: post.content!,
                                    style: {
                                      'body': Style(
                                        margin: Margins.zero,
                                        padding: HtmlPaddings.zero,
                                        fontSize: FontSize(theme.textTheme.bodyLarge?.fontSize ?? 17.0),
                                        lineHeight: const LineHeight(1.7),
                                        color: AppTheme.specNavy.withValues(alpha: 0.9),
                                      ),
                                      'p': Style(margin: Margins.only(bottom: 18)),
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
                                      'ul': Style(
                                        margin: Margins.only(top: 12, bottom: 16, left: 8),
                                        padding: HtmlPaddings.only(left: 20),
                                      ),
                                      'ol': Style(
                                        margin: Margins.only(top: 12, bottom: 16, left: 8),
                                        padding: HtmlPaddings.only(left: 20),
                                      ),
                                      'li': Style(
                                        margin: Margins.only(bottom: 8),
                                        padding: HtmlPaddings.zero,
                                        lineHeight: const LineHeight(1.6),
                                      ),
                                      'blockquote': Style(
                                        margin: Margins.only(top: 20, bottom: 20, left: 16),
                                        padding: HtmlPaddings.only(left: 20, top: 12, bottom: 12),
                                        border: Border(left: BorderSide(color: AppTheme.specGold, width: 4)),
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.specNavy.withValues(alpha: 0.85),
                                      ),
                                      'a': Style(color: AppTheme.specGold, textDecoration: TextDecoration.underline),
                                    },
                                  ),
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
                                Container(height: 1, color: AppTheme.specNavy.withValues(alpha: 0.1)),
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
                              children: otherPosts
                                  .map(
                                    (other) => _OtherBlogTile(
                                      post: other,
                                      onTap: () {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute<void>(
                                            builder: (_) => NewsPostDetailScreen(postId: other.id),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                  .toList(),
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
          );
        },
      ),
    );
  }
}

class _ParishChip extends StatelessWidget {
  const _ParishChip({required this.post, required this.idToName});

  final BlogPost post;
  final Map<String, String> idToName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = post.isAllParishes
        ? 'All parishes'
        : (post.parishIds ?? []).map((id) => idToName[id] ?? id).join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.specNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppTheme.specNavy.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OtherBlogTile extends StatelessWidget {
  const _OtherBlogTile({required this.post, required this.onTap});

  final BlogPost post;
  final VoidCallback onTap;

  static const double _thumbWidth = 100;
  static const double _thumbHeight = 72;

  static Widget _thumbPlaceholder() {
    return Container(
      width: _thumbWidth,
      height: _thumbHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.specNavy.withValues(alpha: 0.1), AppTheme.specGold.withValues(alpha: 0.12)],
        ),
      ),
      child: Center(child: Icon(Icons.article_rounded, size: 28, color: AppTheme.specNavy.withValues(alpha: 0.25))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty;
    final dateStr = NewsPostDetailScreen.formatDate(post.publishedAt ?? post.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AppTheme.specNavy.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _thumbWidth,
                  height: _thumbHeight,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: post.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => _thumbPlaceholder(),
                          errorWidget: (_, _, _) => _thumbPlaceholder(),
                        )
                      : _thumbPlaceholder(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
