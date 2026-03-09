import 'dart:async';
import 'dart:math' show cos, Random, sin;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/listing_data_source.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/models/amenity.dart';
import 'package:my_app/core/data/models/category_banner.dart';
import 'package:my_app/core/data/repositories/amenities_repository.dart';
import 'package:my_app/core/data/repositories/business_ads_repository.dart';
import 'package:my_app/core/data/repositories/business_subscriptions_repository.dart';
import 'package:my_app/core/data/repositories/category_banners_repository.dart';
import 'package:my_app/core/favorites/favorites_scope.dart';
import 'package:my_app/core/subscription/resolved_permissions.dart';
import 'package:my_app/core/revenuecat/present_subscription_paywall.dart';
import 'package:my_app/core/preferences/user_parish_preferences.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/core/subscription/business_tier_service.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/animated_entrance.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, this.initialSearch, this.initialCategoryId});

  /// When opening from home search, pre-fill search query.
  final String? initialSearch;

  /// When opening from home category tap, pre-select this category (Explore shows with this filter).
  final String? initialCategoryId;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

/// Page size for server-side "load more" on Explore.
const int _kExplorePageSize = 50;

class _CategoriesScreenState extends State<CategoriesScreen> with TickerProviderStateMixin {
  late ListingFilters _filters;
  Future<(int, List<MockCategory>, List<MockParish>)>? _filterPanelDataFuture;
  late TabController _listMapTabController;
  late TextEditingController _searchController;
  Timer? _searchDebounce;
  /// Initial page load; then "load more" appends pages.
  Future<void>? _initialLoadFuture;
  /// Cached list from backend (pages appended on load more); filters applied in memory.
  List<MockListing>? _fullListCache;
  int _nextOffset = 0;
  bool _hasMoreFromServer = true;
  bool _loadingMore = false;
  Map<String, String> _lastTierMap = const {};
  Set<String> _lastSponsoredIds = const {};
  /// Lazy-loaded when user first applies deal-only or amenity filter.
  Set<String>? _dealListingIds;
  Set<String>? _cachedAmenityBusinessIds;
  Set<String> _cachedAmenityIds = const {};
  /// Result of in-memory filter + partition/shuffle; shown without reload.
  List<MockListing>? _lastFilteredList;
  /// When true, we're fetching deal or amenity sets for the first time (show previous list).
  bool _loadingAuxiliaryFilters = false;

  @override
  void initState() {
    super.initState();
    _filters = ListingFilters(
      searchQuery: widget.initialSearch ?? '',
      categoryId: widget.initialCategoryId,
    );
    _searchController = TextEditingController(text: widget.initialSearch ?? '');
    _listMapTabController = TabController(length: 2, vsync: this);
    // Apply user's saved parish preferences when Explore loads (no refetch; filters applied in memory).
    UserParishPreferences.getPreferredParishIds().then((ids) {
      if (!mounted) return;
      setState(() {
        _filters = _filters.copyWith(parishIds: ids);
        _applyFiltersFromCache();
      });
    });
  }

  @override
  void didUpdateWidget(CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId) {
      setState(() {
        _filters = _filters.copyWith(categoryId: widget.initialCategoryId);
        _applyFiltersFromCache();
      });
    }
    if (widget.initialSearch != oldWidget.initialSearch &&
        widget.initialSearch != _searchController.text) {
      _searchController.text = widget.initialSearch ?? '';
      setState(() {
        _filters = _filters.copyWith(searchQuery: widget.initialSearch ?? '');
        _applyFiltersFromCache();
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _listMapTabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim();
    _searchDebounce?.cancel();
    if (trimmed.isEmpty) {
      setState(() {
        _filters = _filters.copyWith(searchQuery: '');
        _applyFiltersFromCache();
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final current = _searchController.text.trim();
      setState(() {
        _filters = _filters.copyWith(searchQuery: current);
        _applyFiltersFromCache();
      });
    });
  }

  Future<List<CategoryBanner>>? _approvedBannersFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ds = AppDataScope.of(context).dataSource;
    if (_fullListCache != null && !_loadingAuxiliaryFilters && ds.useBackend) {
      _maybeLoadAuxiliaryFilters(ds);
    }
    _filterPanelDataFuture ??= Future.wait([
        ds.getCategories(),
        ds.getParishes(),
      ]).then((results) {
        final categories = results[0] as List<MockCategory>;
        final parishes = results[1] as List<MockParish>;
        final totalCount = categories.fold<int>(0, (s, c) => s + c.count);
        return (totalCount, categories, parishes);
      });
    if (_initialLoadFuture == null && ds.useBackend) {
      _initialLoadFuture = _performInitialLoad(ds);
    }
    _approvedBannersFuture ??= CategoryBannersRepository().listApproved();
  }

  bool _openNowOnly = false;

  void _openFilterSheet() async {
    final data = await _filterPanelDataFuture;
    if (!mounted) return;
    final categories = data?.$2 ?? [];
    final parishes = data?.$3 ?? [];
    final totalCount = data?.$1 ?? 0;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExploreFilterBottomSheet(
        initialFilters: _filters,
        initialOpenNowOnly: _openNowOnly,
        categories: categories,
        parishes: parishes,
        totalCount: totalCount,
        onApply: (filters, openNowOnly) {
          UserParishPreferences.setPreferredParishIds(filters.parishIds);
          final ds = AppDataScope.of(context).dataSource;
          final categoryChanged = filters.categoryId != _filters.categoryId;
          setState(() {
            _filters = filters;
            _searchController.text = filters.searchQuery;
            _openNowOnly = openNowOnly;
            if (categoryChanged) {
              _fullListCache = null;
              _nextOffset = 0;
              _hasMoreFromServer = true;
              _initialLoadFuture = _performInitialLoad(ds);
            } else {
              _applyFiltersFromCache();
            }
          });
          Navigator.of(ctx).pop();
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  bool _isFiltered() {
    return _filters.parishIds.isNotEmpty ||
        _filters.categoryId != null ||
        _filters.subcategoryIds.isNotEmpty;
  }

  /// Partition into sponsored, Local Partners, rest; shuffle each; order per user rules.
  List<MockListing> _partitionAndShuffle(
    List<MockListing> list,
    Map<String, String> tierMap,
    Set<String> sponsoredIds,
  ) {
    final isFiltered = _isFiltered();
    final rnd = Random();
    final sponsored = list.where((l) => sponsoredIds.contains(l.id)).toList()..shuffle(rnd);
    final partners = list
        .where((l) =>
            !sponsoredIds.contains(l.id) &&
            BusinessTierService.fromPlanTier(tierMap[l.id]) == BusinessTier.localPartner)
        .toList()
      ..shuffle(rnd);
    final rest = list
        .where((l) =>
            !sponsoredIds.contains(l.id) &&
            BusinessTierService.fromPlanTier(tierMap[l.id]) != BusinessTier.localPartner)
        .toList()
      ..shuffle(rnd);
    if (isFiltered) {
      return [...sponsored, ...partners, ...rest];
    }
    return [...partners, ...rest];
  }

  /// Load first page; tiers and sponsored IDs. "Load more" appends via [_loadMoreListings].
  Future<void> _performInitialLoad(ListingDataSource dataSource) async {
    if (!dataSource.useBackend) return;
    final page = await dataSource.getListingsPage(
      limit: _kExplorePageSize,
      offset: 0,
      categoryId: _filters.categoryId,
    );
    if (!mounted) return;
    final list = page.list;
    if (list.isEmpty) {
      setState(() {
        _fullListCache = [];
        _nextOffset = 0;
        _hasMoreFromServer = false;
        _lastTierMap = {};
        _lastSponsoredIds = {};
        _lastFilteredList = [];
      });
      return;
    }
    final ids = list.map((l) => l.id).toList();
    final tierMap = dataSource.useBackend
        ? await BusinessSubscriptionsRepository().getActivePlanTiersForBusinesses(ids)
        : <String, String>{};
    final sponsoredIds = dataSource.useBackend
        ? await BusinessAdsRepository().getActiveSponsoredBusinessIdsForExplore()
        : <String>{};
    if (!mounted) return;
    setState(() {
      _fullListCache = list;
      _nextOffset = list.length;
      _hasMoreFromServer = page.hasMore;
      _lastTierMap = tierMap;
      _lastSponsoredIds = sponsoredIds;
      _applyFiltersFromCache();
    });
  }

  /// Append next page from server (Explore "load more").
  Future<void> _loadMoreListings(ListingDataSource dataSource) async {
    if (_loadingMore || !_hasMoreFromServer || _fullListCache == null) return;
    setState(() => _loadingMore = true);
    final page = await dataSource.getListingsPage(
      limit: _kExplorePageSize,
      offset: _nextOffset,
      categoryId: _filters.categoryId,
    );
    if (!mounted) return;
    final existingIds = _fullListCache!.map((l) => l.id).toSet();
    final newList = page.list.where((l) => !existingIds.contains(l.id)).toList();
    final ids = newList.map((l) => l.id).toList();
    Map<String, String> newTiers = {};
    if (ids.isNotEmpty && dataSource.useBackend) {
      newTiers = await BusinessSubscriptionsRepository().getActivePlanTiersForBusinesses(ids);
    }
    if (!mounted) return;
    setState(() {
      _fullListCache = [..._fullListCache!, ...newList];
      _nextOffset += page.list.length;
      _hasMoreFromServer = page.hasMore;
      _loadingMore = false;
      if (newTiers.isNotEmpty) {
        _lastTierMap = {..._lastTierMap, ...newTiers};
      }
      _applyFiltersFromCache();
    });
  }

  /// Apply current filters to cached list in memory (no network). Instant.
  void _applyFiltersFromCache() {
    if (_fullListCache == null) return;
    final amenitySet = _filters.amenityIds.isNotEmpty ? _cachedAmenityBusinessIds : null;
    final dealSet = _filters.dealOnly ? _dealListingIds : null;
    final filtered = ListingDataSource.filterListingsInMemory(
      _fullListCache!,
      _filters,
      openNowOnly: _openNowOnly,
      businessIdsWithAnyAmenity: amenitySet,
      listingIdsWithDeals: dealSet,
    );
    _lastFilteredList = _partitionAndShuffle(filtered, _lastTierMap, _lastSponsoredIds);
  }

  /// Ensure deal listing IDs are loaded when user first applies deal-only filter.
  Future<void> _ensureDealListingIds(ListingDataSource dataSource) async {
    if (_dealListingIds != null || !dataSource.useBackend) return;
    final deals = await dataSource.getActiveDeals();
    if (!mounted) return;
    setState(() {
      _dealListingIds = deals.map((d) => d.listingId).toSet();
      _loadingAuxiliaryFilters = false;
      _applyFiltersFromCache();
    });
  }

  /// Ensure amenity business IDs are loaded when user first applies amenity filter.
  Future<void> _ensureAmenityBusinessIds(ListingDataSource dataSource) async {
    if (_filters.amenityIds.isEmpty) return;
    final key = _filters.amenityIds;
    if (_setEquals(key, _cachedAmenityIds)) return;
    final ids = await AmenitiesRepository().getBusinessIdsWithAnyAmenity(key);
    if (!mounted) return;
    setState(() {
      _cachedAmenityIds = Set<String>.from(key);
      _cachedAmenityBusinessIds = ids;
      _loadingAuxiliaryFilters = false;
      _applyFiltersFromCache();
    });
  }

  static bool _setEquals<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.every((x) => b.contains(x));

  void _maybeLoadAuxiliaryFilters(ListingDataSource dataSource) {
    if (!dataSource.useBackend || _loadingAuxiliaryFilters || _fullListCache == null) return;
    if (_filters.dealOnly && _dealListingIds == null) {
      setState(() => _loadingAuxiliaryFilters = true);
      _ensureDealListingIds(dataSource);
    } else if (_filters.amenityIds.isNotEmpty &&
        !_setEquals(_filters.amenityIds, _cachedAmenityIds)) {
      setState(() => _loadingAuxiliaryFilters = true);
      _ensureAmenityBusinessIds(dataSource);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataSource = AppDataScope.of(context).dataSource;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppTheme.specOffWhite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TopBar(
                openNowOnly: _openNowOnly,
                onOpenNowChanged: (v) => setState(() {
                  _openNowOnly = v;
                  _applyFiltersFromCache();
                }),
                onFilterTap: _openFilterSheet,
                listMapTabController: _listMapTabController,
              ),
              _ExploreSearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
              ),
            ],
          ),
        ),
        FutureBuilder<List<CategoryBanner>>(
          future: _approvedBannersFuture,
          builder: (context, bannerSnap) {
            final banners = bannerSnap.data ?? [];
            return FutureBuilder<(int, List<MockCategory>, List<MockParish>)>(
              future: _filterPanelDataFuture,
              builder: (context, catSnap) {
                final categories = catSnap.data?.$2 ?? [];
                final categoryNames = {for (final c in categories) c.id: c.name};
                final subcategoryNames = {
                  for (final c in categories)
                    for (final s in c.subcategories)
                      s.id: s.name,
                };
                return Expanded(
                  child: _buildListAndMap(
                    context,
                    dataSource,
                    banners: banners,
                    categoryNames: categoryNames,
                    subcategoryNames: subcategoryNames,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _onRefresh() async {
    final dataSource = AppDataScope.of(context).dataSource;
    setState(() {
      _fullListCache = null;
      _lastFilteredList = null;
      _nextOffset = 0;
      _hasMoreFromServer = true;
      _dealListingIds = null;
      _cachedAmenityBusinessIds = null;
      _cachedAmenityIds = const {};
      _initialLoadFuture = _performInitialLoad(dataSource);
    });
    await _initialLoadFuture;
  }

  Widget _buildListAndMap(
    BuildContext context,
    ListingDataSource dataSource, {
    required List<CategoryBanner> banners,
    required Map<String, String> categoryNames,
    required Map<String, String> subcategoryNames,
  }) {
    if (_fullListCache == null) {
      return FutureBuilder<void>(
        future: _initialLoadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.connectionState == ConnectionState.active) {
            return _ListLoadingSkeleton(padding: AppLayout.horizontalPadding(context));
          }
          return _buildListAndMapContent(
            context,
            dataSource,
            list: _lastFilteredList ?? const [],
            banners: banners,
            categoryNames: categoryNames,
            subcategoryNames: subcategoryNames,
          );
        },
      );
    }
    final list = _lastFilteredList ?? const [];
    return _buildListAndMapContent(
      context,
      dataSource,
      list: list,
      banners: banners,
      categoryNames: categoryNames,
      subcategoryNames: subcategoryNames,
    );
  }

  Widget _buildListAndMapContent(
    BuildContext context,
    ListingDataSource dataSource, {
    required List<MockListing> list,
    required List<CategoryBanner> banners,
    required Map<String, String> categoryNames,
    required Map<String, String> subcategoryNames,
  }) {
    final displayList = list;
    final hasMore = _hasMoreFromServer;
    final isLoadingMore = _loadingAuxiliaryFilters || _loadingMore;
    if (list.isEmpty) {
          final t = Theme.of(context);
          final hasSearch = _filters.searchQuery.isNotEmpty;
          return Center(
            child: AnimatedEntrance(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      hasSearch
                          ? 'No businesses match "${_filters.searchQuery}".'
                          : 'No businesses match your filters.',
                      textAlign: TextAlign.center,
                      style: t.textTheme.bodyLarge?.copyWith(
                        color: t.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasSearch
                          ? 'Try a different name, tagline, or category — or clear search and use filters.'
                          : 'Try changing category, parish, or turn off "Open now".',
                      textAlign: TextAlign.center,
                      style: t.textTheme.bodySmall?.copyWith(
                        color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    if (hasSearch) ...[
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _filters = _filters.copyWith(searchQuery: '');
                            _applyFiltersFromCache();
                          });
                        },
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        label: const Text('Clear search'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
    }
    final countsFuture = dataSource.useBackend && displayList.isNotEmpty
        ? AppDataScope.of(context).favoritesRepository.getCountsForBusinesses(displayList.map((l) => l.id).toList())
        : Future<Map<String, int>>.value({});
    return FutureBuilder<Map<String, int>>(
      future: countsFuture,
      builder: (context, countSnap) {
        final favoritesCounts = countSnap.data ?? {};
        return TabBarView(
          controller: _listMapTabController,
          children: [
            _ListViewList(
              list: displayList,
              tierMap: _lastTierMap,
              sponsoredIds: _lastSponsoredIds,
              favoritesCounts: favoritesCounts,
              banners: banners,
              categoryNames: categoryNames,
              subcategoryNames: subcategoryNames,
              featuredCount: 5,
              hasMore: hasMore,
              isLoadingMore: isLoadingMore,
              onLoadMore: hasMore ? () => _loadMoreListings(dataSource) : null,
              onRefresh: _onRefresh,
            ),
            _MapView(list: list, subcategoryNames: subcategoryNames),
          ],
        );
      },
    );
  }
}

class _ListMapToggle extends StatelessWidget {
  const _ListMapToggle({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isList = controller.index == 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleChip(
              icon: Icons.view_list_rounded,
              label: 'List',
              selected: isList,
              onTap: () => controller.animateTo(0),
            ),
            const SizedBox(width: 4),
            _ToggleChip(
              icon: Icons.map_rounded,
              label: 'Map',
              selected: !isList,
              onTap: () => controller.animateTo(1),
            ),
          ],
        );
      },
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.8)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreSearchBar extends StatelessWidget {
  const _ExploreSearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final padding = AppLayout.horizontalPadding(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 8),
        child: Material(
          color: AppTheme.specOffWhite,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search by name, tagline, or category',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 22,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: Icon(Icons.clear_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    tooltip: 'Clear',
                  );
                },
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            textInputAction: TextInputAction.search,
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.openNowOnly,
    required this.onOpenNowChanged,
    required this.onFilterTap,
    required this.listMapTabController,
  });

  final bool openNowOnly;
  final ValueChanged<bool> onOpenNowChanged;
  final VoidCallback onFilterTap;
  final TabController listMapTabController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.specNavy.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Open now',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.specNavy,
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: openNowOnly,
            onChanged: onOpenNowChanged,
            activeTrackColor: AppTheme.specGold,
            activeThumbColor: AppTheme.specNavy,
          ),
          const Spacer(),
          _ListMapToggle(controller: listMapTabController),
          const SizedBox(width: 8),
          Material(
            color: AppTheme.specNavy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.tune_rounded,
                  color: AppTheme.specNavy,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sponsored category banner: one large horizontal card or carousel with 10s rotation.
class _ExploreCategoryBanner extends StatefulWidget {
  const _ExploreCategoryBanner({
    required this.banners,
    required this.categoryNames,
  });

  final List<CategoryBanner> banners;
  final Map<String, String> categoryNames;

  @override
  State<_ExploreCategoryBanner> createState() => _ExploreCategoryBannerState();
}

class _ExploreCategoryBannerState extends State<_ExploreCategoryBanner> {
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
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
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
          child: _BannerCard(
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
                  child: _BannerCard(
                    banner: b,
                    headline: categoryNames[b.categoryId] ?? 'Explore',
                    radius: radius,
                  ),
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

class _BannerCard extends StatelessWidget {
  const _BannerCard({
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
              placeholder: (_, _) => _bannerPlaceholder(),
              errorWidget: (_, _, _) => _bannerPlaceholder(),
            )
          else
            _bannerPlaceholder(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.specNavy.withValues(alpha: 0.75),
                ],
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
                AppPrimaryButton(
                  onPressed: () {},
                  expanded: false,
                  child: const Text('Explore'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerPlaceholder() {
    return Container(
      color: AppTheme.specNavy.withValues(alpha: 0.2),
      child: Icon(Icons.image_rounded, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.4)),
    );
  }
}

/// Modal bottom sheet: category multi-select, parish, distance, rating, Open Now, Deal only, Apply.
class _ExploreFilterBottomSheet extends StatefulWidget {
  const _ExploreFilterBottomSheet({
    required this.initialFilters,
    required this.initialOpenNowOnly,
    required this.categories,
    required this.parishes,
    required this.totalCount,
    required this.onApply,
    required this.onClose,
  });

  final ListingFilters initialFilters;
  final bool initialOpenNowOnly;
  final List<MockCategory> categories;
  final List<MockParish> parishes;
  final int totalCount;
  final void Function(ListingFilters filters, bool openNowOnly) onApply;
  final VoidCallback onClose;

  @override
  State<_ExploreFilterBottomSheet> createState() => _ExploreFilterBottomSheetState();
}

class _ExploreFilterBottomSheetState extends State<_ExploreFilterBottomSheet> {
  late ListingFilters _filters;
  late bool _openNowOnly;
  String? _expandedCategoryId;
  Future<List<Amenity>>? _amenitiesFuture;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _openNowOnly = widget.initialOpenNowOnly;
    _amenitiesFuture = _amenitiesFutureForCategory(_filters.categoryId);
  }

  Future<List<Amenity>> _amenitiesFutureForCategory(String? categoryId) {
    if (categoryId == null) return Future.value([]);
    final cat = widget.categories.where((c) => c.id == categoryId).firstOrNull;
    final bucket = cat?.bucket;
    return AmenitiesRepository().getAmenitiesForBucket(bucket);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.paddingOf(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.specNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.specNavy,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, padding.bottom + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel('CATEGORY'),
                    const SizedBox(height: 8),
                    _buildCategoryList(theme),
                    const SizedBox(height: 20),
                    _sectionLabel('PARISHES'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.parishes.map((p) {
                        final selected = _filters.parishIds.contains(p.id);
                        return FilterChip(
                          label: Text(p.name),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              final next = Set<String>.from(_filters.parishIds);
                              if (selected) {
                                next.remove(p.id);
                              } else {
                                next.add(p.id);
                              }
                              _filters = _filters.copyWith(parishIds: next);
                            });
                          },
                          selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                          checkmarkColor: AppTheme.specNavy,
                        );
                      }).toList(),
                    ),
                    if (_filters.categoryId != null) ...[
                      const SizedBox(height: 20),
                      _sectionLabel('AMENITIES'),
                      const SizedBox(height: 8),
                      FutureBuilder<List<Amenity>>(
                        future: _amenitiesFuture,
                        builder: (context, snap) {
                          final amenities = snap.data ?? [];
                          if (amenities.isEmpty && snap.connectionState != ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (amenities.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                            );
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: amenities.map((a) {
                              final selected = _filters.amenityIds.contains(a.id);
                              return FilterChip(
                                label: Text(a.name),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    final next = Set<String>.from(_filters.amenityIds);
                                    if (selected) {
                                      next.remove(a.id);
                                    } else {
                                      next.add(a.id);
                                    }
                                    _filters = _filters.copyWith(amenityIds: next);
                                  });
                                },
                                selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                                checkmarkColor: AppTheme.specNavy,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    _sectionLabel('DISTANCE (optional)'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Any'),
                          selected: _filters.maxDistanceMiles == null,
                          onSelected: (_) => setState(() => _filters = _filters.copyWith(maxDistanceMiles: null)),
                          selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                          labelStyle: TextStyle(
                            color: _filters.maxDistanceMiles == null ? AppTheme.specNavy : theme.colorScheme.onSurfaceVariant,
                            fontWeight: _filters.maxDistanceMiles == null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        ...([10.0, 25.0, 50.0].map((m) {
                          final selected = _filters.maxDistanceMiles == m;
                          return ChoiceChip(
                            label: Text('${m.round()} mi'),
                            selected: selected,
                            onSelected: (_) => setState(() => _filters = _filters.copyWith(maxDistanceMiles: m)),
                            selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                            labelStyle: TextStyle(
                              color: selected ? AppTheme.specNavy : theme.colorScheme.onSurfaceVariant,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          );
                        })),
                      ],
                    ),
                    if (_filters.maxDistanceMiles != null) ...[
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.specGold,
                          thumbColor: AppTheme.specGold,
                          overlayColor: AppTheme.specGold.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: _filters.maxDistanceMiles!.clamp(1.0, 50.0),
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: '${_filters.maxDistanceMiles!.round()} mi',
                          onChanged: (v) => setState(() => _filters = _filters.copyWith(maxDistanceMiles: v)),
                        ),
                      ),
                    ],
                    _sectionLabel('MINIMUM RATING'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [null, 3.0, 3.5, 4.0, 4.5].map((r) {
                        final label = r == null ? 'Any' : r.toString();
                        final selected = _filters.minRating == r;
                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) => setState(() => _filters = _filters.copyWith(minRating: r)),
                          selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                          labelStyle: TextStyle(
                            color: selected ? AppTheme.specNavy : theme.colorScheme.onSurfaceVariant,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Open now only',
                            style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy),
                          ),
                        ),
                        Switch.adaptive(
                          value: _openNowOnly,
                          onChanged: (v) => setState(() => _openNowOnly = v),
                          activeTrackColor: AppTheme.specGold,
                          activeThumbColor: AppTheme.specNavy,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Deals only',
                            style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy),
                          ),
                        ),
                        Switch.adaptive(
                          value: _filters.dealOnly,
                          onChanged: (v) => setState(() => _filters = _filters.copyWith(dealOnly: v)),
                          activeTrackColor: AppTheme.specGold,
                          activeThumbColor: AppTheme.specNavy,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      onPressed: () => widget.onApply(_filters, _openNowOnly),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppTheme.specNavy,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCategoryList(ThemeData theme) {
    return Column(
      children: [
        _CategoryTile(
          label: 'All Businesses',
          count: widget.totalCount,
          isExpanded: false,
          isSelected: _filters.categoryId == null,
          onTap: () => setState(() {
            _filters = _filters.copyWith(categoryId: null, subcategoryIds: const {}, amenityIds: const {});
            _expandedCategoryId = null;
            _amenitiesFuture = _amenitiesFutureForCategory(null);
          }),
        ),
        ...widget.categories.map((cat) {
          final isExpanded = _expandedCategoryId == cat.id;
          final isSelected = _filters.categoryId == cat.id;
          return Column(
            key: ValueKey(cat.id),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryTile(
                label: cat.name,
                count: cat.count,
                isExpanded: isExpanded,
                isSelected: isSelected,
                hasSubcategories: cat.subcategories.isNotEmpty,
                onTap: () => setState(() {
                  if (isExpanded) {
                    _expandedCategoryId = null;
                  } else {
                    _expandedCategoryId = cat.id;
                    _filters = _filters.copyWith(categoryId: cat.id, amenityIds: const {});
                    _amenitiesFuture = _amenitiesFutureForCategory(cat.id);
                  }
                }),
              ),
              if (isExpanded && cat.subcategories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cat.subcategories.map((sub) {
                      final selected = _filters.subcategoryIds.contains(sub.id);
                      return FilterChip(
                        label: Text(sub.name),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            final next = Set<String>.from(_filters.subcategoryIds);
                            if (selected) {
                              next.remove(sub.id);
                            } else {
                              next.add(sub.id);
                            }
                            _filters = _filters.copyWith(subcategoryIds: next);
                          });
                        },
                        selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.count,
    required this.isExpanded,
    required this.isSelected,
    this.hasSubcategories = false,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isExpanded;
  final bool isSelected;
  final bool hasSubcategories;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isSelected ? AppTheme.specGold.withValues(alpha: 0.2) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: AppTheme.specNavy,
                  ),
                ),
              ),
              if (count > 0)
                Text(
                  count.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.7),
                  ),
                ),
              if (hasSubcategories)
                Icon(
                  isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppTheme.specNavy,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton loading for directory list: card-shaped placeholders with shimmer.
class _ListLoadingSkeleton extends StatelessWidget {
  const _ListLoadingSkeleton({required this.padding});

  final EdgeInsets padding;

  static const int _placeholderCount = 8;
  static const double _cardRadius = 16;

  @override
  Widget build(BuildContext context) {
    final baseColor = AppTheme.specNavy.withValues(alpha: 0.08);
    final highlightColor = AppTheme.specNavy.withValues(alpha: 0.14);
    return Container(
      color: AppTheme.specOffWhite,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 24),
          itemCount: _placeholderCount,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.specWhite,
                  borderRadius: BorderRadius.circular(_cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 18,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: 120,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// List: Local Partners at top (when unfiltered) or sponsored then partners (when filtered); all randomized within groups.
/// Sponsored listings get a slight blue border. Supports pagination via [onLoadMore].
class _ListViewList extends StatelessWidget {
  const _ListViewList({
    required this.list,
    this.tierMap = const {},
    this.sponsoredIds = const {},
    this.favoritesCounts = const {},
    this.banners = const [],
    this.categoryNames = const {},
    this.subcategoryNames = const {},
    this.featuredCount = 5,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.onRefresh,
  });

  final List<MockListing> list;
  final Map<String, String> tierMap;
  final Set<String> sponsoredIds;
  final Map<String, int> favoritesCounts;
  final List<CategoryBanner> banners;
  final Map<String, String> categoryNames;
  final Map<String, String> subcategoryNames;
  final int featuredCount;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final Future<void> Function()? onRefresh;

  static const double _cardRadius = 18;
  static const int _sponsoredInlineEvery = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final hasBanners = banners.isNotEmpty;

    final listView = ListView(
      padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 16),
      children: [
        if (isLoadingMore) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Updating results…',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (hasBanners) ...[
            _ExploreCategoryBanner(
              banners: banners,
              categoryNames: categoryNames,
            ),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Listings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.specNavy,
              ),
            ),
          ),
          ..._buildStandardListWithSponsored(list, padding, theme),
          if (hasMore && onLoadMore != null && !isLoadingMore) ...[
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: TextButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: const Text('Load more'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.specNavy,
                  ),
                ),
              ),
            ),
          ],
        ],
    );
    final body = onRefresh != null
        ? RefreshIndicator(onRefresh: onRefresh!, child: listView)
        : listView;
    return Container(color: AppTheme.specOffWhite, child: body);
  }

  List<Widget> _buildStandardListWithSponsored(
    List<MockListing> standard,
    EdgeInsets padding,
    ThemeData theme,
  ) {
    final children = <Widget>[];
    final rnd = banners.isNotEmpty ? Random(Object.hash(standard.length, standard.hashCode)) : null;
    for (var i = 0; i < standard.length; i++) {
      if (banners.isNotEmpty && i > 0 && i % _sponsoredInlineEvery == 0) {
        final bannerIndex = rnd!.nextInt(banners.length);
        final b = banners[bannerIndex];
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _SponsoredInlineCard(
            banner: b,
            headline: categoryNames[b.categoryId] ?? 'Sponsored',
            radius: _cardRadius,
            compact: true,
          ),
        ));
      }
      final listing = standard[i];
      final isLocalPartner = BusinessTierService.fromPlanTier(tierMap[listing.id]) == BusinessTier.localPartner;
      final isSponsored = sponsoredIds.contains(listing.id);
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _StandardListingCard(
            listing: listing,
            tierMap: tierMap,
            favoritesCounts: favoritesCounts,
            cardRadius: _cardRadius,
            isLocalPartner: isLocalPartner,
            isSponsored: isSponsored,
            subcategoryNames: subcategoryNames,
          ),
        ),
      );
    }
    return children;
  }
}

/// Business logo thumbnail: network image or placeholder icon.
class _ListingLogo extends StatelessWidget {
  const _ListingLogo({
    required this.logoUrl,
    this.size = 48,
    this.radius = 12,
  });

  final String? logoUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final boxDecoration = BoxDecoration(
      color: AppTheme.specNavy.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(radius),
    );
    if (logoUrl != null && logoUrl!.trim().isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: boxDecoration,
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          fit: BoxFit.cover,
          width: size,
          memCacheWidth: 200,
          memCacheHeight: 200,
          height: size,
          placeholder: (_, _) => Icon(
            Icons.store_rounded,
            size: size * 0.5,
            color: AppTheme.specNavy.withValues(alpha: 0.7),
          ),
          errorWidget: (_, _, _) => Icon(
            Icons.store_rounded,
            size: size * 0.5,
            color: AppTheme.specNavy.withValues(alpha: 0.7),
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: boxDecoration,
      child: Icon(
        Icons.store_rounded,
        size: size * 0.5,
        color: AppTheme.specNavy.withValues(alpha: 0.7),
      ),
    );
  }
}

class _StandardListingCard extends StatelessWidget {
  const _StandardListingCard({
    required this.listing,
    required this.tierMap,
    required this.favoritesCounts,
    required this.cardRadius,
    this.isLocalPartner = false,
    this.isSponsored = false,
    this.subcategoryNames = const {},
  });

  final MockListing listing;
  final Map<String, String> tierMap;
  final Map<String, int> favoritesCounts;
  final double cardRadius;
  final bool isLocalPartner;
  final bool isSponsored;
  final Map<String, String> subcategoryNames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = listing.rating;
    final ratingStr = rating != null ? '(${rating.toStringAsFixed(1)})' : '—';
    final location = listing.address ?? '—';
    final distanceStr = listing.distanceMiles != null
        ? '${listing.distanceMiles!.toStringAsFixed(1)} mi'
        : null;
    final subName = listing.subcategoryId != null
        ? subcategoryNames[listing.subcategoryId!]
        : null;
    final categorySubLine = subName != null
        ? '${listing.categoryName} · $subName'
        : listing.categoryName;
    final padding = isLocalPartner
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    final logoSize = isLocalPartner ? 56.0 : 48.0;
    final cardColor = isLocalPartner
        ? AppTheme.specGold.withValues(alpha: 0.12)
        : AppTheme.specWhite;
    Border? border;
    if (isLocalPartner) {
      border = Border.all(color: AppTheme.specGold.withValues(alpha: 0.35), width: 1);
    } else if (isSponsored) {
      border = Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 1.5);
    }
    return AnimatedEntrance(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ListingDetailScreen(listingId: listing.id)),
          ),
          borderRadius: BorderRadius.circular(cardRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(cardRadius),
              border: border,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLocalPartner ? 0.08 : 0.06),
                  blurRadius: isLocalPartner ? 12 : 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _ListingLogo(logoUrl: listing.imagePlaceholder, size: logoSize, radius: 12),
                SizedBox(width: isLocalPartner ? 16 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        listing.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.specNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (i) {
                              final filled = rating != null && i < rating.floor().clamp(0, 5);
                              return Icon(
                                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 16,
                                color: AppTheme.specGold,
                              );
                            }),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ratingStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    categorySubLine,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (distanceStr != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    distanceStr,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isLocalPartner)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.specGold.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '+ ${BusinessTierService.tierDisplayName(BusinessTier.localPartner)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.specNavy,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                _FavoriteHeartButton(listingId: listing.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteHeartButton extends StatefulWidget {
  const _FavoriteHeartButton({required this.listingId});

  final String listingId;

  @override
  State<_FavoriteHeartButton> createState() => _FavoriteHeartButtonState();
}

class _FavoriteHeartButtonState extends State<_FavoriteHeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoritesScope.of(context),
      builder: (context, ids, _) {
        final isFav = ids.contains(widget.listingId);
        return ScaleTransition(
          scale: _scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                _controller.forward().then((_) => _controller.reverse());
                final scope = AppDataScope.of(context);
                if (!scope.dataSource.useBackend) return;
                final next = Set<String>.from(ids);
                if (next.contains(widget.listingId)) {
                  next.remove(widget.listingId);
                  await scope.favoritesRepository.remove(widget.listingId);
                } else {
                  final perms = scope.userTierService.value ?? ResolvedPermissions.free;
                  if (perms.wouldExceedFavoritesLimit(ids.length)) {
                    if (!context.mounted) return;
                    await presentSubscriptionPaywall(context);
                    return;
                  }
                  next.add(widget.listingId);
                  await scope.favoritesRepository.add(widget.listingId);
                }
                if (context.mounted) FavoritesScope.of(context).value = next;
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 22,
                  color: isFav ? AppTheme.specGold : AppTheme.specNavy.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SponsoredInlineCard extends StatelessWidget {
  const _SponsoredInlineCard({
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                    child: CachedNetworkImage(
                      imageUrl: banner.imageUrl,
                      fit: BoxFit.cover,
                    ),
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
                  AppPrimaryButton(
                    onPressed: () {},
                    expanded: false,
                    child: const Text('Explore'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Baton Rouge area - used as map center and base for synthetic marker positions.
const _mapCenter = LatLng(30.4515, -91.1871);

/// Map view with OSM tiles and a marker per business (synthetic lat/lng when not in data).
/// Tapping a marker shows a tooltip card; tap "View" to open the listing or tap the map to dismiss.
class _MapView extends StatefulWidget {
  const _MapView({required this.list, this.subcategoryNames = const {}});

  final List<MockListing> list;
  final Map<String, String> subcategoryNames;

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  int? _selectedIndex;

  static LatLng _positionForIndex(int index) {
    const radius = 0.012;
    final angle = index * 0.7;
    return LatLng(
      _mapCenter.latitude + radius * cos(angle),
      _mapCenter.longitude + radius * sin(angle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = widget.list;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _mapCenter,
            initialZoom: 13.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onTap: (_, _) {
              if (_selectedIndex != null) {
                setState(() => _selectedIndex = null);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.my_app',
            ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < list.length; i++)
                  Marker(
                    point: _positionForIndex(i),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedIndex = _selectedIndex == i ? null : i);
                      },
                  child: SvgPicture.asset(
                    'assets/images/map pin icon.svg',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    // No colorFilter: keep SVG's built-in logo colors (gold, red, white, navy).
                  ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (_selectedIndex != null && _selectedIndex! < list.length)
          DraggableScrollableSheet(
            initialChildSize: 0.36,
            minChildSize: 0.14,
            maxChildSize: 0.58,
            builder: (context, scrollController) {
              final listing = list[_selectedIndex!];
              final rating = listing.rating;
              final ratingStr = rating?.toStringAsFixed(1);
              final subName = widget.subcategoryNames[listing.subcategoryId ?? ''];
              final categorySubLine = subName != null
                  ? '${listing.categoryName} · $subName'
                  : listing.categoryName;
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.specWhite,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.specNavy.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.specNavy,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (listing.tagline.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  listing.tagline,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.specNavy.withValues(alpha: 0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.specNavy.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  categorySubLine,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppTheme.specNavy.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (i) {
                                      final filled = rating != null &&
                                          i < rating.floor().clamp(0, 5);
                                      return Icon(
                                        filled
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        size: 20,
                                        color: AppTheme.specGold,
                                      );
                                    }),
                                  ),
                                  if (ratingStr != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      ratingStr,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      'No reviews',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _selectedIndex = null),
                          color: AppTheme.specNavy,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppPrimaryButton(
                      onPressed: () {
                        final id = listing.id;
                        setState(() => _selectedIndex = null);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ListingDetailScreen(listingId: id),
                          ),
                        );
                      },
                      expanded: false,
                      child: const Text('View listing'),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
