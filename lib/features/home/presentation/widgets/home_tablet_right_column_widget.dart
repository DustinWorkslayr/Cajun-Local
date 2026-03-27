import 'package:flutter/material.dart';
import 'package:cajun_local/features/businesses/data/models/featured_business.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'home_section_header_widget.dart';
import 'popular_card_widget.dart';

class HomeTabletRightColumnWidget extends StatelessWidget {
  const HomeTabletRightColumnWidget({
    super.key,
    required this.spots,
    required this.onExplore,
    required this.onTapSpot,
    this.previewScrollController,
  });

  final List<FeaturedBusiness> spots;
  final VoidCallback onExplore;
  final void Function(FeaturedBusiness spot) onTapSpot;
  final ScrollController? previewScrollController;

  static const double _cardRadius = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewSpots = spots.take(2).toList();
    if (previewSpots.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.specWhite,
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: Center(
          child: Text(
            'Pick your parish to see spots',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.6)),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.specNavy.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: HomeSectionHeaderWidget(
                      title: 'Popular near you',
                      subtitle: 'Highly rated spots',
                    ),
                  ),
                  TextButton(
                    onPressed: onExplore,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.specGold,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See all',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.specGold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.specGold),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: previewScrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: previewSpots.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final spot = previewSpots[index];
                  return PopularCardWidget(spot: spot, onTap: () => onTapSpot(spot));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
