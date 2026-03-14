import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/core/theme/theme.dart';

class LatestPostCardWidget extends StatelessWidget {
  const LatestPostCardWidget({
    super.key,
    required this.post,
    required this.parishLabel,
    required this.onTap,
    this.cardWidth,
  });

  final BlogPost post;
  final String parishLabel;
  final VoidCallback onTap;

  /// When set (e.g. horizontal scroll), use this width; otherwise full width for grid.
  final double? cardWidth;

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${d.month}/${d.day}/${d.year}';
  }

  static String _shortExcerpt(String? excerpt, {int maxLen = 72}) {
    if (excerpt == null || excerpt.trim().isEmpty) return '';
    final t = excerpt.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen).trim()}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = 18.0;
    final coverUrl = post.coverImageUrl;
    final dateStr = _formatDate(post.publishedAt ?? post.createdAt);
    final excerpt = _shortExcerpt(post.excerpt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 128,
                      width: double.infinity,
                      child: coverUrl != null && coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: coverUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              memCacheWidth: 400,
                              memCacheHeight: 200,
                              placeholder: (_, progress) => _placeholderCover(),
                              errorWidget: (_, error, stackTrace) => _placeholderCover(),
                            )
                          : _placeholderCover(),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [AppTheme.specGold, AppTheme.specGold.withValues(alpha: 0.6)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (parishLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            parishLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.specNavy.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Text(
                        post.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.specNavy,
                          height: 1.2,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (excerpt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            excerpt,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.specNavy.withValues(alpha: 0.7),
                              height: 1.3,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: AppTheme.specNavy.withValues(alpha: 0.55)),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.specNavy.withValues(alpha: 0.65),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Read',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.specGold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.specGold),
                          ],
                        ),
                      ],
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

  Widget _placeholderCover() {
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
      child: Center(
        child: Icon(Icons.article_rounded, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.22)),
      ),
    );
  }
}
