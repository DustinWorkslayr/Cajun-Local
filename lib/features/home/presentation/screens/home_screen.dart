import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/categories/presentation/screens/categories_screen.dart';
import 'package:cajun_local/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:cajun_local/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:cajun_local/features/local_events/presentation/screens/local_events_screen.dart';
import 'package:cajun_local/shared/widgets/animated_entrance.dart';
import 'package:cajun_local/shared/widgets/dismissible_alert_banner.dart';
import 'package:cajun_local/shared/widgets/parish_onboarding_dialog.dart';
import 'package:cajun_local/shared/widgets/app_empty_state.dart';
import 'package:cajun_local/features/profile/data/models/user_parish_preferences.dart';

// Widgets
import '../widgets/home_hero_widget.dart';
import '../widgets/home_quick_actions_widget.dart';
import '../widgets/home_section_header_widget.dart';
import '../widgets/popular_card_widget.dart';
import '../widgets/latest_post_card_widget.dart';
import '../widgets/category_card_widget.dart';
import '../widgets/upcoming_event_card_widget.dart';
import '../widgets/home_tablet_right_column_widget.dart';

// Providers
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    this.parishPrefsVersion = 0,
    this.openMenu,
    this.onSelectCategory,
    this.onNavigateToExplore,
    this.onNavigateToFavorites,
    this.onNavigateToDeals,
    this.onNavigateToNews,
    this.onNavigateToNewsPost,
    this.onOpenLocalEvents,
    this.onOpenChooseForMe,
  });

  final int parishPrefsVersion;
  final VoidCallback? openMenu;
  final void Function(MockCategory category)? onSelectCategory;
  final VoidCallback? onNavigateToExplore;
  final VoidCallback? onNavigateToFavorites;
  final VoidCallback? onNavigateToDeals;
  final VoidCallback? onNavigateToNews;
  final void Function(String postId)? onNavigateToNewsPost;
  final VoidCallback? onOpenLocalEvents;
  final VoidCallback? onOpenChooseForMe;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late final ScrollController _eventsScrollController;
  late final ScrollController _popularScrollController;
  late final ScrollController _blogScrollController;
  late final ScrollController _heroPreviewScrollController;

  static const double _paddingMobile = 20;
  static const double _paddingTablet = 44;
  static const double _sectionSpacing = 32;
  static const double _sectionSpacingLarge = 40;
  static const double _cardGap = 16;
  static const double _sectionTitleBottom = 12;

  @override
  void initState() {
    super.initState();
    _eventsScrollController = ScrollController();
    _popularScrollController = ScrollController();
    _blogScrollController = ScrollController();
    _heroPreviewScrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.parishPrefsVersion != oldWidget.parishPrefsVersion) {
      _refreshAll();
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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _eventsScrollController.dispose();
    _popularScrollController.dispose();
    _blogScrollController.dispose();
    _heroPreviewScrollController.dispose();
    super.dispose();
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
    final horizontalPad = isTablet ? _paddingTablet : _paddingMobile;
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
        child: CustomScrollView(
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
                    padding.left + 11.5,
                    8,
                    padding.right + 11.5,
                    isTablet ? _sectionSpacingLarge : _sectionSpacing,
                  ),
                  child: isTablet
                      ? Row(
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
                              child: featuredAsync.when(
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
                                  ).push(MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: spot.id))),
                                ),
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (_, _) => const SizedBox(),
                              ),
                            ),
                          ],
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
            prefNamesAsync.when(
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
                                final ids = await UserParishPreferences.getPreferredParishIds();
                                if (!context.mounted) return;
                                await showDialog<void>(
                                  context: context,
                                  builder: (ctx) => ParishOnboardingDialog(
                                    initialParishIds: ids,
                                    parishOnly: true,
                                    onComplete: (newIds) async {
                                      await UserParishPreferences.setPreferredParishIds(newIds);
                                      if (ctx.mounted) Navigator.of(ctx).pop();
                                      _refreshAll();
                                    },
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.specWhite,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.12)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 18, color: AppTheme.specGold),
                                    const SizedBox(width: 8),
                                    Text(
                                      'In your parish · ${names.join(', ')}',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: AppTheme.specNavy,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(child: SizedBox()),
              error: (_, _) => const SliverToBoxAdapter(child: SizedBox()),
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
                    isTablet: isTablet,
                    onDeals: widget.onNavigateToDeals,
                    onEvents: widget.onOpenLocalEvents,
                    onChooseForMe: widget.onOpenChooseForMe,
                  ),
                ),
              ),
            ),

            // --- Upcoming events ---
            eventsAsync.when(
              data: (events) => _buildEventsSection(events, theme, padding),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (_, _) => const SliverToBoxAdapter(child: SizedBox()),
            ),

            // --- Popular Near You ---
            featuredAsync.when(
              data: (spots) => _buildPopularSection(spots, theme, width, isTablet, isLargeTablet, padding),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (_, _) => const SliverToBoxAdapter(child: SizedBox()),
            ),

            // --- Local Stories ---
            postsAsync.when(
              data: (posts) {
                return parishesAsync.when(
                  data: (parishes) {
                    final idToName = {for (final p in parishes) p.id: p.name};
                    return _buildStoriesSection(posts, idToName, theme, width, padding);
                  },
                  loading: () => const SliverToBoxAdapter(child: SizedBox()),
                  error: (_, _) => _buildStoriesSection(posts, {}, theme, width, padding),
                );
              },
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (_, _) => const SliverToBoxAdapter(child: SizedBox()),
            ),

            // --- Categories ---
            categoriesAsync.when(
              data: (cats) => _buildCategoriesSection(cats, theme, isTablet, padding),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (_, _) => const SliverToBoxAdapter(child: SizedBox()),
            ),

            // --- Bottom spacing ---
            SliverToBoxAdapter(child: const SizedBox(height: _sectionSpacing + 8)),
            SliverToBoxAdapter(child: SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom)),
          ],
        ),
      ),
    );
  }

  // --- UI Section Builders ---

  Widget _buildEventsSection(List<(MockEvent, String)> events, ThemeData theme, EdgeInsets padding) {
    return SliverToBoxAdapter(
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
                          const SizedBox(width: 2),
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
                  height: 112,
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
              SizedBox(height: _sectionSpacingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularSection(
    List<MockSpot> spots,
    ThemeData theme,
    double width,
    bool isTablet,
    bool isLargeTablet,
    EdgeInsets padding,
  ) {
    return SliverMainAxisGroup(
      slivers: [
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
                  crossAxisCount: isLargeTablet ? 4 : 3,
                  mainAxisSpacing: _cardGap,
                  crossAxisSpacing: _cardGap,
                  childAspectRatio: isLargeTablet ? 1.85 : 1.75,
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
                height: 120,
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
      ],
    );
  }

  Widget _buildStoriesSection(
    List<BlogPost> posts,
    Map<String, String> idToName,
    ThemeData theme,
    double width,
    EdgeInsets padding,
  ) {
    return SliverMainAxisGroup(
      slivers: [
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
              height: 268,
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
      ],
    );
  }

  Widget _buildCategoriesSection(List<MockCategory> cats, ThemeData theme, bool isTablet, EdgeInsets padding) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding.left, _sectionSpacingLarge, padding.right, 0),
            child: HomeSectionHeaderWidget(
              title: 'Browse by category',
              titleStyle: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
            ),
          ),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: _sectionTitleBottom)),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 4 : 2,
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
      ],
    );
  }
}
