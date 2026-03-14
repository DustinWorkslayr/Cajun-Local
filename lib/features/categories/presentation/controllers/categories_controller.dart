import 'dart:async';
import 'dart:math' show Random;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/businesses/data/models/business_category.dart';
import 'package:cajun_local/features/categories/data/repositories/category_repository.dart';
import 'package:cajun_local/features/locations/data/models/parish.dart';
import 'package:cajun_local/features/locations/data/repositories/parish_repository.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/features/businesses/data/repositories/amenities_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_ads_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_subscriptions_repository.dart';
import 'package:cajun_local/core/subscription/business_tier_service.dart';
import 'package:cajun_local/features/profile/data/models/user_parish_preferences.dart';
import 'package:cajun_local/features/categories/data/models/category_banner.dart';
import 'package:cajun_local/features/categories/data/repositories/category_banners_repository.dart';
import 'package:cajun_local/features/deals/data/repositories/deals_repository.dart';

part 'categories_controller.g.dart';

class CategoriesState {
  CategoriesState({
    required this.filters,
    required this.openNowOnly,
    this.fullListCache,
    this.filteredList,
    this.nextOffset = 0,
    this.hasMoreFromServer = true,
    this.isLoadingMore = false,
    this.loadingAuxiliaryFilters = false,
    this.tierMap = const {},
    this.sponsoredIds = const {},
    this.dealListingIds,
    this.cachedAmenityBusinessIds,
    this.cachedAmenityIds = const {},
  });

  final ListingFilters filters;
  final bool openNowOnly;
  final List<Business>? fullListCache;
  final List<Business>? filteredList;
  final int nextOffset;
  final bool hasMoreFromServer;
  final bool isLoadingMore;
  final bool loadingAuxiliaryFilters;
  final Map<String, String> tierMap;
  final Set<String> sponsoredIds;
  final Set<String>? dealListingIds;
  final Set<String>? cachedAmenityBusinessIds;
  final Set<String> cachedAmenityIds;

  CategoriesState copyWith({
    ListingFilters? filters,
    bool? openNowOnly,
    List<Business>? fullListCache,
    List<Business>? filteredList,
    int? nextOffset,
    bool? hasMoreFromServer,
    bool? isLoadingMore,
    bool? loadingAuxiliaryFilters,
    Map<String, String>? tierMap,
    Set<String>? sponsoredIds,
    Set<String>? dealListingIds,
    Set<String>? cachedAmenityBusinessIds,
    Set<String>? cachedAmenityIds,
  }) {
    return CategoriesState(
      filters: filters ?? this.filters,
      openNowOnly: openNowOnly ?? this.openNowOnly,
      fullListCache: fullListCache ?? this.fullListCache,
      filteredList: filteredList ?? this.filteredList,
      nextOffset: nextOffset ?? this.nextOffset,
      hasMoreFromServer: hasMoreFromServer ?? this.hasMoreFromServer,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingAuxiliaryFilters: loadingAuxiliaryFilters ?? this.loadingAuxiliaryFilters,
      tierMap: tierMap ?? this.tierMap,
      sponsoredIds: sponsoredIds ?? this.sponsoredIds,
      dealListingIds: dealListingIds ?? this.dealListingIds,
      cachedAmenityBusinessIds: cachedAmenityBusinessIds ?? this.cachedAmenityBusinessIds,
      cachedAmenityIds: cachedAmenityIds ?? this.cachedAmenityIds,
    );
  }

  /// Clears cache safely and resets pagination for a fresh query based on current filters.
  CategoriesState cleared() {
    return CategoriesState(
      filters: filters,
      openNowOnly: openNowOnly,
      fullListCache: null,
      filteredList: null,
      nextOffset: 0,
      hasMoreFromServer: true,
      isLoadingMore: false,
      loadingAuxiliaryFilters: false,
      tierMap: const {},
      sponsoredIds: const {},
      dealListingIds: null,
      cachedAmenityBusinessIds: null,
      cachedAmenityIds: const {},
    );
  }
}

const int _kExplorePageSize = 50;

@riverpod
class CategoriesController extends _$CategoriesController {
  @override
  FutureOr<CategoriesState> build() async {
    final parishIds = await UserParishPreferences.getPreferredParishIds();
    final initialState = CategoriesState(
      filters: ListingFilters(parishIds: parishIds.toSet()),
      openNowOnly: false,
    );
    return _performInitialLoad(initialState);
  }

  BusinessRepository get _businessRepo => BusinessRepository();
  DealsRepository get _dealsRepo => DealsRepository();

  Future<void> initializeWith({String? search, String? categoryId}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    // Check if anything actually changed
    final searchChanged = search != null && current.filters.searchQuery != search;
    final categoryChanged = categoryId != null && current.filters.categoryId != categoryId;
    
    if (!searchChanged && !categoryChanged) return;

    final newFilters = current.filters.copyWith(
      searchQuery: search ?? current.filters.searchQuery,
      categoryId: categoryId ?? current.filters.categoryId,
    );
    
    if (categoryChanged) {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() {
        return _performInitialLoad(current.cleared().copyWith(filters: newFilters));
      });
    } else {
      _applyFiltersAsync(current.copyWith(filters: newFilters));
    }
  }

  Future<void> updateSearch(String searchQuery) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final newFilters = current.filters.copyWith(searchQuery: searchQuery);
    _applyFiltersAsync(current.copyWith(filters: newFilters));
  }

  Future<void> applyFilters(ListingFilters filters, bool openNowOnly) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Save preferences
    await UserParishPreferences.setPreferredParishIds(filters.parishIds);

    final categoryChanged = filters.categoryId != current.filters.categoryId;
    final newState = current.copyWith(filters: filters, openNowOnly: openNowOnly);

    if (categoryChanged) {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _performInitialLoad(newState.cleared().copyWith(filters: filters, openNowOnly: openNowOnly)));
    } else {
      _applyFiltersAsync(newState);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMoreFromServer || current.fullListCache == null) return;
    
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final list = await _businessRepo.listApproved(
        limit: _kExplorePageSize,
        offset: current.nextOffset,
        categoryId: current.filters.categoryId,
        parishIds: current.filters.parishIds,
      );
      
      final existingIds = current.fullListCache!.map((l) => l.id).toSet();
      final newList = list.where((l) => !existingIds.contains(l.id)).toList();
      final ids = newList.map((l) => l.id).toList();
      
      Map<String, String> newTiers = {};
      if (ids.isNotEmpty) {
        newTiers = await BusinessSubscriptionsRepository().getActivePlanTiersForBusinesses(ids);
      }
      
      final nextState = current.copyWith(
        fullListCache: [...current.fullListCache!, ...newList],
        nextOffset: current.nextOffset + list.length,
        hasMoreFromServer: list.length == _kExplorePageSize,
        isLoadingMore: false,
        tierMap: newTiers.isNotEmpty ? {...current.tierMap, ...newTiers} : current.tierMap,
      );
      
      _applyFiltersAsync(nextState);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? CategoriesState(filters: const ListingFilters(), openNowOnly: false);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _performInitialLoad(current.cleared()));
  }

  Future<CategoriesState> _performInitialLoad(CategoriesState currentState) async {
    final list = await _businessRepo.listApproved(
      limit: _kExplorePageSize, 
      offset: 0, 
      categoryId: currentState.filters.categoryId,
      parishIds: currentState.filters.parishIds,
    );
    
    if (list.isEmpty) {
      return currentState.copyWith(
        fullListCache: [],
        filteredList: [],
        nextOffset: 0,
        hasMoreFromServer: false,
        tierMap: const {},
        sponsoredIds: const {},
      );
    }

    final ids = list.map((l) => l.id).toList();
    final tierMap = await BusinessSubscriptionsRepository().getActivePlanTiersForBusinesses(ids);
    final sponsoredIds = await BusinessAdsRepository().getActiveSponsoredBusinessIdsForExplore();

    final newState = currentState.copyWith(
      fullListCache: list,
      nextOffset: list.length,
      hasMoreFromServer: list.length == _kExplorePageSize,
      tierMap: tierMap,
      sponsoredIds: sponsoredIds,
    );

    return _calculateFilteredState(newState);
  }

  void _applyFiltersAsync(CategoriesState newState) async {
    state = AsyncValue.data(newState.copyWith(loadingAuxiliaryFilters: true));
    try {
      final processedState = await _calculateFilteredState(newState);
      state = AsyncValue.data(processedState.copyWith(loadingAuxiliaryFilters: false));
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) => a.length == b.length && a.every((x) => b.contains(x));

  Future<CategoriesState> _calculateFilteredState(CategoriesState s) async {
    if (s.fullListCache == null) return s;

    Set<String>? dealListingIds = s.dealListingIds;
    if (s.filters.dealOnly && dealListingIds == null) {
      final deals = await _dealsRepo.listApproved(activeOnly: true);
      dealListingIds = deals.map((d) => d.businessId).toSet();
    }

    Set<String>? cachedAmenityBusinessIds = s.cachedAmenityBusinessIds;
    Set<String> cachedAmenityIds = s.cachedAmenityIds;
    if (s.filters.amenityIds.isNotEmpty && !_setEquals(s.filters.amenityIds, cachedAmenityIds)) {
      cachedAmenityIds = Set<String>.from(s.filters.amenityIds);
      cachedAmenityBusinessIds = await AmenitiesRepository().getBusinessIdsWithAnyAmenity(cachedAmenityIds);
    }

    final amenitySet = s.filters.amenityIds.isNotEmpty ? cachedAmenityBusinessIds : null;
    final dealSet = s.filters.dealOnly ? dealListingIds : null;

    final filtered = s.fullListCache!.where((l) {
      if (s.openNowOnly) {
         // TODO: Implement open now check if possible, or skip for now
      }
      if (dealSet != null && !dealSet.contains(l.id)) return false;
      if (amenitySet != null && !amenitySet.contains(l.id)) return false;

      if (s.filters.searchQuery.isNotEmpty) {
        final q = s.filters.searchQuery.toLowerCase();
        final nameMatch = l.name.toLowerCase().contains(q);
        final taglineMatch = l.tagline?.toLowerCase().contains(q) ?? false;
        if (!nameMatch && !taglineMatch) return false;
      }

      return true;
    }).toList();

    final groupedAndShuffledList = _partitionAndOrder(filtered, s.tierMap, s.sponsoredIds, _isFiltered(s.filters));

    return s.copyWith(
      filteredList: groupedAndShuffledList,
      dealListingIds: dealListingIds,
      cachedAmenityBusinessIds: cachedAmenityBusinessIds,
      cachedAmenityIds: cachedAmenityIds,
    );
  }

  bool _isFiltered(ListingFilters f) {
    return f.parishIds.isNotEmpty || f.categoryId != null || f.subcategoryIds.isNotEmpty;
  }

  List<Business> _partitionAndOrder(
    List<Business> list,
    Map<String, String> tierMap,
    Set<String> sponsoredIds,
    bool isFiltered,
  ) {
    final rnd = Random();
    final sponsored = list.where((l) => sponsoredIds.contains(l.id)).toList()..shuffle(rnd);
    final partners = list
        .where((l) => !sponsoredIds.contains(l.id) && BusinessTierService.fromPlanTier(tierMap[l.id]) == BusinessTier.localPartner)
        .toList()
      ..shuffle(rnd);
    final rest = list
        .where((l) => !sponsoredIds.contains(l.id) && BusinessTierService.fromPlanTier(tierMap[l.id]) != BusinessTier.localPartner)
        .toList()
      ..shuffle(rnd);
    
    if (isFiltered) {
      return [...sponsored, ...partners, ...rest];
    }
    return [...partners, ...rest];
  }
}

@riverpod
Future<List<CategoryBanner>> approvedCategoryBanners(ApprovedCategoryBannersRef ref) {
  return CategoryBannersRepository().listApproved();
}

@riverpod
Future<(int, List<BusinessCategory>, List<Parish>)> filterPanelData(FilterPanelDataRef ref) async {
  final categories = await CategoryRepository().listCategories();
  final parishes = await ParishRepository().listParishes();
  final totalCount = await BusinessRepository().listApprovedCount();
  return (totalCount, categories, parishes);
}
