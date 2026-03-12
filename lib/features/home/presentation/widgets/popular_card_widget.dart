import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/core/theme/theme.dart';

class PopularCardWidget extends StatelessWidget {
  const PopularCardWidget({super.key, required this.spot, required this.onTap, this.cardWidth});

  final MockSpot spot;
  final VoidCallback onTap;
  final double? cardWidth;

  static const double _logoSize = 82;
  static const double _radius = 18.0;

  static bool _showSubtitle(String name, String subtitle) {
    if (subtitle.trim().isEmpty) return false;
    return subtitle.trim().toLowerCase() != name.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoUrl = spot.logoUrl;
    final rating = spot.rating;
    final showRating = rating != null;
    final subcatOrCategory = spot.subcategoryName ?? spot.categoryName;
    final showSubtitle = _showSubtitle(spot.name, spot.subtitle);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo on the side (left)
                SizedBox(
                  width: _logoSize,
                  height: _logoSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.specOffWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.06)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: logoUrl != null && logoUrl.trim().isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.contain,
                              memCacheWidth: 200,
                              memCacheHeight: 200,
                              placeholder: (_, _) => _placeholderContent(),
                              errorWidget: (_, _, _) => _placeholderContent(),
                            )
                          : _placeholderContent(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        spot.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.specNavy,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showSubtitle) ...[
                        const SizedBox(height: 2),
                        Text(
                          spot.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.7)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (showRating || subcatOrCategory != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (rating != null) ...[
                              Icon(Icons.star_rounded, size: 16, color: AppTheme.specGold),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.specNavy,
                                ),
                              ),
                            ],
                            if (showRating && subcatOrCategory != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppTheme.specNavy.withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            if (subcatOrCategory != null)
                              Expanded(
                                child: Text(
                                  subcatOrCategory,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppTheme.specNavy.withValues(alpha: 0.65),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.specGold),
                          const SizedBox(width: 6),
                          Text(
                            'View listing',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.specGold,
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
      ),
    );
  }

  Widget _placeholderContent() {
    return Center(child: Icon(Icons.store_rounded, size: 44, color: AppTheme.specNavy.withValues(alpha: 0.25)));
  }
}
