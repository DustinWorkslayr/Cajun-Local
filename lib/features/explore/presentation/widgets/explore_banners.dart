import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/categories/data/models/category_banner.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Carousel banner widget (top of the list when banners exist)
// ─────────────────────────────────────────────────────────────────────────────

class ExploreCategoryBanner extends StatefulWidget {
  const ExploreCategoryBanner({
    super.key,
    required this.banners,
    required this.categoryNames,
  });

  final List<CategoryBanner> banners;
  final Map<String, String> categoryNames;

  @override
  State<ExploreCategoryBanner> createState() => _ExploreCategoryBannerState();
}

class _ExploreCategoryBannerState extends State<ExploreCategoryBanner> {
  late PageController _pageController;
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (!mounted || !_pageController.hasClients) return;
        final next = (_currentPage.value + 1) % widget.banners.length;
        _pageController.animateToPage(
            next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      });
    }
  }

  void _onPageChanged() {
    if (!_pageController.hasClients) return;
    final page = (_pageController.page ?? 0).round().clamp(0, widget.banners.length - 1);
    if (_currentPage.value != page) _currentPage.value = page;
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _timer?.cancel();
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    final categoryNames = widget.categoryNames;
    if (banners.isEmpty) return const SizedBox.shrink();

    final padding = AppLayout.horizontalPadding(context);
    const radius = 18.0;
    const bannerHeight = 160.0;

    if (banners.length == 1) {
      return Padding(
        padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 12),
        child: SizedBox(
          height: bannerHeight,
          child: BannerCard(
            banner: banners[0],
            headline: categoryNames[banners[0].categoryId] ?? 'Explore',
            radius: radius,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: bannerHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final b = banners[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: BannerCard(
                      banner: b,
                      headline: categoryNames[b.categoryId] ?? 'Explore',
                      radius: radius),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: _currentPage,
            builder: (context, current, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  banners.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: (current % banners.length) == i ? 10 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: (current % banners.length) == i
                          ? AppTheme.specGold
                          : AppTheme.specNavy.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual banner card (image + overlay + CTA)
// ─────────────────────────────────────────────────────────────────────────────

class BannerCard extends StatelessWidget {
  const BannerCard({
    super.key,
    required this.banner,
    required this.headline,
    required this.radius,
  });

  final CategoryBanner banner;
  final String headline;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (banner.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: banner.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => _placeholder(),
              errorWidget: (_, _, _) => _placeholder(),
            )
          else
            _placeholder(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppTheme.specNavy.withValues(alpha: 0.75)],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.specNavy.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Sponsored',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.specOffWhite,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.specWhite,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Discover local spots in this category',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.specOffWhite.withValues(alpha: 0.9),
                      ),
                ),
                const SizedBox(height: 10),
                AppPrimaryButton(onPressed: () {}, expanded: false, child: const Text('Explore')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppTheme.specNavy.withValues(alpha: 0.2),
        child: Icon(Icons.image_rounded, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.4)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline sponsored card (interspersed in the list every N items)
// ─────────────────────────────────────────────────────────────────────────────

class SponsoredInlineCard extends StatelessWidget {
  const SponsoredInlineCard({
    super.key,
    required this.banner,
    required this.headline,
    required this.radius,
    this.compact = false,
  });

  final CategoryBanner banner;
  final String headline;
  final double radius;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 48 : 64,
            height: compact ? 48 : 64,
            decoration: BoxDecoration(
              color: AppTheme.specNavy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: banner.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: banner.imageUrl, fit: BoxFit.cover),
                  )
                : Icon(Icons.campaign_rounded, color: AppTheme.specGold, size: compact ? 24 : 32),
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sponsored',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  headline,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.specNavy,
                      ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  AppPrimaryButton(onPressed: () {}, expanded: false, child: const Text('Explore')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
