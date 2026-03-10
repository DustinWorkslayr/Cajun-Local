import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/core/data/repositories/blog_posts_repository.dart';
import 'package:cajun_local/core/data/repositories/parish_repository.dart';
import 'package:cajun_local/core/data/category_icons.dart';
import 'package:cajun_local/core/data/models/blog_post.dart';
import 'package:cajun_local/core/data/models/parish.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/core/preferences/user_parish_preferences.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/categories/presentation/screens/categories_screen.dart';
import 'package:cajun_local/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:cajun_local/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:cajun_local/features/local_events/presentation/screens/local_events_screen.dart';
import 'package:cajun_local/shared/widgets/animated_entrance.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/dismissible_alert_banner.dart';
import 'package:cajun_local/shared/widgets/parish_onboarding_dialog.dart';

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

  /// Incremented by MainShell when parish onboarding completes; home refetches when this changes.
  final int parishPrefsVersion;

  /// Called to open the app menu (hamburger). Provided by MainShell.
  final VoidCallback? openMenu;

  /// When user taps a category, switch to Explore tab with this category selected. Provided by MainShell.
  final void Function(MockCategory category)? onSelectCategory;

  /// When user taps "Explore" or "View All", switch to Explore tab. Provided by MainShell.
  final VoidCallback? onNavigateToExplore;

  /// When user taps "Favorites", switch to Favorites tab. Provided by MainShell.
  final VoidCallback? onNavigateToFavorites;

  /// Switch to Deals tab. Optional.
  final VoidCallback? onNavigateToDeals;

  /// Switch to News (blog list) tab. Optional.
  final VoidCallback? onNavigateToNews;

  /// Switch to News tab and open a specific post. Optional.
  final void Function(String postId)? onNavigateToNewsPost;

  /// Open Local Events screen. Optional.
  final VoidCallback? onOpenLocalEvents;

  /// Open Choose for Me screen. Optional.
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

  Future<(List<MockSpot>, List<MockCategory>)>? _homeFuture;
  Future<(List<BlogPost>, List<Parish>)>? _latestPostsFuture;
  Future<List<String>>? _parishNamesFuture;
  Future<List<(MockEvent, String)>>? _upcomingEventsFuture;

  static const double _cardRadius = 20;
  static const double _bannerMinHeight = 220;
  static const double _bannerMinHeightTablet = 280;
  static const double _paddingMobile = 20;
  static const double _paddingTablet = 44;
  static const double _sectionTitleBottom = 12;
  static const double _sectionSpacing = 32;
  static const double _sectionSpacingLarge = 40;
  static const double _cardGap = 16;

  @override
  void initState() {
    super.initState();
    _eventsScrollController = ScrollController();
    _popularScrollController = ScrollController();
    _blogScrollController = ScrollController();
    _heroPreviewScrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_homeFuture == null) {
      final ds = ref.read(listingDataSourceProvider);
      _homeFuture = Future.wait<dynamic>([
        ds.getFeaturedSpots(),
        ds.getCategories(),
      ]).then((r) => (r[0] as List<MockSpot>, r[1] as List<MockCategory>));
    }
    _latestPostsFuture ??= UserParishPreferences.getPreferredParishIds().then((ids) async {
      final posts = await ref
          .read(blogPostsRepositoryProvider)
          .listApproved(limit: 10, forParishIds: ids.isEmpty ? null : ids.toSet());
      final parishes = await ref.read(parishRepositoryProvider).listParishes();
      return (posts, parishes);
    });
    _parishNamesFuture ??= _loadParishNamesForDisplay();
    if (_upcomingEventsFuture == null) {
      final ds = ref.read(listingDataSourceProvider);
      if (ds.useBackend) {
        _upcomingEventsFuture = ds.getUpcomingEvents(limit: 6);
      }
    }
  }

  Future<List<String>> _loadParishNamesForDisplay() async {
    final ds = ref.read(listingDataSourceProvider);
    if (!ds.useBackend) return [];
    final ids = await UserParishPreferences.getPreferredParishIds();
    if (ids.isEmpty) return [];
    final parishes = await ds.getParishes();
    final byId = {for (final p in parishes) p.id: p.name};
    return ids.map((id) => byId[id] ?? id).where((n) => n.isNotEmpty).toList();
  }

  /// Pull-to-refresh: reset all home data and reload.
  Future<void> _refreshHome() async {
    if (!mounted) return;
    final ds = ref.read(listingDataSourceProvider);
    setState(() {
      _homeFuture = Future.wait<dynamic>([
        ds.getFeaturedSpots(),
        ds.getCategories(),
      ]).then((r) => (r[0] as List<MockSpot>, r[1] as List<MockCategory>));
      _latestPostsFuture = UserParishPreferences.getPreferredParishIds().then((ids) async {
        final posts = await ref
            .read(blogPostsRepositoryProvider)
            .listApproved(limit: 10, forParishIds: ids.isEmpty ? null : ids.toSet());
        final parishes = await ref.read(parishRepositoryProvider).listParishes();
        return (posts, parishes);
      });
      _parishNamesFuture = _loadParishNamesForDisplay();
      if (ds.useBackend) {
        _upcomingEventsFuture = ds.getUpcomingEvents(limit: 6);
      }
    });
    await _homeFuture;
    if (mounted) setState(() {});
  }

  static String _parishLabelForPost(BlogPost post, Map<String, String> idToName) {
    if (post.isAllParishes) return 'All parishes';
    return post.parishIds!.map((id) => idToName[id] ?? id).join(', ');
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.parishPrefsVersion != oldWidget.parishPrefsVersion) {
      _homeFuture = null;
      _latestPostsFuture = null;
      _parishNamesFuture = null;
      if (mounted) setState(() {});
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= AppTheme.breakpointTablet;
    final isLargeTablet = width >= AppTheme.breakpointLargeTablet;
    final horizontalPad = isTablet ? _paddingTablet : _paddingMobile;
    final padding = EdgeInsets.symmetric(horizontal: horizontalPad);
    if (_homeFuture == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _homeFuture != null) return;
        setState(() {
          final ds = ref.read(listingDataSourceProvider);
          _homeFuture = Future.wait<dynamic>([
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
                            final ds = ref.read(listingDataSourceProvider);
                            _homeFuture = Future.wait<dynamic>([
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
                return const Center(child: CircularProgressIndicator(color: AppTheme.specNavy));
              }
              final spots = snapshot.data?.$1 ?? <MockSpot>[];
              final categories = snapshot.data?.$2 ?? <MockCategory>[];
              return RefreshIndicator(
                onRefresh: _refreshHome,
                color: AppTheme.specNavy,
                child: CustomScrollView(
                  slivers: [
                    // ——— Notification banner (below topbar) ———
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(padding.left, 4, padding.right, 0),
                        child: DismissibleAlertBanner(horizontalPadding: padding, compact: true),
                      ),
                    ),
                    // ——— Hero ( + on tablet: Popular in your parish preview right column ) ———
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
                                      child: _HomeHero(
                                        isTablet: true,
                                        onExplore: () {
                                          if (widget.onNavigateToExplore != null) {
                                            widget.onNavigateToExplore!();
                                          } else {
                                            Navigator.of(
                                              context,
                                            ).push(MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()));
                                          }
                                        },
                                        onFavorites: () {
                                          if (widget.onNavigateToFavorites != null) {
                                            widget.onNavigateToFavorites!();
                                          } else {
                                            Navigator.of(
                                              context,
                                            ).push(MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()));
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: _cardGap),
                                    Expanded(
                                      child: _HomeTabletRightColumn(
                                        spots: spots,
                                        previewScrollController: _heroPreviewScrollController,
                                        onExplore: () {
                                          if (widget.onNavigateToExplore != null) {
                                            widget.onNavigateToExplore!();
                                          } else {
                                            Navigator.of(
                                              context,
                                            ).push(MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()));
                                          }
                                        },
                                        onTapSpot: (spot) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => ListingDetailScreen(listingId: spot.id),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : _HomeHero(
                                  isTablet: false,
                                  onExplore: () {
                                    if (widget.onNavigateToExplore != null) {
                                      widget.onNavigateToExplore!();
                                    } else {
                                      Navigator.of(
                                        context,
                                      ).push(MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()));
                                    }
                                  },
                                  onFavorites: () {
                                    if (widget.onNavigateToFavorites != null) {
                                      widget.onNavigateToFavorites!();
                                    } else {
                                      Navigator.of(
                                        context,
                                      ).push(MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()));
                                    }
                                  },
                                ),
                        ),
                      ),
                    ),

                    // ——— Your area (parish chip, tappable) ———
                    SliverToBoxAdapter(
                      child: FutureBuilder<List<String>>(
                        future: _parishNamesFuture,
                        builder: (context, snapshot) {
                          final names = snapshot.data;
                          if (names == null || names.isEmpty) return const SizedBox.shrink();
                          final label = names.length == 1
                              ? names.single
                              : names.take(3).join(', ') + (names.length > 3 ? ' ···' : '');
                          return AnimatedEntrance(
                            delay: const Duration(milliseconds: 40),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 12),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
                                            if (mounted) {
                                              setState(() {
                                                _parishNamesFuture = _loadParishNamesForDisplay();
                                                _homeFuture = null;
                                              });
                                            }
                                          },
                                        ),
                                      );
                                    });
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
                                          'In your parish · $label',
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
                          );
                        },
                      ),
                    ),

                    // ——— Search section ———
                    SliverToBoxAdapter(
                      child: AnimatedEntrance(
                        delay: const Duration(milliseconds: 60),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacingLarge),
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
                                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.specNavy, size: 24),
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
                          padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacingLarge),
                          child: _QuickActions(
                            isTablet: isTablet,
                            onDeals: widget.onNavigateToDeals,
                            onEvents: widget.onOpenLocalEvents,
                            onChooseForMe: widget.onOpenChooseForMe,
                          ),
                        ),
                      ),
                    ),

                    // ——— Upcoming events strip ———
                    SliverToBoxAdapter(
                      child: FutureBuilder<List<(MockEvent, String)>>(
                        future: _upcomingEventsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                            return Padding(
                              padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacing),
                              child: SizedBox(
                                height: 100,
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.specNavy.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          final list = snapshot.data ?? [];
                          if (list.isEmpty) return const SizedBox.shrink();
                          return AnimatedEntrance(
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
                                      _SectionHeader(
                                        title: 'This week in Acadiana',
                                        titleStyle: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.specNavy,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (widget.onOpenLocalEvents != null) {
                                            widget.onOpenLocalEvents!();
                                          } else {
                                            Navigator.of(
                                              context,
                                            ).push(MaterialPageRoute<void>(builder: (_) => const LocalEventsScreen()));
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.specGold,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'See all',
                                              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(width: 2),
                                            Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.specGold),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 112,
                                    child: ListView.builder(
                                      controller: _eventsScrollController,
                                      scrollDirection: Axis.horizontal,
                                      padding: EdgeInsets.only(bottom: 4),
                                      clipBehavior: Clip.none,
                                      itemCount: list.length,
                                      itemBuilder: (context, index) {
                                        final (event, businessName) = list[index];
                                        return Padding(
                                          padding: EdgeInsets.only(right: _cardGap),
                                          child: _UpcomingEventCard(
                                            event: event,
                                            businessName: businessName,
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) => ListingDetailScreen(listingId: event.listingId),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: _sectionSpacingLarge),
                                ],
                              ),
                            ),
                          );
                        },
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
                                _SectionHeader(
                                  title: 'Popular Near You',
                                  subtitle: 'Top spots in your parish',
                                  titleStyle: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.specNavy,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    if (widget.onNavigateToExplore != null) {
                                      widget.onNavigateToExplore!();
                                    } else {
                                      Navigator.of(
                                        context,
                                      ).push(MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()));
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
                                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
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
                                crossAxisCount: isLargeTablet ? 4 : 3,
                                mainAxisSpacing: _cardGap,
                                crossAxisSpacing: _cardGap,
                                childAspectRatio: isLargeTablet ? 1.85 : 1.75,
                              ),
                              delegate: SliverChildBuilderDelegate((context, index) {
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
                              }, childCount: spots.length),
                            ),
                          )
                        : SliverToBoxAdapter(
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
                        padding: EdgeInsets.fromLTRB(padding.left, _sectionSpacingLarge, padding.right, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _SectionHeader(
                                  title: 'Local Stories',
                                  subtitle: 'Stories from Cajun country',
                                  titleStyle: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.specNavy,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    widget.onNavigateToNews?.call();
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
                                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
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
                      child: FutureBuilder<(List<BlogPost>, List<Parish>)>(
                        future: _latestPostsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                            return Padding(
                              padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacing),
                              child: SizedBox(
                                height: 200,
                                child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                              ),
                            );
                          }
                          final posts = snapshot.data?.$1 ?? [];
                          final parishes = snapshot.data?.$2 ?? [];
                          final idToName = {for (final p in parishes) p.id: p.name};
                          if (posts.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacing),
                              child: Container(
                                height: 160,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.specWhite,
                                  borderRadius: BorderRadius.circular(_cardRadius),
                                  border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.12)),
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
                            final largeTablet = MediaQuery.sizeOf(context).width >= AppTheme.breakpointLargeTablet;
                            return Padding(
                              padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, _sectionSpacing),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: largeTablet ? 4 : 2,
                                  mainAxisSpacing: _cardGap,
                                  crossAxisSpacing: _cardGap,
                                  childAspectRatio: largeTablet ? 0.75 : 1.15,
                                ),
                                itemCount: posts.length,
                                itemBuilder: (context, index) {
                                  final post = posts[index];
                                  return AnimatedEntrance(
                                    delay: Duration(milliseconds: 100 + (index * 60)),
                                    child: _LatestPostCard(
                                      post: post,
                                      parishLabel: _parishLabelForPost(post, idToName),
                                      onTap: () {
                                        widget.onNavigateToNewsPost?.call(post.id);
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                          // Mobile: horizontal scroll for compact, swipeable showcase
                          final blogCardWidth = (width - padding.left - padding.right - _cardGap * 2) * 0.78;
                          return Padding(
                            padding: EdgeInsets.only(bottom: _sectionSpacing),
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
                                  return Padding(
                                    padding: EdgeInsets.only(right: _cardGap),
                                    child: AnimatedEntrance(
                                      delay: Duration(milliseconds: 100 + (index * 60)),
                                      child: _LatestPostCard(
                                        post: post,
                                        parishLabel: _parishLabelForPost(post, idToName),
                                        onTap: () {
                                          widget.onNavigateToNewsPost?.call(post.id);
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
                        padding: EdgeInsets.fromLTRB(padding.left, _sectionSpacingLarge, padding.right, 0),
                        child: _SectionHeader(
                          title: 'Browse by category',
                          titleStyle: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.specNavy,
                          ),
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
                        delegate: SliverChildBuilderDelegate((context, index) {
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
                        }, childCount: categories.length),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: _sectionSpacing + 8)),
                    // Extra bottom padding so content clears nav and safe area (avoids bottom overflow).
                    SliverToBoxAdapter(child: SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Reusable section title with optional subtitle and gold underline.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, required this.titleStyle});

  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;

  static const double _barHeight = 3;
  static const double _barWidth = 40;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: titleStyle),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.65)),
          ),
        ],
        const SizedBox(height: 6),
        Container(
          height: _barHeight,
          width: _barWidth,
          decoration: BoxDecoration(
            color: AppTheme.specGold.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.isTablet, required this.onExplore, required this.onFavorites});

  final bool isTablet;
  final VoidCallback onExplore;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bannerHeight = isTablet ? _HomeScreenState._bannerMinHeightTablet : _HomeScreenState._bannerMinHeight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_HomeScreenState._cardRadius),
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
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(_HomeScreenState._cardRadius)),
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
                    Row(
                      children: [
                        AppSecondaryButton(onPressed: onExplore, child: const Text('Explore')),
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

/// Tablet-only: right column above the fold — "Popular in your parish" with first two spots.
class _HomeTabletRightColumn extends StatelessWidget {
  const _HomeTabletRightColumn({
    required this.spots,
    required this.onExplore,
    required this.onTapSpot,
    this.previewScrollController,
  });

  final List<MockSpot> spots;
  final VoidCallback onExplore;
  final void Function(MockSpot spot) onTapSpot;
  final ScrollController? previewScrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewSpots = spots.take(2).toList();
    if (previewSpots.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.specWhite,
          borderRadius: BorderRadius.circular(_HomeScreenState._cardRadius),
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
        borderRadius: BorderRadius.circular(_HomeScreenState._cardRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_HomeScreenState._cardRadius),
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
                  _SectionHeader(
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
                    child: _PopularCard(spot: spot, onTap: () => onTapSpot(spot)),
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({this.isTablet = false, this.onDeals, this.onEvents, this.onChooseForMe});

  final bool isTablet;
  final VoidCallback? onDeals;
  final VoidCallback? onEvents;
  final VoidCallback? onChooseForMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);

    if (isTablet) {
      Widget actionCard(String label, String description, IconData icon, VoidCallback? onTap) {
        final enabled = onTap != null;
        return Expanded(
          child: Material(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(_HomeScreenState._cardRadius),
            elevation: 0,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(_HomeScreenState._cardRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_HomeScreenState._cardRadius),
                  border: Border.all(
                    color: enabled ? AppTheme.specGold.withValues(alpha: 0.4) : nav.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 28, color: enabled ? AppTheme.specGold : sub),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: enabled ? nav : sub,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(color: nav.withValues(alpha: 0.65), height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return Row(
        children: [
          actionCard('Deals', 'Save at local spots', Icons.local_offer_rounded, onDeals),
          const SizedBox(width: _HomeScreenState._cardGap),
          actionCard('Events', 'What\'s happening in Acadiana', Icons.event_rounded, onEvents),
          const SizedBox(width: _HomeScreenState._cardGap),
          actionCard('Choose for Me', 'Get a random pick', Icons.shuffle_rounded, onChooseForMe),
        ],
      );
    }

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
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
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

/// Compact card for the home "Upcoming" events strip. Shows date, title, venue.
class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({required this.event, required this.businessName, required this.onTap});

  final MockEvent event;
  final String businessName;
  final VoidCallback onTap;

  static const _cardWidth = 200.0;
  static const _radius = 14.0;

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final local = d.isUtc ? d.toLocal() : d;
    final eventDay = DateTime(local.year, local.month, local.day);
    if (eventDay == today) return 'Today';
    final tomorrow = today.add(const Duration(days: 1));
    if (eventDay == tomorrow) return 'Tomorrow';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final w = weekdays[eventDay.weekday - 1];
    final m = months[eventDay.month - 1];
    return '$w, $m ${eventDay.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = _formatDate(event.eventDate);

    const double cardHeight = 112.0;
    return SizedBox(
      width: _cardWidth,
      height: cardHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.specGold,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    event.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.specNavy,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  businessName,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.65)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  const _PopularCard({required this.spot, required this.onTap, this.cardWidth});

  final MockSpot spot;
  final VoidCallback onTap;

  /// When set (e.g. horizontal scroll), use this width; otherwise full width for grid.
  final double? cardWidth;

  static const double _logoSize = 72;
  static const double _radius = 18.0;

  /// Show subtitle only when it adds info (not same as business name).
  static bool _showSubtitle(String name, String subtitle) {
    if (subtitle.trim().isEmpty) return false;
    return subtitle.trim().toLowerCase() != name.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoUrl = spot.logoUrl;
    final hasImage = logoUrl != null && logoUrl.trim().isNotEmpty;
    final rating = spot.rating;
    final showRating = rating != null;
    final subcatOrCategory = spot.subcategoryName ?? spot.categoryName;
    final showSubtitle = _showSubtitle(spot.name, spot.subtitle);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo on the side (left)
                SizedBox(
                  width: _logoSize,
                  height: _logoSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.specOffWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.06)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.contain,
                              memCacheWidth: 200,
                              memCacheHeight: 200,
                              placeholder: (_, _) => _placeholderContent(),
                              errorWidget: (_, _, _) => _placeholderContent(),
                            )
                          : _placeholderContent(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                      if (showSubtitle) ...[
                        const SizedBox(height: 2),
                        Text(
                          spot.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.7)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (showRating || subcatOrCategory != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (showRating) ...[
                              Icon(Icons.star_rounded, size: 16, color: AppTheme.specGold),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.specNavy,
                                ),
                              ),
                            ],
                            if (showRating && subcatOrCategory != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppTheme.specNavy.withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            if (subcatOrCategory != null)
                              Expanded(
                                child: Text(
                                  subcatOrCategory,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppTheme.specNavy.withValues(alpha: 0.65),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.specGold),
                          const SizedBox(width: 6),
                          Text(
                            'View listing',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.specGold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderContent() {
    return Center(child: Icon(Icons.store_rounded, size: 44, color: AppTheme.specNavy.withValues(alpha: 0.25)));
  }
}

class _LatestPostCard extends StatelessWidget {
  const _LatestPostCard({required this.post, required this.parishLabel, required this.onTap, this.cardWidth});

  final BlogPost post;
  final String parishLabel;
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
    final coverUrl = post.coverImageUrl;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
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
                      height: 140,
                      width: double.infinity,
                      child: hasCover
                          ? CachedNetworkImage(
                              imageUrl: coverUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              memCacheWidth: 400,
                              memCacheHeight: 200,
                              placeholder: (_, progress) => _placeholderCover(),
                              errorWidget: (_, error, stackTrace) => _placeholderCover(),
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
                            colors: [AppTheme.specGold, AppTheme.specGold.withValues(alpha: 0.6)],
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
                    if (parishLabel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          parishLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specNavy.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.specNavy.withValues(alpha: 0.12), AppTheme.specGold.withValues(alpha: 0.15)],
        ),
      ),
      child: Center(child: Icon(Icons.article_rounded, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.22))),
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(getCategoryIconData(category.iconName), size: 40, color: AppTheme.specNavy),
              const SizedBox(height: 14),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
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
