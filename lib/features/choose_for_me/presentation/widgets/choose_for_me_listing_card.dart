import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/listing/presentation/screens/listing_detail_screen.dart';

/// Compact listing card for slot machine (minimal style).
class ChooseForMeListingCard extends StatelessWidget {
  const ChooseForMeListingCard({super.key, required this.listing, this.cardHeight = 96, this.onTap});

  final MockListing listing;
  final double cardHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = listing.rating;
    final ratingStr = rating != null ? '(${rating.toStringAsFixed(1)})' : '—';
    final location = listing.address ?? '—';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            onTap ??
            () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => ListingDetailScreen(listingId: listing.id)));
            },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: cardHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              _Logo(logoUrl: listing.imagePlaceholder, size: 48, radius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      listing.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) {
                            final filled = rating != null && i < rating.floor().clamp(0, 5);
                            return Icon(
                              filled ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 14,
                              color: AppTheme.specGold,
                            );
                          }),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ratingStr,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

/// Explore-page style listing card: same design as Explore (categories) listing cards,
/// with category · subcategory line and distance. Used in the Choose for me slot popup.
class ExploreStyleListingCard extends StatelessWidget {
  const ExploreStyleListingCard({
    super.key,
    required this.listing,
    required this.subcategoryNames,
    this.cardHeight = 88,
    this.cardRadius = 16,
    this.onTap,
  });

  final MockListing listing;
  final Map<String, String> subcategoryNames;
  final double cardHeight;
  final double cardRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = listing.rating;
    final ratingStr = rating != null ? '(${rating.toStringAsFixed(1)})' : '—';
    final location = listing.address ?? '—';
    final distanceStr = listing.distanceMiles != null ? '${listing.distanceMiles!.toStringAsFixed(1)} mi' : null;
    final subName = listing.subcategoryId != null ? subcategoryNames[listing.subcategoryId!] : null;
    final categorySubLine = subName != null ? '${listing.categoryName} · $subName' : listing.categoryName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            onTap ??
            () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => ListingDetailScreen(listingId: listing.id)));
            },
        borderRadius: BorderRadius.circular(cardRadius),
        child: Container(
          height: cardHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              _Logo(logoUrl: listing.imagePlaceholder, size: 48, radius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      listing.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) {
                            final filled = rating != null && i < rating.floor().clamp(0, 5);
                            return Icon(
                              filled ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 16,
                              color: AppTheme.specGold,
                            );
                          }),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ratingStr,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  categorySubLine,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (distanceStr != null) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 2),
                                Text(
                                  distanceStr,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ],
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

class _Logo extends StatelessWidget {
  const _Logo({required this.logoUrl, this.size = 48, this.radius = 12});

  final String? logoUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final boxDecoration = BoxDecoration(
      color: AppTheme.specNavy.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(radius),
    );
    if (logoUrl != null && logoUrl!.trim().isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: boxDecoration,
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          fit: BoxFit.cover,
          width: size,
          memCacheWidth: 200,
          memCacheHeight: 200,
          height: size,
          placeholder: (_, _) =>
              Icon(Icons.store_rounded, size: size * 0.5, color: AppTheme.specNavy.withValues(alpha: 0.7)),
          errorWidget: (_, _, _) =>
              Icon(Icons.store_rounded, size: size * 0.5, color: AppTheme.specNavy.withValues(alpha: 0.7)),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: boxDecoration,
      child: Icon(Icons.store_rounded, size: size * 0.5, color: AppTheme.specNavy.withValues(alpha: 0.7)),
    );
  }
}
