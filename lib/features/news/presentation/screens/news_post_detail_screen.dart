import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/news/presentation/providers/news_providers.dart';
import 'package:cajun_local/shared/widgets/animated_entrance.dart';

/// Single news post detail view — redesigned with a premium editorial aesthetic.
class NewsPostDetailScreen extends ConsumerWidget {
  const NewsPostDetailScreen({super.key, required this.postId});

  final String postId;

  static String formatDate(DateTime? d) {
    if (d == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    const maxContentWidth = 720.0;

    final postAsync = ref.watch(newsPostProvider(postId));
    final otherPostsAsync = ref.watch(newsRecentPostsProvider(excludePostId: postId));
    final parishesAsync = ref.watch(newsParishesProvider);

    return Scaffold(
      backgroundColor: AppTheme.specWhite,
      body: postAsync.when(
        data: (post) {
          if (post == null) return _buildNotFound(context, theme);
          return parishesAsync.when(
            data: (parishes) {
              final idToName = {for (final p in parishes) p.id: p.name};
              return _buildContent(
                context,
                post,
                otherPostsAsync,
                idToName,
                theme,
                padding,
                maxContentWidth,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
            error: (_, _) => _buildContent(context, post, otherPostsAsync, {}, theme, padding, maxContentWidth),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
        error: (_, _) => _buildNotFound(context, theme),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BlogPost post,
    AsyncValue<List<BlogPost>> otherPostsAsync,
    Map<String, String> idToName,
    ThemeData theme,
    EdgeInsets padding,
    double maxContentWidth,
  ) {
    final dateStr = formatDate(post.publishedAt ?? post.createdAt);
    final coverUrl = post.coverImageUrl;

    return CustomScrollView(
      slivers: [
        // --- Immersive Hero Header ---
        SliverAppBar(
          expandedHeight: 400,
          pinned: true,
          stretch: true,
          backgroundColor: AppTheme.specNavy,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.3),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (coverUrl != null && coverUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppTheme.specNavy.withOpacity(0.05)),
                    errorWidget: (_, _, _) => Container(color: AppTheme.specNavy.withOpacity(0.05)),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- Article Body ---
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding.left, 40, padding.right, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedEntrance(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (dateStr.isNotEmpty)
                                Text(
                                  dateStr.toUpperCase(),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: AppTheme.specGold,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              const SizedBox(width: 16),
                              _ParishChip(post: post, idToName: idToName),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            post.title,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontFamily: 'Libre Baskerville',
                              fontWeight: FontWeight.w700,
                              color: AppTheme.specNavy,
                              height: 1.25,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 200),
                      child: Html(
                        data: post.content ?? '',
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            fontSize: FontSize(18),
                            lineHeight: const LineHeight(1.8),
                            color: AppTheme.specNavy.withOpacity(0.9),
                            fontFamily: 'Be Vietnam Pro',
                          ),
                          "p": Style(margin: Margins.only(bottom: 24)),
                          "h2": Style(
                            margin: Margins.only(top: 32, bottom: 12),
                            fontSize: FontSize(22),
                            fontWeight: FontWeight.w700,
                            color: AppTheme.specNavy,
                          ),
                          "blockquote": Style(
                            margin: Margins.only(top: 24, bottom: 24, left: 0),
                            padding: HtmlPaddings.only(left: 24, top: 4, bottom: 4),
                            border: const Border(left: BorderSide(color: AppTheme.specGold, width: 4)),
                            fontStyle: FontStyle.italic,
                            color: AppTheme.specNavy.withOpacity(0.7),
                          ),
                          "li": Style(margin: Margins.only(bottom: 12)),
                          "a": Style(
                            color: AppTheme.specGold,
                            textDecoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // --- More Stories ---
        otherPostsAsync.when(
          data: (other) {
            if (other.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(padding.left, 40, padding.right, 100),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 48),
                        Text(
                          'CONTINUE READING',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specGold,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'More Local Narratives',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontFamily: 'Libre Baskerville',
                            fontWeight: FontWeight.w700,
                            color: AppTheme.specNavy,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ...other.map((o) => _OtherBlogTile(post: o)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(child: SizedBox()),
          error: (_, _) => const SliverToBoxAdapter(child: SizedBox()),
        ),
      ],
    );
  }

  Widget _buildNotFound(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 56, color: AppTheme.specNavy.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text('Story not found', style: theme.textTheme.titleLarge),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Back to News'),
          ),
        ],
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
    final label = post.isAllParishes ? 'All Parishes' : (post.parishIds ?? []).map((id) => idToName[id] ?? id).join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.specGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.specGold,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _OtherBlogTile extends StatelessWidget {
  const _OtherBlogTile({required this.post});
  final BlogPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = NewsPostDetailScreen.formatDate(post.publishedAt ?? post.createdAt);
    final coverUrl = post.coverImageUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.specWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.specNavy.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.pushReplacement('/news/${post.id}'),
          child: Row(
            children: [
              if (coverUrl != null && coverUrl.isNotEmpty)
                SizedBox(
                  width: 120,
                  height: 100,
                  child: CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(width: 120, height: 100, color: AppTheme.specNavy.withOpacity(0.05)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr.toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.specGold,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        post.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.specNavy,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
