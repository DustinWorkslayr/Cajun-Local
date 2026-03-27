import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/features/categories/data/models/category_banner.dart';
import 'package:cajun_local/features/categories/presentation/controllers/categories_controller.dart';
import 'package:cajun_local/features/favorites/data/repositories/favorites_repository.dart';
import 'package:cajun_local/features/explore/presentation/widgets/explore_filter_sheet.dart';
import 'package:cajun_local/features/explore/presentation/widgets/explore_list_view.dart';
import 'package:cajun_local/features/explore/presentation/widgets/explore_map_view.dart';
import 'package:cajun_local/features/explore/presentation/widgets/explore_search_bar.dart';
import 'package:cajun_local/features/explore/presentation/widgets/explore_top_bar.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/animated_entrance.dart';

// Keeping this alias so router.dart needs only the import path change.
typedef CategoriesScreen = ExploreScreen;

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.initialSearch, this.initialCategoryId});

  /// Pre-fill the search box when opening from home search.
  final String? initialSearch;

  /// Pre-select a category when opening from a home category tap.
  final String? initialCategoryId;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> with TickerProviderStateMixin {
  late TabController _listMapTabController;
  late TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch ?? '');
    _listMapTabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() {
      ref.read(categoriesControllerProvider.notifier).initializeWith(
            search: widget.initialSearch,
            categoryId: widget.initialCategoryId,
          );
    });
  }

  @override
  void didUpdateWidget(ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId ||
        widget.initialSearch != oldWidget.initialSearch) {
      if (widget.initialSearch != oldWidget.initialSearch &&
          widget.initialSearch != _searchController.text) {
        _searchController.text = widget.initialSearch ?? '';
      }
      Future.microtask(() {
        ref.read(categoriesControllerProvider.notifier).initializeWith(
              search: widget.initialSearch,
              categoryId: widget.initialCategoryId,
            );
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
      ref.read(categoriesControllerProvider.notifier).updateSearch('');
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(categoriesControllerProvider.notifier).updateSearch(trimmed);
    });
  }

  void _openFilterSheet(CategoriesState controllerState) async {
    final asyncPanelData = ref.read(filterPanelDataProvider);
    if (!asyncPanelData.hasValue) return;

    final data = asyncPanelData.value!;
    final totalCount = data.$1;
    final categories = data.$2;
    final parishes = data.$3;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExploreFilterSheet(
        initialFilters: controllerState.filters,
        initialOpenNowOnly: controllerState.openNowOnly,
        categories: categories,
        parishes: parishes,
        totalCount: totalCount,
        onApply: (filters, openNowOnly) {
          _searchController.text = filters.searchQuery;
          ref.read(categoriesControllerProvider.notifier).applyFilters(filters, openNowOnly);
          Navigator.of(ctx).pop();
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await ref.read(categoriesControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(categoriesControllerProvider);
    final bannersAsync = ref.watch(approvedCategoryBannersProvider);
    final panelDataAsync = ref.watch(filterPanelDataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── sticky header (AppBar replacement) ──────────────────────────────
        Container(
          color: AppTheme.specOffWhite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExploreTopBar(
                openNowOnly: asyncState.valueOrNull?.openNowOnly ?? false,
                onOpenNowChanged: (v) {
                  final s = asyncState.valueOrNull;
                  if (s != null) {
                    ref.read(categoriesControllerProvider.notifier).applyFilters(s.filters, v);
                  }
                },
                onFilterTap: () {
                  final s = asyncState.valueOrNull;
                  if (s != null) _openFilterSheet(s);
                },
                listMapTabController: _listMapTabController,
              ),
              ExploreSearchBar(controller: _searchController, onChanged: _onSearchChanged),
            ],
          ),
        ),

        // ── body ─────────────────────────────────────────────────────────────
        Expanded(
          child: asyncState.when(
            data: (state) {
              final banners = bannersAsync.valueOrNull ?? [];
              final panelData = panelDataAsync.valueOrNull;

              final categories = panelData?.$2 ?? [];
              final categoryNames = {for (final c in categories) c.id: c.name};
              final subcategoryNames = {
                for (final c in categories)
                  for (final s in c.subcategories) s.id: s.name,
              };

              if (state.fullListCache == null) {
                return ExploreLoadingSkeleton(padding: AppLayout.horizontalPadding(context));
              }

              return _buildBody(
                context,
                state: state,
                banners: banners,
                categoryNames: categoryNames,
                subcategoryNames: subcategoryNames,
              );
            },
            loading: () => ExploreLoadingSkeleton(padding: AppLayout.horizontalPadding(context)),
            error: (err, _) => Center(child: Text('Error loading directory: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required CategoriesState state,
    required List<CategoryBanner> banners,
    required Map<String, String> categoryNames,
    required Map<String, String> subcategoryNames,
  }) {
    final list = state.filteredList ?? [];
    final hasMore = state.hasMoreFromServer;
    final isLoadingMore = state.loadingAuxiliaryFilters || state.isLoadingMore;

    if (list.isEmpty) {
      return _buildEmptyState(context, state);
    }

    final countsFuture = ref
        .read(favoritesRepositoryProvider)
        .getCountsForBusinesses(list.map((l) => l.id).toList());

    return FutureBuilder<Map<String, int>>(
      future: countsFuture,
      builder: (context, countSnap) {
        final favoritesCounts = countSnap.data ?? {};
        return TabBarView(
          controller: _listMapTabController,
          children: [
            ExploreListView(
              list: list,
              tierMap: state.tierMap,
              sponsoredIds: state.sponsoredIds,
              favoritesCounts: favoritesCounts,
              banners: banners,
              categoryNames: categoryNames,
              subcategoryNames: subcategoryNames,
              featuredCount: 5,
              hasMore: hasMore,
              isLoadingMore: isLoadingMore,
              onLoadMore: hasMore ? () => ref.read(categoriesControllerProvider.notifier).loadMore() : null,
              onRefresh: _onRefresh,
            ),
            ExploreMapView(list: list, subcategoryNames: subcategoryNames),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, CategoriesState state) {
    final t = Theme.of(context);
    final hasSearch = state.filters.searchQuery.isNotEmpty;
    return Center(
      child: AnimatedEntrance(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(
                hasSearch
                    ? 'No businesses match "${state.filters.searchQuery}".'
                    : 'No businesses match your filters.',
                textAlign: TextAlign.center,
                style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                hasSearch
                    ? 'Try a different name, tagline, or category — or clear search and use filters.'
                    : 'Try changing category, parish, or turn off "Open now".',
                textAlign: TextAlign.center,
                style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
              ),
              if (hasSearch) ...[
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(categoriesControllerProvider.notifier).updateSearch('');
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
}
