import 'package:flutter/material.dart';
import 'package:cajun_local/core/data/mock_data.dart';
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

  final List<MockSpot> spots;
  final VoidCallback onExplore;
  final void Function(MockSpot spot) onTapSpot;
  final ScrollController? previewScrollController;

  static const double _cardRadius = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewSpots = spots.take(2).toList();
    if (previewSpots.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.specWhite,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.08)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  HomeSectionHeaderWidget(
                    title: 'Popular in your parish',
                    titleStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.specNavy,
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
                        Text('See all', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.specGold),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: previewScrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: previewSpots.length,
                itemBuilder: (context, index) {
                  final spot = previewSpots[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PopularCardWidget(spot: spot, onTap: () => onTapSpot(spot)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
