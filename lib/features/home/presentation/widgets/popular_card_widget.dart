import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cajun_local/core/revenuecat/present_subscription_paywall.dart';
import 'package:cajun_local/core/subscription/resolved_permissions.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/businesses/data/models/featured_business.dart';
import 'package:cajun_local/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:cajun_local/core/data/providers/app_data_providers.dart';

/// Popular spot card — matches Stitch v2 exactly:
/// Image at top with heart + "OPEN NOW" overlay badges.
class PopularCardWidget extends ConsumerWidget {
  const PopularCardWidget({super.key, required this.spot, required this.onTap, this.cardWidth});

  final FeaturedBusiness spot;
  final VoidCallback onTap;
  final double? cardWidth;

  static const double _radius = 24.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logoUrl = spot.logoUrl;
    final rating = spot.rating;
    final subcatOrCategory = spot.subcategoryName ?? spot.categoryName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth ?? 288,
        decoration: BoxDecoration(
          color: AppTheme.specWhite,
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF191C1D).withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top image section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(_radius)),
              child: SizedBox(
                height: 176,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image or placeholder
                    logoUrl != null && logoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: logoUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => _placeholderImg(),
                            errorWidget: (_, _, _) => _placeholderImg(),
                          )
                        : _placeholderImg(),

                    // Heart button (top-right)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: ref.watch(userFavoriteIdsProvider).when(
                            data: (ids) {
                              final isFav = ids.contains(spot.id);
                              return GestureDetector(
                                onTap: () async {
                                  if (isFav) {
                                    await ref.read(userFavoriteIdsProvider.notifier).remove(spot.id);
                                  } else {
                                    final perms = ref.read(userTierServiceProvider).value ?? ResolvedPermissions.free;
                                    if (perms.wouldExceedFavoritesLimit(ids.length)) {
                                      if (!context.mounted) return;
                                      await presentSubscriptionPaywall(context, ref);
                                      return;
                                    }
                                    await ref.read(userFavoriteIdsProvider.notifier).add(spot.id);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    size: 20,
                                    color: AppTheme.specGold,
                                  ),
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                    ),

                    // "OPEN NOW" / "CLOSED" dynamic badge (bottom-left)
                    if (spot.isOpenNow != null)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: spot.isOpenNow! 
                                    ? AppTheme.specNavy.withValues(alpha: 0.65)
                                    : Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: spot.isOpenNow! ? AppTheme.specGold : Colors.white70,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        if (spot.isOpenNow!)
                                          BoxShadow(color: AppTheme.specGold.withValues(alpha: 0.6), blurRadius: 4, spreadRadius: 1),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    spot.isOpenNow! ? 'OPEN NOW' : 'CLOSED',
                                    style: TextStyle(
                                      color: spot.isOpenNow! ? Colors.white : Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tags
                  if (subcatOrCategory != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.specSurfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        subcatOrCategory.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.specOutline,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Name
                  Text(
                    spot.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.specNavy,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Tagline
                  if (spot.tagline?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      spot.tagline!,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specOutline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Star rating
                  if (rating != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: AppTheme.specGold),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.specNavy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImg() {
    return Container(
      color: AppTheme.specSurfaceContainerHigh,
      child: const Center(child: Icon(Icons.store_rounded, size: 40, color: AppTheme.specOutline)),
    );
  }
}
