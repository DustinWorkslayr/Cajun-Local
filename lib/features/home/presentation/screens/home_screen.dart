import 'dart:async';
import 'package:cajun_local/features/home/data/models/home_models.dart';
import 'package:cajun_local/features/businesses/data/models/featured_business.dart';
import 'package:cajun_local/features/profile/data/models/user_parish_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cajun_local/features/home/presentation/providers/home_providers.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/features/businesses/data/models/business_category.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/animated_entrance.dart';
import 'package:cajun_local/shared/widgets/dismissible_alert_banner.dart';
import 'package:cajun_local/shared/widgets/parish_onboarding_dialog.dart';
import 'package:cajun_local/shared/widgets/app_empty_state.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/shared/widgets/app_refresh_indicator.dart';

// Widgets
import '../widgets/home_hero_widget.dart';
import '../widgets/home_quick_actions_widget.dart';
import '../widgets/home_section_header_widget.dart';
import '../widgets/latest_post_card_widget.dart';
import '../widgets/popular_card_widget.dart';
import '../widgets/upcoming_event_card_widget.dart';
import '../widgets/category_card_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    this.parishPrefsVersion = 0,
    this.openMenu,
    this.onNavigateToExplore,
    this.onNavigateToNews,
    this.onNavigateToNewsPost,
    this.onNavigateToDeals,
    this.onOpenLocalEvents,
    this.onOpenChooseForMe,
    this.onNavigateToFavorites,
    this.onSelectCategory,
  });

  final int parishPrefsVersion;
  final VoidCallback? openMenu;
  final VoidCallback? onNavigateToExplore;
  final VoidCallback? onNavigateToNews;
  final void Function(String)? onNavigateToNewsPost;
  final VoidCallback? onNavigateToDeals;
  final VoidCallback? onOpenLocalEvents;
  final VoidCallback? onOpenChooseForMe;
  final VoidCallback? onNavigateToFavorites;
  final void Function(BusinessCategory)? onSelectCategory;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ScrollController _blogScrollController;
  late final ScrollController _heroPreviewScrollController;
  late final ScrollController _eventsScrollController;
  late final ScrollController _popularScrollController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  static const double _sectionSpacing = 32;
  static const double _sectionSpacingLarge = 40;
  static const double _cardGap = 16;
  static const double _sectionTitleBottom = 12;

  @override
  void initState() {
    super.initState();
    _blogScrollController = ScrollController();
    _heroPreviewScrollController = ScrollController();
    _eventsScrollController = ScrollController();
    _popularScrollController = ScrollController();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    // Check onboarding on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  @override
  void dispose() {
    _blogScrollController.dispose();
    _heroPreviewScrollController.dispose();
    _eventsScrollController.dispose();
    _popularScrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkOnboarding() async {
    final prefs = ref.read(homePreferredParishNamesProvider);
    if (!prefs.hasValue || (prefs.hasValue && prefs.value!.isEmpty)) {
      if (mounted) {
        final initialParishIds = await UserParishPreferences.getPreferredParishIds();
        final initialInterestIds = await UserParishPreferences.getPreferredInterestIds();
        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => ParishOnboardingDialog(
              initialParishIds: initialParishIds,
              initialInterestIds: initialInterestIds,
              onComplete: (parishIds, interestIds) async {
                await UserParishPreferences.setPreferredParishIds(parishIds);
                await UserParishPreferences.setPreferredInterestIds(interestIds);
                await UserParishPreferences.setCompletedParishOnboarding();
                if (ctx.mounted) Navigator.of(ctx).pop();
                _refreshAll();
              },
            ),
          );
        }
      }
    }
  }

  void _refreshAll() {
    ref.invalidate(homeFeaturedSpotsProvider);
    ref.invalidate(homeCategoriesProvider);
    ref.invalidate(homeLatestPostsProvider);
    ref.invalidate(homeUpcomingEventsProvider);
    ref.invalidate(homePreferredParishNamesProvider);
    ref.invalidate(homeParishesProvider);
  }

  void _onSearchSubmitted() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.go('/explore?search=$query');
    } else {
      context.go('/explore');
    }
  }

  String _parishLabelForPost(BlogPost post, Map<String, String> idToName) {
    if (post.isAllParishes) return 'All parishes';
    if (post.parishIds == null) return '';
    return post.parishIds!.map((id) => idToName[id] ?? id).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= AppTheme.breakpointTablet;
    final horizontalPad = AppLayout.horizontalPadding(context).left;
    final padding = EdgeInsets.symmetric(horizontal: horizontalPad);

    // Watch all granular providers
    final featuredAsync = ref.watch(homeFeaturedSpotsProvider);
    final categoriesAsync = ref.watch(homeCategoriesProvider);
    final postsAsync = ref.watch(homeLatestPostsProvider);
    final eventsAsync = ref.watch(homeUpcomingEventsProvider);
    final prefNamesAsync = ref.watch(homePreferredParishNamesProvider);
    final parishesAsync = ref.watch(homeParishesProvider);

    return Container(
      color: AppTheme.specOffWhite,
      child: AppRefreshIndicator(
        onRefresh: () async => _refreshAll(),
        child: AppLayout.constrainSection(
          context,
          CustomScrollView(
            slivers: [
              // --- Notification banner ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding.left, 4, padding.right, 0),
                  child: DismissibleAlertBanner(horizontalPadding: padding, compact: true),
                ),
              ),

              // --- Hero + Search Section ---
              SliverToBoxAdapter(
                child: AnimatedEntrance(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      HomeHeroWidget(
                        isTablet: isTablet,
                        padding: padding,
                        onExplore: () {
                          if (widget.onNavigateToExplore != null) {
                            widget.onNavigateToExplore!();
                          } else {
                            context.go('/explore');
                          }
                        },
                        onFavorites: () {
                          if (widget.onNavigateToFavorites != null) {
                            widget.onNavigateToFavorites!();
                          } else {
                            context.go('/favorites');
                          }
                        },
                      ),

                      // Overlapping Search Bar
                      Positioned(
                        left: padding.left,
                        right: padding.right,
                        bottom: -28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.specWhite,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF191C1D).withValues(alpha: 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onSubmitted: (_) => _onSearchSubmitted(),
                                  style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specOnSurface),
                                  decoration: InputDecoration(
                                    hintText: 'Find local flavor...',
                                    hintStyle: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specOutline),
                                    prefixIcon: Icon(Icons.search_rounded, color: AppTheme.specOutline, size: 22),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                                  ),
                                  textInputAction: TextInputAction.search,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Material(
                                  color: AppTheme.specGold,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: _onSearchSubmitted,
                                    borderRadius: BorderRadius.circular(12),
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 52)),

              // --- Parish selection ---
              prefNamesAsync.maybeWhen(
                data: (names) => names.isEmpty
                    ? const SliverToBoxAdapter(child: SizedBox())
                    : SliverToBoxAdapter(
                        child: AnimatedEntrance(
                          delay: const Duration(milliseconds: 40),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 12),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  final initialParishIds = await UserParishPreferences.getPreferredParishIds();
                                  final initialInterestIds = await UserParishPreferences.getPreferredInterestIds();
                                  if (context.mounted) {
                                    await showDialog<void>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) => ParishOnboardingDialog(
                                        initialParishIds: initialParishIds,
                                        initialInterestIds: initialInterestIds,
                                        onComplete: (parishIds, interestIds) async {
                                          await UserParishPreferences.setPreferredParishIds(parishIds);
                                          await UserParishPreferences.setPreferredInterestIds(interestIds);
                                          await UserParishPreferences.setCompletedParishOnboarding();
                                          if (ctx.mounted) Navigator.of(ctx).pop();
                                          _refreshAll();
                                        },
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.specGold.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, color: AppTheme.specGold, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Browsing in',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: AppTheme.specNavy.withValues(alpha: 0.6),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              names.join(', '),
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                color: AppTheme.specNavy,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.specNavy),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                orElse: () => const SliverToBoxAdapter(child: SizedBox()),
              ),

              SliverToBoxAdapter(
                child: AnimatedEntrance(
                  delay: const Duration(milliseconds: 80),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacingLarge),
                    child: HomeQuickActionsWidget(
                      isTablet: width > 500,
                      onDeals: widget.onNavigateToDeals,
                      onEvents: widget.onOpenLocalEvents,
                      onChooseForMe: widget.onOpenChooseForMe,
                    ),
                  ),
                ),
              ),

              // Upcoming events
              ...eventsAsync.maybeWhen(
                data: (events) => _buildEventsSection(events, theme, padding),
                loading: () => [const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))],
                orElse: () => [const SliverToBoxAdapter(child: SizedBox())],
              ),

              // Popular Near You
              ...featuredAsync.maybeWhen(
                data: (spots) => _buildPopularSection(spots, theme, width, isTablet, padding),
                loading: () => [const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))],
                orElse: () => [const SliverToBoxAdapter(child: SizedBox())],
              ),

              // Categories
              ...categoriesAsync.maybeWhen(
                data: (cats) => _buildCategoriesSection(cats, theme, width, isTablet, padding),
                loading: () => [const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))],
                orElse: () => [const SliverToBoxAdapter(child: SizedBox())],
              ),

              // Local Stories
              ...postsAsync.maybeWhen(
                data: (posts) {
                  return parishesAsync.maybeWhen(
                    data: (parishes) {
                      final idToName = parishes.map((p) => MapEntry(p.id, p.name));
                      final map = Map<String, String>.fromEntries(idToName);
                      return _buildStoriesSection(posts, map, theme, width, padding);
                    },
                    orElse: () => _buildStoriesSection(posts, {}, theme, width, padding),
                  );
                },
                loading: () => [const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))],
                orElse: () => [const SliverToBoxAdapter(child: SizedBox())],
              ),

              // Bottom spacing
              SliverToBoxAdapter(child: const SizedBox(height: _sectionSpacing + 8)),
              SliverToBoxAdapter(child: SizedBox(height: 110 + MediaQuery.paddingOf(context).bottom)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEventsSection(List<HomeEvent> events, ThemeData theme, EdgeInsets padding) {
    return [
      SliverToBoxAdapter(
        child: AnimatedEntrance(
          delay: const Duration(milliseconds: 90),
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: HomeSectionHeaderWidget(title: 'This week in Acadiana', subtitle: 'Events & happenings')),
                    if (events.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          if (widget.onOpenLocalEvents != null) {
                            widget.onOpenLocalEvents!();
                          } else {
                            context.push('/local-events');
                          }
                        },
                        child: Row(
                          children: [
                            Text(
                              'See all',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.specGold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.specGold),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (events.isEmpty)
                  const AppEmptyState(
                    message: 'No events scheduled this week',
                    icon: Icons.event_available_outlined,
                    padding: EdgeInsets.symmetric(vertical: 20),
                  )
                else
                  GridView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: events.length > 4 ? 4 : events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final isFeatured = index % 2 != 0;
                      return UpcomingEventCardWidget(
                        event: event,
                        featured: isFeatured,
                        onTap: () => context.push('/listing/${event.businessId}'),
                      );
                    },
                  ),
                const SizedBox(height: _sectionSpacingLarge),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildPopularSection(
    List<FeaturedBusiness> spots,
    ThemeData theme,
    double width,
    bool isTablet,
    EdgeInsets padding,
  ) {
    return [
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
                  Expanded(child: HomeSectionHeaderWidget(title: 'Popular Near You', subtitle: 'Top local favorites in your parish')),
                  if (spots.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        if (widget.onNavigateToExplore != null) {
                          widget.onNavigateToExplore!();
                        } else {
                          context.go('/explore');
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            'See all',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.specGold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.specGold),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (spots.isEmpty)
                const AppEmptyState(
                  message: 'No featured spots nearby right now',
                  icon: Icons.storefront_outlined,
                  padding: EdgeInsets.symmetric(vertical: 24),
                ),
            ],
          ),
        ),
      ),
      if (spots.isNotEmpty)
        if (isTablet)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacing),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: width > 1200 ? 4 : (width > 850 ? 3 : 2),
                mainAxisSpacing: _cardGap,
                crossAxisSpacing: _cardGap,
                mainAxisExtent: 290,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final spot = spots[index];
                return AnimatedEntrance(
                  delay: Duration(milliseconds: 80 + (index * 60)),
                  child: PopularCardWidget(spot: spot, onTap: () => context.push('/listing/${spot.id}')),
                );
              }, childCount: spots.length),
            ),
          )
        else
          SliverToBoxAdapter(
            child: SizedBox(
              height: 290,
              child: ListView.builder(
                controller: _popularScrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: padding.left, right: padding.right, bottom: 4),
                itemCount: spots.length,
                itemBuilder: (context, index) {
                  final spot = spots[index];
                  final cardWidth = (width - padding.left - padding.right - _cardGap * 2) * 0.72;
                  return Padding(
                    padding: EdgeInsets.only(right: _cardGap),
                    child: AnimatedEntrance(
                      delay: Duration(milliseconds: 80 + (index * 60)),
                      child: PopularCardWidget(
                        spot: spot,
                        onTap: () => context.push('/listing/${spot.id}'),
                        cardWidth: cardWidth,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
    ];
  }

  List<Widget> _buildStoriesSection(
    List<BlogPost> posts,
    Map<String, String> idToName,
    ThemeData theme,
    double width,
    EdgeInsets padding,
  ) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding.left, _sectionSpacingLarge, padding.right, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: HomeSectionHeaderWidget(
                      title: 'Local Stories',
                      subtitle: 'Journal entries from across Cajun country',
                    ),
                  ),
                  if (posts.isNotEmpty)
                    GestureDetector(
                      onTap: () => widget.onNavigateToNews?.call(),
                      child: Row(
                        children: [
                          Text(
                            'See all',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.specGold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.specGold),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (posts.isEmpty)
                const AppEmptyState(
                  message: 'No stories yet for these parishes',
                  icon: Icons.auto_stories_outlined,
                  padding: EdgeInsets.symmetric(vertical: 24),
                ),
            ],
          ),
        ),
      ),
      if (posts.isNotEmpty)
        SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = width - padding.left - padding.right;
              final cardWidth = (contentWidth * 0.85).clamp(280.0, 420.0);
              final cardHeight = cardWidth * 1.25;

              return SizedBox(
                height: cardHeight,
                child: ListView.builder(
                  controller: _blogScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(left: padding.left, right: padding.right),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final isFeatured = index == 0;

                    return Padding(
                      padding: EdgeInsets.only(right: index == posts.length - 1 ? 0 : _cardGap),
                      child: AnimatedEntrance(
                        delay: Duration(milliseconds: 100 + (index * 60)),
                        child: LatestPostCardWidget(
                          post: post,
                          parishLabel: _parishLabelForPost(post, idToName),
                          onTap: () => widget.onNavigateToNewsPost?.call(post.id),
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          featured: isFeatured,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
    ];
  }

  List<Widget> _buildCategoriesSection(
    List<BusinessCategory> cats,
    ThemeData theme,
    double width,
    bool isTablet,
    EdgeInsets padding,
  ) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding.left, _sectionSpacingLarge, padding.right, 0),
          child: HomeSectionHeaderWidget(title: 'Browse by category', subtitle: 'Explore by interest'),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: _sectionTitleBottom)),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 0),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: width > 1000 ? 5 : (width > 750 ? 4 : (width > 500 ? 3 : 2)),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 200,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final cat = cats[index];
            return AnimatedEntrance(
              delay: Duration(milliseconds: 120 + (index * 50)),
              child: CategoryCardWidget(
                category: cat,
                onTap: () {
                  if (widget.onSelectCategory != null) {
                    widget.onSelectCategory!(cat);
                  } else {
                    context.go('/explore?categoryId=${cat.id}');
                  }
                },
              ),
            );
          }, childCount: cats.length),
        ),
      ),
    ];
  }
}
