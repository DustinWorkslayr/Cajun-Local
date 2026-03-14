import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';

class HomeHeroWidget extends StatelessWidget {
  const HomeHeroWidget({
    super.key,
    required this.isTablet,
    required this.onExplore,
    required this.onFavorites,
  });

  final bool isTablet;
  final VoidCallback onExplore;
  final VoidCallback onFavorites;

  static const double _cardRadius = 20;
  static const double _bannerMinHeight = 220;
  static const double _bannerMinHeightTablet = 280;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bannerHeight = isTablet ? _bannerMinHeightTablet : _bannerMinHeight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_cardRadius),
      child: Stack(
        children: [
          Container(
            height: bannerHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.specNavy, AppTheme.specNavy.withValues(alpha: 0.92)],
              ),
            ),
          ),
          // Skyline at bottom for Cajun / Acadiana feel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(_cardRadius)),
              child: SizedBox(
                height: bannerHeight * 0.45,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(AppTheme.specWhite.withValues(alpha: 0.12), BlendMode.srcATop),
                  child: Image.asset('assets/images/skyline-1.png', fit: BoxFit.cover, width: double.infinity),
                ),
              ),
            ),
          ),
          SizedBox(
            height: bannerHeight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(28, isTablet ? 28 : 24, 28, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover & support local',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.specWhite.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Acadiana businesses',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppTheme.specGold,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Restaurants, shops, events & deals — all in one place.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.specWhite.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        AppSecondaryButton(onPressed: onExplore, child: const Text('Explore')),
                        Material(
                          color: AppTheme.specOffWhite,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: onFavorites,
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Text(
                                'Favorites',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppTheme.specNavy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.specGold,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(_cardRadius)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
