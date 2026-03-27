import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/core/theme/theme.dart';

/// Local story card — matches Stitch v2 exactly.
/// Two layouts:
///  • featured=true : full image (aspect 4:5) with gradient overlay from bottom,
///    gold "Featured Story" badge, white bold title, "Read Story" button.
///  • featured=false: image (h-48) on top, content below with parish label + title + date.
class LatestPostCardWidget extends StatelessWidget {
  const LatestPostCardWidget({
    super.key,
    required this.post,
    required this.parishLabel,
    required this.onTap,
    this.cardWidth,
    this.cardHeight,
    this.featured = false,
  });

  final BlogPost post;
  final String parishLabel;
  final VoidCallback onTap;
  final double? cardWidth;
  final double? cardHeight;
  final bool featured;

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.month}/${d.day}/${d.year}';
  }

  static String _shortExcerpt(String? excerpt, {int maxLen = 80}) {
    if (excerpt == null || excerpt.trim().isEmpty) return '';
    final t = excerpt.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen).trim()}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverUrl = post.coverImageUrl;
    final dateStr = _formatDate(post.publishedAt ?? post.createdAt);
    final excerpt = _shortExcerpt(post.excerpt);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: featured ? _buildFeatured(context, theme, coverUrl, excerpt) : _buildSecondary(context, theme, coverUrl, dateStr, excerpt),
      ),
    );
  }

  // ── Featured card: image fills entire card with gradient overlay ──
  Widget _buildFeatured(BuildContext context, ThemeData theme, String? coverUrl, String excerpt) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        children: [
          // Background image — aspect 4:5
          AspectRatio(
            aspectRatio: 4 / 5,
            child: coverUrl != null && coverUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _imgPlaceholder(),
                    errorWidget: (_, _, _) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
          ),

          // Gradient overlay (from-primary/90 via-primary/20 to-transparent)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.specNavy.withValues(alpha: 0.2),
                    AppTheme.specNavy.withValues(alpha: 0.9),
                  ],
                  stops: const [0.3, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Content at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Featured Story" badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.specGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'FEATURED STORY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    post.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (excerpt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      excerpt,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.specOnPrimaryContainer,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),

                  // "Read Story" button
                  Material(
                    color: AppTheme.specWhite,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Read Story',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppTheme.specNavy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.menu_book_rounded, size: 18, color: AppTheme.specNavy),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Secondary card: image on top, content below ──
  Widget _buildSecondary(BuildContext context, ThemeData theme, String? coverUrl, String dateStr, String excerpt) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1D).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image (h-48 = 192px)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: SizedBox(
              height: 192,
              width: double.infinity,
              child: coverUrl != null && coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _imgPlaceholder(),
                      errorWidget: (_, _, _) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parishLabel.isNotEmpty)
                    Text(
                      parishLabel.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.specGold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                  const SizedBox(height: 6),

                  Text(
                    post.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.specNavy,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (excerpt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      excerpt,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specOutline),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const Spacer(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specOutline,
                            fontSize: 10,
                          ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onTap,
                        child: Row(
                          children: [
                            Text(
                              'Read',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.specGold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.specGold),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      color: AppTheme.specSurfaceContainer,
      child: Center(
        child: Icon(Icons.article_rounded, size: 48, color: AppTheme.specOutline),
      ),
    );
  }
}
