import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:cajun_local/core/subscription/business_tier_service.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/categories/data/models/category_banner.dart';
import 'package:cajun_local/features/explore/presentation/widgets/explore_banners.dart';
import 'package:cajun_local/features/explore/presentation/widgets/explore_listing_card.dart';
import 'package:cajun_local/shared/widgets/app_refresh_indicator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer loading skeleton
// ─────────────────────────────────────────────────────────────────────────────

class ExploreLoadingSkeleton extends StatelessWidget {
  const ExploreLoadingSkeleton({super.key, required this.padding});

  final EdgeInsets padding;

  static const int _placeholderCount = 8;
  static const double _cardRadius = 16;

  @override
  Widget build(BuildContext context) {
    final baseColor = AppTheme.specNavy.withValues(alpha: 0.08);
    final highlightColor = AppTheme.specNavy.withValues(alpha: 0.14);

    return Container(
      color: AppTheme.specOffWhite,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 24),
          itemCount: _placeholderCount,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.specWhite,
                  borderRadius: BorderRadius.circular(_cardRadius),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(12)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Category tag shimmer
                          Container(
                            height: 10,
                            width: 70,
                            decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(height: 6),
                          // Title shimmer
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(height: 6),
                          // Stars shimmer
                          Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(height: 6),
                          // Subtitle shimmer
                          Container(
                            height: 12,
                            width: 120,
                            decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(10)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List view — partners at top, then standard listings interleaved with inline
// sponsored banners every N items.
// ─────────────────────────────────────────────────────────────────────────────

class ExploreListView extends StatelessWidget {
  const ExploreListView({
    super.key,
    required this.list,
    this.tierMap = const {},
    this.sponsoredIds = const {},
    this.favoritesCounts = const {},
    this.banners = const [],
    this.categoryNames = const {},
    this.subcategoryNames = const {},
    this.featuredCount = 5,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.onRefresh,
  });

  final List<Business> list;
  final Map<String, String> tierMap;
  final Set<String> sponsoredIds;
  final Map<String, int> favoritesCounts;
  final List<CategoryBanner> banners;
  final Map<String, String> categoryNames;
  final Map<String, String> subcategoryNames;
  final int featuredCount;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final Future<void> Function()? onRefresh;

  static const double _cardRadius = 18;
  static const int _sponsoredInlineEvery = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    final listView = ListView(
      padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 110 + MediaQuery.paddingOf(context).bottom),
      children: [
        if (isLoadingMore) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Updating results…',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (banners.isNotEmpty) ...[
          ExploreCategoryBanner(banners: banners, categoryNames: categoryNames),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                'LOCAL LISTINGS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.specGold,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              // const SizedBox(width: 8),
              // Container(
              //   height: 1,
              //   width: 40,
              //   color: AppTheme.specGold.withValues(alpha: 0.35),
              // ),
            ],
          ),
        ),

        ..._buildStandardListWithSponsored(list, padding, theme),
        if (hasMore && onLoadMore != null && !isLoadingMore) ...[
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TextButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: const Text('Load more'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.specNavy),
              ),
            ),
          ),
        ],
      ],
    );

    final body = onRefresh != null ? AppRefreshIndicator(onRefresh: onRefresh!, child: listView) : listView;
    return Container(color: AppTheme.specOffWhite, child: body);
  }

  List<Widget> _buildStandardListWithSponsored(List<Business> standard, EdgeInsets padding, ThemeData theme) {
    final children = <Widget>[];
    final rnd = banners.isNotEmpty ? Random(Object.hash(standard.length, standard.hashCode)) : null;

    for (var i = 0; i < standard.length; i++) {
      if (banners.isNotEmpty && i > 0 && i % _sponsoredInlineEvery == 0) {
        final bannerIndex = rnd!.nextInt(banners.length);
        final b = banners[bannerIndex];
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SponsoredInlineCard(
              banner: b,
              headline: categoryNames[b.categoryId] ?? 'Sponsored',
              radius: _cardRadius,
              compact: true,
            ),
          ),
        );
      }

      final listing = standard[i];
      final isLocalPartner = BusinessTierService.fromPlanTier(tierMap[listing.id]) == BusinessTier.localPartner;
      final isSponsored = sponsoredIds.contains(listing.id);
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ExploreListingCard(
            listing: listing,
            tierMap: tierMap,
            cardRadius: _cardRadius,
            isLocalPartner: isLocalPartner,
            isSponsored: isSponsored,
            categoryNames: categoryNames,
            subcategoryNames: subcategoryNames,
          ),
        ),
      );
    }
    return children;
  }
}
