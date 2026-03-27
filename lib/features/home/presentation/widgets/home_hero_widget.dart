import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/theme.dart';

/// Hero section — full-bleed gradient (navy to navy-container) with the
/// existing skyline background image at low opacity blend. Text anchored
/// at the bottom exactly as in the Stitch "Cajun Local Redesigned v2" spec.
class HomeHeroWidget extends StatelessWidget {
  const HomeHeroWidget({
    super.key,
    required this.isTablet,
    required this.onExplore,
    required this.onFavorites,
    required this.padding,
  });

  final bool isTablet;
  final VoidCallback onExplore;
  final VoidCallback onFavorites;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final height = isTablet ? 280.0 : 220.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
          // 1. Navy-to-navy-container gradient (Stitch: bg-gradient-to-br from-primary to-primary-container)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.specNavy, AppTheme.specNavyContainer],
              ),
            ),
          ),

          // 2. Background image at 40% opacity with overlay blend (user's exception: keep skyline)
          Opacity(
            opacity: 0.4,
            child: Image.asset(
              'assets/images/skyline-1.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // 3. Text content anchored to bottom-left (Stitch: flex items-end p-8)
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, isTablet ? 64 : 56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover & Support Acadiana businesses',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Experience the authentic heart of Cajun country.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.specOnPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
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
