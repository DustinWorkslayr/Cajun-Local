import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/home/presentation/providers/home_providers.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/animated_entrance.dart';
import 'package:cajun_local/shared/widgets/dismissible_alert_banner.dart';
import 'package:cajun_local/features/categories/presentation/screens/categories_screen.dart';
import 'package:cajun_local/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:cajun_local/features/local_events/presentation/screens/local_events_screen.dart';
import 'package:cajun_local/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:cajun_local/shared/widgets/parish_onboarding_dialog.dart';
import 'package:cajun_local/shared/widgets/app_empty_state.dart';
import 'package:cajun_local/core/theme/app_layout.dart';

// Widgets
import '../widgets/home_hero_widget.dart';
import '../widgets/home_quick_actions_widget.dart';
import '../widgets/home_section_header_widget.dart';
import '../widgets/home_tablet_right_column_widget.dart';
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
  final void Function(MockCategory)? onSelectCategory;

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
    if (!prefs.hasValue || prefs.value!.isEmpty) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (_) => ParishOnboardingDialog(
            onComplete: (_) {
              _refreshAll();
            },
          ),
        );
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => CategoriesScreen(initialSearch: query.isEmpty ? null : query)));
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
    final isLargeTablet = width >= AppTheme.breakpointLargeTablet;
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
      child: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        color: AppTheme.specNavy,
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

              // --- Hero section ---
              SliverToBoxAdapter(
                child: AnimatedEntrance(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      padding.left,
                      8,
                      padding.right,
                      isTablet ? _sectionSpacingLarge : _sectionSpacing,
                    ),
                    child: isTablet
                        ? SizedBox(
                            height: 280,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: HomeHeroWidget(
                                    isTablet: true,
                                    onExplore: () {
                                      if (widget.onNavigateToExplore != null) {
                                        widget.onNavigateToExplore!();
                                      } else {
                                        Navigator.of(
                                          context,
                                        ).push(MaterialPageRoute(builder: (_) => const CategoriesScreen()));
                                      }
                                    },
                                    onFavorites: () {
                                      if (widget.onNavigateToFavorites != null) {
                                        widget.onNavigateToFavorites!();
                                      } else {
                                        Navigator.of(
                                          context,
                                        ).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: _cardGap),
                                Expanded(
                                  child: featuredAsync.maybeWhen(
                                    data: (spots) => HomeTabletRightColumnWidget(
                                      spots: spots,
                                      previewScrollController: _heroPreviewScrollController,
                                      onExplore: () {
                                        if (widget.onNavigateToExplore != null) {
                                          widget.onNavigateToExplore!();
                                        } else {
                                          Navigator.of(
                                            context,
                                          ).push(MaterialPageRoute(builder: (_) => const CategoriesScreen()));
                                        }
                                      },
                                      onTapSpot: (spot) => Navigator.of(
                                        context,
                                      ).push(
                                        MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: spot.id)),
                                      ),
                                    ),
                                    orElse: () => const Center(child: CircularProgressIndicator()),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : HomeHeroWidget(
                            isTablet: false,
                            onExplore: () {
                              if (widget.onNavigateToExplore != null) {
                                widget.onNavigateToExplore!();
                              } else {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoriesScreen()));
                              }
                            },
                            onFavorites: () {
                              if (widget.onNavigateToFavorites != null) {
                                widget.onNavigateToFavorites!();
                              } else {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                              }
                            },
                          ),
                  ),
                ),
              ),

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
                                onTap: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => ParishOnboardingDialog(
                                    onComplete: (_) {
                                      _refreshAll();
                                    },
                                  ),
                                ),
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

              // --- Search bar ---
              SliverToBoxAdapter(
                child: AnimatedEntrance(
                  delay: const Duration(milliseconds: 60),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacingLarge),
                    child: Material(
                      color: AppTheme.specWhite,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
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
                            hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.specNavy, size: 24),
                            suffixIcon: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _searchController,
                              builder: (context, value, _) {
                                if (value.text.isNotEmpty) {
                                  return IconButton(
                                    icon: Icon(Icons.clear_rounded, color: AppTheme.specNavy, size: 22),
                                    onPressed: () => _searchController.clear(),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- Quick actions ---
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

              // --- Sections ---

              // Upcoming events
              ...eventsAsync.maybeWhen(
                data: (events) => _buildEventsSection(events, theme, padding),
                loading: () => [const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))],
                orElse: () => [const SliverToBoxAdapter(child: SizedBox())],
              ),

              // Popular Near You
              ...featuredAsync.maybeWhen(
                data: (spots) => _buildPopularSection(spots, theme, width, isTablet, isLargeTablet, padding),
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

              // Categories
              ...categoriesAsync.maybeWhen(
                data: (cats) => _buildCategoriesSection(cats, theme, width, isTablet, padding),
                loading: () => [const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))],
                orElse: () => [const SliverToBoxAdapter(child: SizedBox())],
              ),

              // Bottom spacing
              SliverToBoxAdapter(child: const SizedBox(height: _sectionSpacing + 8)),
              SliverToBoxAdapter(child: SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom)),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Section Builders ---

  List<Widget> _buildEventsSection(List<(MockEvent, String)> events, ThemeData theme, EdgeInsets padding) {
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
                    HomeSectionHeaderWidget(
                      title: 'This week in Acadiana',
                      titleStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                    ),
                    if (events.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          if (widget.onOpenLocalEvents != null) {
                            widget.onOpenLocalEvents!();
                          } else {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocalEventsScreen()));
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: AppTheme.specGold),
                        child: Row(
                          children: [
                            Text(
                              'See all',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.specNavy,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
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
                  SizedBox(
                    height: 124,
                    child: ListView.builder(
                      controller: _eventsScrollController,
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final (event, businessName) = events[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: _cardGap),
                          child: UpcomingEventCardWidget(
                            event: event,
                            businessName: businessName,
                            onTap: () => Navigator.of(
                              context,
                            ).push(MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: event.listingId))),
                          ),
                        );
                      },
                    ),
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
    List<MockSpot> spots,
    ThemeData theme,
    double width,
    bool isTablet,
    bool isLargeTablet,
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
                  HomeSectionHeaderWidget(
                    title: 'Popular Near You',
                    subtitle: 'Top spots in your parish',
                    titleStyle: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.specNavy,
                    ),
                  ),
                  if (spots.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        if (widget.onNavigateToExplore != null) {
                          widget.onNavigateToExplore!();
                        } else {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoriesScreen()));
                        }
                      },
                      style: TextButton.styleFrom(foregroundColor: AppTheme.specGold),
                      child: Row(
                        children: [
                          Text('See all', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
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
                childAspectRatio: width > 1200 ? 1.85 : 1.75,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final spot = spots[index];
                return AnimatedEntrance(
                  delay: Duration(milliseconds: 80 + (index * 60)),
                  child: PopularCardWidget(
                    spot: spot,
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: spot.id))),
                  ),
                );
              }, childCount: spots.length),
            ),
          )
        else
          SliverToBoxAdapter(
            child: SizedBox(
              height: 132,
              child: ListView.builder(
                controller: _popularScrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: padding.left, right: padding.right, bottom: 4),
                clipBehavior: Clip.none,
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
                        onTap: () => Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: spot.id))),
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
                  HomeSectionHeaderWidget(
                    title: 'Local Stories',
                    subtitle: 'Stories from Cajun country',
                    titleStyle: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.specNavy,
                    ),
                  ),
                  if (posts.isNotEmpty)
                    TextButton(
                      onPressed: () => widget.onNavigateToNews?.call(),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.specGold),
                      child: Row(
                        children: [
                          Text('See all', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
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
          child: SizedBox(
            height: 300,
            child: ListView.builder(
              controller: _blogScrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: padding.left, right: padding.right, bottom: 4),
              clipBehavior: Clip.none,
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final cardWidth = (width - padding.left - padding.right - _cardGap * 2) * 0.78;
                return Padding(
                  padding: EdgeInsets.only(right: _cardGap),
                  child: AnimatedEntrance(
                    delay: Duration(milliseconds: 100 + (index * 60)),
                    child: LatestPostCardWidget(
                      post: post,
                      parishLabel: _parishLabelForPost(post, idToName),
                      onTap: () => widget.onNavigateToNewsPost?.call(post.id),
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

  List<Widget> _buildCategoriesSection(List<MockCategory> cats, ThemeData theme, double width, bool isTablet, EdgeInsets padding) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding.left, _sectionSpacingLarge, padding.right, 0),
          child: HomeSectionHeaderWidget(
            title: 'Browse by category',
            titleStyle: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
          ),
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
            childAspectRatio: isTablet ? 1.1 : 1.25,
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
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => CategoriesScreen(initialCategoryId: cat.id)));
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
