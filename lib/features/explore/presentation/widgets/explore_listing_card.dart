import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/core/revenuecat/present_subscription_paywall.dart';
import 'package:cajun_local/core/subscription/resolved_permissions.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:cajun_local/shared/widgets/animated_entrance.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Business logo thumbnail
// ─────────────────────────────────────────────────────────────────────────────

class ListingLogo extends StatelessWidget {
  const ListingLogo({super.key, required this.logoUrl, this.size = 48, this.radius = 12});

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
          height: size,
          memCacheWidth: 200,
          memCacheHeight: 200,
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

// ─────────────────────────────────────────────────────────────────────────────
// Standard listing card
// ─────────────────────────────────────────────────────────────────────────────

class ExploreListingCard extends StatelessWidget {
  const ExploreListingCard({
    super.key,
    required this.listing,
    required this.tierMap,
    required this.cardRadius,
    this.isLocalPartner = false,
    this.isSponsored = false,
    this.categoryNames = const {},
    this.subcategoryNames = const {},
  });

  final Business listing;
  final Map<String, String> tierMap;
  final double cardRadius;
  final bool isLocalPartner;
  final bool isSponsored;
  final Map<String, String> categoryNames;
  final Map<String, String> subcategoryNames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catName = categoryNames[listing.categoryId] ?? 'Business';
    final location = listing.address;

    // No rating in model yet — show 5 outline stars as placeholder
    const double? rating = null;

    final Color cardBg = isLocalPartner
        ? AppTheme.specGold.withValues(alpha: 0.08)
        : AppTheme.specWhite;
    Border? border;
    if (isLocalPartner) {
      border = Border.all(color: AppTheme.specGold.withValues(alpha: 0.4), width: 1.5);
    } else if (isSponsored) {
      border = Border.all(color: Colors.blue.withValues(alpha: 0.4), width: 1.5);
    }
    final logoSize = isLocalPartner ? 54.0 : 48.0;

    return AnimatedEntrance(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(cardRadius),
        child: InkWell(
          onTap: () => context.push('/listing/${listing.id}'),
          borderRadius: BorderRadius.circular(cardRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(cardRadius),
              border: border,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.specNavy.withValues(alpha: isLocalPartner ? 0.09 : 0.06),
                  blurRadius: isLocalPartner ? 14 : 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ListingLogo(logoUrl: listing.logoUrl, size: logoSize, radius: 12),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category tag in gold caps
                      Text(
                        catName.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.specGold,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Business name
                      Text(
                        listing.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.specNavy,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Star rating row (placeholder until model has rating)
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final filled = rating != null && i < rating.floor().clamp(0, 5);
                            return Icon(
                              filled ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 13,
                              color: AppTheme.specGold,
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            rating != null ? rating.toStringAsFixed(1) : 'No rating',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.specNavy.withValues(alpha: 0.45),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Tagline or address
                      if (listing.tagline != null && listing.tagline!.isNotEmpty)
                        Text(
                          listing.tagline!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.specNavy.withValues(alpha: 0.50),
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (location != null && location.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 11,
                                color: AppTheme.specNavy.withValues(alpha: 0.35)),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                location,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.specNavy.withValues(alpha: 0.45),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (isLocalPartner) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.specGold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Local Partner',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                FavoriteHeartButton(listingId: listing.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated favourite heart button
// ─────────────────────────────────────────────────────────────────────────────

class FavoriteHeartButton extends ConsumerStatefulWidget {
  const FavoriteHeartButton({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<FavoriteHeartButton> createState() => _FavoriteHeartButtonState();
}

class _FavoriteHeartButtonState extends ConsumerState<FavoriteHeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _scale = Tween<double>(begin: 1, end: 1.25)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(userFavoriteIdsProvider).when(
      data: (ids) {
        final isFav = ids.contains(widget.listingId);
        return ScaleTransition(
          scale: _scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                _controller.forward().then((_) => _controller.reverse());
                if (isFav) {
                  await ref.read(userFavoriteIdsProvider.notifier).remove(widget.listingId);
                } else {
                  final perms = ref.read(userTierServiceProvider).value ?? ResolvedPermissions.free;
                  if (perms.wouldExceedFavoritesLimit(ids.length)) {
                    if (!context.mounted) return;
                    await presentSubscriptionPaywall(context, ref);
                    return;
                  }
                  await ref.read(userFavoriteIdsProvider.notifier).add(widget.listingId);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 22,
                  color: isFav ? AppTheme.specGold : AppTheme.specNavy.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
