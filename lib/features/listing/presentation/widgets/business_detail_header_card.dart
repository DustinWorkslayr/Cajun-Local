import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/core/revenuecat/present_subscription_paywall.dart';
import 'package:cajun_local/core/subscription/resolved_permissions.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:cajun_local/features/listing/presentation/providers/listing_detail_provider.dart';

/// Clean card matching the Stitch v2 style:
/// Rounded corners, soft shadow, image at top, white content below.
class BusinessDetailHeaderCard extends ConsumerWidget {
  const BusinessDetailHeaderCard({super.key, required this.data, required this.onReload});

  final ListingDetailData data;
  final VoidCallback onReload;
  static const double _radius = 24.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = data.listing;
    final theme = Theme.of(context);
    
    // Find a good image
    final showCarousel = data.isPartner && data.imageUrls.length > 1;
    final singleUrl = data.bannerImageUrl ?? (data.imageUrls.isNotEmpty ? data.imageUrls.first : null);

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top image/carousel section ──────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(_radius)),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  showCarousel
                      ? PageView.builder(
                          itemCount: data.imageUrls.length,
                          itemBuilder: (_, i) => _HeroImage(url: data.imageUrls[i]),
                        )
                      : singleUrl != null
                          ? _HeroImage(url: singleUrl)
                          : const _NavyPlaceholder(),

                  // Open/Closed Badge (bottom left of image)
                  if (listing.isOpenNow != null)
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
                              color: listing.isOpenNow! 
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
                                    color: listing.isOpenNow! ? AppTheme.specGold : Colors.white70,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      if (listing.isOpenNow!)
                                        BoxShadow(color: AppTheme.specGold.withValues(alpha: 0.6), blurRadius: 4, spreadRadius: 1),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  listing.isOpenNow! ? 'OPEN NOW' : 'CLOSED',
                                  style: TextStyle(
                                    color: listing.isOpenNow! ? Colors.white : Colors.white70,
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
                    
                  // Partner/tier badge (bottom right)
                  if (data.subscriptionTier != null && data.subscriptionTier!.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: _TierBadge(tier: data.subscriptionTier!),
                    ),
                ],
              ),
            ),
          ),

          // ── White content section ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.specNavy,
                    fontSize: 22,
                    height: 1.15,
                  ),
                ),
                if (listing.tagline != null && listing.tagline!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    listing.tagline!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specOutline),
                  ),
                ],

                const SizedBox(height: 12),

                // Metadata Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (data.reviewCount > 0) _RatingChip(rating: data.averageRating, count: data.reviewCount),
                    if (listing.parish != null) _Chip(icon: Icons.location_on_rounded, label: listing.parish!),
                    if (data.distanceMi != null) _Chip(icon: Icons.near_me_rounded, label: '${data.distanceMi!.toStringAsFixed(1)} mi'),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(height: 1, color: AppTheme.specSurfaceContainerHigh),
                const SizedBox(height: 20),

                // Action buttons
                _ActionRow(listing: listing, data: data, onReload: onReload),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared private helpers ─────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => const _NavyPlaceholder(),
        errorWidget: (_, __, ___) => const _NavyPlaceholder(),
      );
}

class _NavyPlaceholder extends StatelessWidget {
  const _NavyPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        color: AppTheme.specSurfaceContainerHigh,
        child: const Center(child: Icon(Icons.store_rounded, size: 40, color: AppTheme.specOutline)),
      );
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});
  final String tier;

  @override
  Widget build(BuildContext context) {
    final t = tier.toLowerCase();
    final label = (t == 'local_partner' || t == 'enterprise' || t == 'premium') ? '★ Local Partner' : '+ Local Plus';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.7)),
      ),
      child: Text(label, style: const TextStyle(color: AppTheme.specGold, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating, required this.count});
  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AppTheme.specSurfaceContainer, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, size: 13, color: AppTheme.specGold),
          const SizedBox(width: 4),
          Text(
            '${rating.toStringAsFixed(1)} ($count)',
            style: const TextStyle(color: AppTheme.specNavy, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ]),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AppTheme.specSurfaceContainer, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: AppTheme.specOutline),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppTheme.specNavy, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _ActionRow extends ConsumerWidget {
  const _ActionRow({required this.listing, required this.data, required this.onReload});
  final Business listing;
  final ListingDetailData data;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CircleAction(
          icon: Icons.phone_rounded,
          label: 'Call',
          enabled: listing.phone != null,
          onTap: listing.phone != null ? () => _open('tel:${listing.phone}') : null,
        ),
        _CircleAction(
          icon: Icons.directions_rounded,
          label: 'Directions',
          enabled: listing.address != null,
          onTap: listing.address != null
              ? () => _open('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(listing.address!)}')
              : null,
        ),
        ref.watch(userFavoriteIdsProvider).when(
          data: (ids) {
            final isFav = ids.contains(listing.id);
            return _CircleAction(
              icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              label: isFav ? 'Saved' : 'Save',
              enabled: true,
              highlight: isFav,
              onTap: () async {
                if (isFav) {
                  await ref.read(userFavoriteIdsProvider.notifier).remove(listing.id);
                } else {
                  final perms = ref.read(userTierServiceProvider).value ?? ResolvedPermissions.free;
                  if (perms.wouldExceedFavoritesLimit(ids.length)) {
                    if (!context.mounted) return;
                    await presentSubscriptionPaywall(context, ref);
                    return;
                  }
                  await ref.read(userFavoriteIdsProvider.notifier).add(listing.id);
                }
              },
            );
          },
          loading: () => const _CircleAction(icon: Icons.favorite_border_rounded, label: 'Save', enabled: false),
          error: (_, __) => const _CircleAction(icon: Icons.favorite_border_rounded, label: 'Save', enabled: false),
        ),
        _CircleAction(
          icon: listing.website != null ? Icons.language_rounded : Icons.share_rounded,
          label: listing.website != null ? 'Website' : 'Share',
          enabled: true,
          onTap: listing.website != null ? () => _open(listing.website!) : () {},
        ),
      ],
    );
  }

  static Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.enabled,
    this.highlight = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = highlight ? AppTheme.specGold : AppTheme.specNavy;
    final bgColor = highlight ? AppTheme.specGold.withValues(alpha: 0.08) : AppTheme.specSurfaceContainer;

    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: bgColor,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(icon, size: 22, color: iconColor),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.specNavy,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
