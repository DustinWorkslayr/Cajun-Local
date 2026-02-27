import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/category_icons.dart';
import 'package:my_app/core/data/models/blog_post.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/repositories/blog_posts_repository.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:my_app/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:my_app/features/news/presentation/screens/news_post_detail_screen.dart';
import 'package:my_app/features/news/presentation/screens/news_screen.dart';
import 'package:my_app/shared/widgets/animated_entrance.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/app_logo.dart';
import 'package:my_app/shared/widgets/dismissible_alert_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.openMenu,
    this.onSelectCategory,
    this.onNavigateToExplore,
    this.onNavigateToDeals,
    this.onOpenLocalEvents,
    this.onOpenChooseForMe,
  });

  /// Called to open the app menu (hamburger). Provided by MainShell.
  final VoidCallback? openMenu;

  /// When user taps a category, switch to Explore tab with this category selected. Provided by MainShell.
  final void Function(MockCategory category)? onSelectCategory;

  /// When user taps "Explore" or "View All", switch to Explore tab. Provided by MainShell.
  final VoidCallback? onNavigateToExplore;

  /// Switch to Deals tab. Optional.
  final VoidCallback? onNavigateToDeals;

  /// Open Local Events screen. Optional.
  final VoidCallback? onOpenLocalEvents;

  /// Open Choose for Me screen. Optional.
  final VoidCallback? onOpenChooseForMe;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Future<(List<MockSpot>, List<MockCategory>)>? _homeFuture;
  Future<List<BlogPost>>? _latestPostsFuture;

  static const double _cardRadius = 20;
  static const double _bannerMinHeight = 220;
  static const double _paddingMobile = 20;
  static const double _paddingTablet = 44;
  static const double _sectionTitleBottom = 12;
  static const double _sectionSpacing = 32;
  static const double _cardGap = 16;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_homeFuture == null) {
      final ds = AppDataScope.of(context).dataSource;
      _homeFuture = Future.wait([
        ds.getFeaturedSpots(),
        ds.getCategories(),
      ]).then((r) => (r[0] as List<MockSpot>, r[1] as List<MockCategory>));
    }
    _latestPostsFuture ??= BlogPostsRepository().listApproved(limit: 10);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmitted() {
    final query = _searchController.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoriesScreen(initialSearch: query.isEmpty ? null : query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.sizeOf(context).width >= AppTheme.breakpointTablet;
    final horizontalPad = isTablet ? _paddingTablet : _paddingMobile;
    final padding = EdgeInsets.symmetric(horizontal: horizontalPad);
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (_homeFuture == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _homeFuture != null) return;
        setState(() {
          final ds = AppDataScope.of(context).dataSource;
          _homeFuture = Future.wait([
            ds.getFeaturedSpots(),
            ds.getCategories(),
          ]).then((r) => (r[0] as List<MockSpot>, r[1] as List<MockCategory>));
        });
      });
      return Container(
        color: AppTheme.specOffWhite,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppTheme.specNavy),
      );
    }
    return LayoutBuilder(
      builder: (context, contentConstraints) {
        return Container(
      color: AppTheme.specOffWhite,
      child: FutureBuilder<(List<MockSpot>, List<MockCategory>)>(
        future: _homeFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Loading data failed.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() {
                        _homeFuture = null;
                        final ds = AppDataScope.of(context).dataSource;
                        _homeFuture = Future.wait([
                          ds.getFeaturedSpots(),
                          ds.getCategories(),
                        ]).then((r) => (r[0] as List<MockSpot>, r[1] as List<MockCategory>));
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.specNavy),
            );
          }
          final spots = snapshot.data?.$1 ?? <MockSpot>[];
          final categories = snapshot.data?.$2 ?? <MockCategory>[];
          return CustomScrollView(
            slivers: [
              // ——— Notification banner (below topbar) ———
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding.left, 4, padding.right, 0),
                  child: DismissibleAlertBanner(horizontalPadding: padding, compact: true),
                ),
              ),
              // ——— Hero: logo, tagline, primary CTAs (blue card; 23px narrower to match design) ———
              SliverToBoxAdapter(
                child: AnimatedEntrance(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding.left + 11.5, 8, padding.right + 11.5, _sectionSpacing),
                    child: _HomeHero(
                      onExplore: () {
                        if (widget.onNavigateToExplore != null) {
                          widget.onNavigateToExplore!();
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
                          );
                        }
                      },
                      onFavorites: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ——— Search section ———
              SliverToBoxAdapter(
                child: AnimatedEntrance(
                  delay: const Duration(milliseconds: 60),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacing),
                    child: Material(
                      color: AppTheme.specWhite,
                      borderRadius: BorderRadius.circular(_cardRadius),
                      elevation: 0,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_cardRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onSubmitted: (_) => _onSearchSubmitted(),
                          decoration: InputDecoration(
                            hintText: 'Find by name or category — then explore',
                            hintStyle: theme.textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppTheme.specNavy,
                              size: 24,
                            ),
                            suffixIcon: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _searchController,
                              builder: (context, value, _) {
                                if (value.text.isNotEmpty) {
                                  return IconButton(
                                    icon: Icon(Icons.clear_rounded, color: AppTheme.specNavy, size: 22),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                    tooltip: 'Clear',
                                  );
                                }
                                return IconButton(
                                  icon: Icon(Icons.arrow_forward_rounded, color: AppTheme.specNavy, size: 22),
                                  onPressed: _onSearchSubmitted,
                                  tooltip: 'Search in Explore',
                                );
                              },
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ——— Quick actions: Deals, Events, Choose for Me ———
              SliverToBoxAdapter(
                child: AnimatedEntrance(
                  delay: const Duration(milliseconds: 80),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacing),
                    child: _QuickActions(
                      onDeals: widget.onNavigateToDeals,
                      onEvents: widget.onOpenLocalEvents,
                      onChooseForMe: widget.onOpenChooseForMe,
                    ),
                  ),
                ),
              ),

              // ——— Popular Near You ———
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Popular Near You',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.specNavy,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Top local spots to discover',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.specNavy.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              if (widget.onNavigateToExplore != null) {
                                widget.onNavigateToExplore!();
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.specGold,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'See all',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.specGold),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              isTablet
                  ? SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacing),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: _cardGap,
                          crossAxisSpacing: _cardGap,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final spot = spots[index];
                            return AnimatedEntrance(
                              delay: Duration(milliseconds: 80 + (index * 60)),
                              child: _PopularCard(
                                spot: spot,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ListingDetailScreen(listingId: spot.id),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          childCount: spots.length,
                        ),
                      ),
                    )
                  : SliverToBoxAdapter(
                      child: SizedBox(
                        height: 252,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(
                            left: padding.left,
                            right: padding.right,
                            bottom: 4,
                          ),
                          clipBehavior: Clip.none,
                          itemCount: spots.length,
                          itemBuilder: (context, index) {
                            final spot = spots[index];
                            final cardWidth = (screenWidth - padding.left - padding.right - _cardGap * 2) * 0.72;
                            return Padding(
                              padding: EdgeInsets.only(right: _cardGap),
                              child: AnimatedEntrance(
                                delay: Duration(milliseconds: 80 + (index * 60)),
                                child: _PopularCard(
                                  spot: spot,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ListingDetailScreen(listingId: spot.id),
                                      ),
                                    );
                                  },
                                  cardWidth: cardWidth,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

              // ——— Local Stories (blog) ———
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding.left, _sectionSpacing, padding.right, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Local Stories',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.specNavy,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'News and stories from Acadiana',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.specNavy.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const NewsScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.specGold,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'See all',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.specGold),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FutureBuilder<List<BlogPost>>(
                  future: _latestPostsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacing),
                        child: SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(color: AppTheme.specNavy),
                          ),
                        ),
                      );
                    }
                    final posts = snapshot.data ?? [];
                    if (posts.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacing),
                        child: Container(
                          height: 160,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.specWhite,
                            borderRadius: BorderRadius.circular(_cardRadius),
                            border: Border.all(
                              color: AppTheme.specNavy.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(
                            'No stories yet. Check back soon.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.specNavy.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      );
                    }
                    if (isTablet) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacing),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: _cardGap,
                            crossAxisSpacing: _cardGap,
                            childAspectRatio: 1.05,
                          ),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return AnimatedEntrance(
                              delay: Duration(milliseconds: 100 + (index * 60)),
                              child: _LatestPostCard(
                                post: post,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => NewsPostDetailScreen(postId: post.id),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    }
                    // Mobile: horizontal scroll for compact, swipeable showcase
                    final blogCardWidth = (screenWidth - padding.left - padding.right - _cardGap * 2) * 0.78;
                    return Padding(
                      padding: EdgeInsets.only(bottom: _sectionSpacing),
                      child: SizedBox(
                        height: 268,
                        child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.only(left: padding.left, right: padding.right, bottom: 4),
                        clipBehavior: Clip.none,
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return Padding(
                            padding: EdgeInsets.only(right: _cardGap),
                            child: AnimatedEntrance(
                              delay: Duration(milliseconds: 100 + (index * 60)),
                              child: _LatestPostCard(
                                post: post,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => NewsPostDetailScreen(postId: post.id),
                                    ),
                                  );
                                },
                                cardWidth: blogCardWidth,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    );
                  },
                ),
              ),

              // ——— Browse by category ———
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding.left, _sectionSpacing, padding.right, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browse by category',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.specNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 3,
                        width: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.specGold.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: _sectionTitleBottom)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 4 : 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: isTablet ? 1.1 : 1.25,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final cat = categories[index];
                      return AnimatedEntrance(
                        delay: Duration(milliseconds: 120 + (index * 50)),
                        child: _CategoryCard(
                          category: cat,
                          onTap: () {
                            if (widget.onSelectCategory != null) {
                              widget.onSelectCategory!(cat);
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => CategoriesScreen(initialCategoryId: cat.id),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                    childCount: categories.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: _sectionSpacing + 8)),
              // Extra bottom padding so content clears nav and safe area (avoids bottom overflow).
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 24 + MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          );
        },
      ),
    );
      },
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.onExplore, required this.onFavorites});

  final VoidCallback onExplore;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_HomeScreenState._cardRadius),
      child: Stack(
        children: [
          Container(
            height: _HomeScreenState._bannerMinHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.specNavy,
                  AppTheme.specNavy.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          SizedBox(
            height: _HomeScreenState._bannerMinHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogo(height: 52),
                    const SizedBox(height: 16),
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
                      'Explore restaurants, shops, events, and deals — all in one place.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.specWhite.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                      AppSecondaryButton(
                        onPressed: onExplore,
                        child: const Text('Explore'),
                      ),
                      const SizedBox(width: 12),
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
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(_HomeScreenState._cardRadius)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    this.onDeals,
    this.onEvents,
    this.onChooseForMe,
  });

  final VoidCallback? onDeals;
  final VoidCallback? onEvents;
  final VoidCallback? onChooseForMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);

    Widget chip(String label, IconData icon, VoidCallback? onTap) {
      final enabled = onTap != null;
      return Material(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: enabled ? AppTheme.specGold.withValues(alpha: 0.5) : nav.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: enabled ? AppTheme.specGold : sub),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: enabled ? nav : sub,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: chip('Deals', Icons.local_offer_rounded, onDeals)),
        const SizedBox(width: 12),
        Expanded(child: chip('Events', Icons.event_rounded, onEvents)),
        const SizedBox(width: 12),
        Expanded(child: chip('Choose for Me', Icons.shuffle_rounded, onChooseForMe)),
      ],
    );
  }
}

class _PopularCard extends StatelessWidget {
  const _PopularCard({required this.spot, required this.onTap, this.cardWidth});

  final MockSpot spot;
  final VoidCallback onTap;
  /// When set (e.g. horizontal scroll), use this width; otherwise full width for grid.
  final double? cardWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = 18.0;
    final hasImage = spot.logoUrl != null && spot.logoUrl!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: hasImage
                          ? Image.network(
                              spot.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _placeholderImage(),
                            )
                          : _placeholderImage(),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppTheme.specGold,
                              AppTheme.specGold.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (spot.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        spot.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: AppTheme.specGold),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'View listing',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.specGold,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.specNavy.withValues(alpha: 0.5)),
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

  Widget _placeholderImage() {
    return Container(
      color: AppTheme.specNavy.withValues(alpha: 0.06),
      child: Center(
        child: Icon(Icons.store_rounded, size: 44, color: AppTheme.specNavy.withValues(alpha: 0.25)),
      ),
    );
  }
}

class _LatestPostCard extends StatelessWidget {
  const _LatestPostCard({required this.post, required this.onTap, this.cardWidth});

  final BlogPost post;
  final VoidCallback onTap;
  /// When set (e.g. horizontal scroll), use this width; otherwise full width for grid.
  final double? cardWidth;

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${d.month}/${d.day}/${d.year}';
  }

  static String _shortExcerpt(String? excerpt, {int maxLen = 72}) {
    if (excerpt == null || excerpt.trim().isEmpty) return '';
    final t = excerpt.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen).trim()}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = 18.0;
    final hasCover = post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty;
    final dateStr = _formatDate(post.publishedAt ?? post.createdAt);
    final excerpt = _shortExcerpt(post.excerpt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 128,
                      width: double.infinity,
                      child: hasCover
                          ? Image.network(
                              post.coverImageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, _, _) => _placeholderCover(),
                            )
                          : _placeholderCover(),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppTheme.specGold,
                              AppTheme.specGold.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                        height: 1.28,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        excerpt,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.7),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 14, color: AppTheme.specNavy.withValues(alpha: 0.55)),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.specNavy.withValues(alpha: 0.65),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Read',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.specGold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.specGold),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      color: AppTheme.specNavy.withValues(alpha: 0.06),
      child: Center(
        child: Icon(Icons.article_rounded, size: 44, color: AppTheme.specNavy.withValues(alpha: 0.25)),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final MockCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_HomeScreenState._cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(_HomeScreenState._cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                getCategoryIconData(category.iconName),
                size: 40,
                color: AppTheme.specNavy,
              ),
              const SizedBox(height: 14),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.specNavy,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (category.count > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${category.count} spots',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Container(
                height: 3,
                width: 32,
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
