import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/models/business.dart';
import 'package:my_app/core/data/models/business_hours.dart';
import 'package:my_app/core/data/models/deal.dart';
import 'package:my_app/core/data/models/punch_card_program.dart';
import 'package:my_app/core/data/models/user_punch_card.dart';
import 'package:my_app/core/data/repositories/business_hours_repository.dart';
import 'package:my_app/core/data/repositories/business_links_repository.dart';
import 'package:my_app/core/data/repositories/business_managers_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/category_repository.dart';
import 'package:my_app/core/data/models/business_event.dart';
import 'package:my_app/core/data/repositories/business_events_repository.dart';
import 'package:my_app/core/data/repositories/deals_repository.dart';
import 'package:my_app/core/data/repositories/menu_repository.dart';
import 'package:my_app/core/data/repositories/amenities_repository.dart';
import 'package:my_app/core/data/repositories/parish_repository.dart';
import 'package:my_app/core/data/repositories/punch_card_programs_repository.dart';
import 'package:my_app/core/data/repositories/user_punch_cards_repository.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:my_app/core/utils/hours_format.dart';

/// Single data entry point: uses Supabase repos when configured.
/// When Supabase is not configured, methods throw so the UI shows "Loading data failed" instead of mock data.
class ListingDataSource {
  /// Error message thrown when backend is not configured; UI should show this or "Loading data failed".
  static const String kNotConfiguredMessage = 'Loading data failed. Backend is not configured.';

  ListingDataSource({
    AuthRepository? authRepository,
    BusinessRepository? businessRepository,
    BusinessManagersRepository? businessManagersRepository,
    CategoryRepository? categoryRepository,
    BusinessHoursRepository? businessHoursRepository,
    BusinessLinksRepository? businessLinksRepository,
    MenuRepository? menuRepository,
    DealsRepository? dealsRepository,
    PunchCardProgramsRepository? punchCardProgramsRepository,
    UserPunchCardsRepository? userPunchCardsRepository,
    BusinessEventsRepository? businessEventsRepository,
    AmenitiesRepository? amenitiesRepository,
  })  : _auth = authRepository ?? AuthRepository(),
        _business = businessRepository ?? BusinessRepository(),
        _businessManagers = businessManagersRepository ?? BusinessManagersRepository(),
        _category = categoryRepository ?? CategoryRepository(),
        _hours = businessHoursRepository ?? BusinessHoursRepository(),
        _links = businessLinksRepository ?? BusinessLinksRepository(),
        _menu = menuRepository ?? MenuRepository(),
        _deals = dealsRepository ?? DealsRepository(),
        _punchCards = punchCardProgramsRepository ?? PunchCardProgramsRepository(),
        _userPunchCards = userPunchCardsRepository ?? UserPunchCardsRepository(),
        _events = businessEventsRepository ?? BusinessEventsRepository(),
        _amenities = amenitiesRepository ?? AmenitiesRepository();

  final AuthRepository _auth;
  final BusinessRepository _business;
  final BusinessManagersRepository _businessManagers;
  final CategoryRepository _category;
  final BusinessHoursRepository _hours;
  final BusinessLinksRepository _links;
  final MenuRepository _menu;
  final DealsRepository _deals;
  final PunchCardProgramsRepository _punchCards;
  final UserPunchCardsRepository _userPunchCards;
  final BusinessEventsRepository _events;
  final AmenitiesRepository _amenities;

  bool get useSupabase => SupabaseConfig.isConfigured;

  /// Current user (from profile when signed in). Throws when backend not configured.
  Future<MockUser> getCurrentUser() async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final profile = await _auth.getCurrentProfile();
    if (profile == null) return Future.value(MockUser(displayName: '', email: null, avatarUrl: null, ownedListingIds: []));
    final userId = _auth.currentUserId;
    final ownedListingIds = userId != null
        ? await _businessManagers.listBusinessIdsForUser(userId)
        : <String>[];
    return Future.value(MockUser(
      displayName: profile.displayName ?? profile.email ?? 'User',
      email: profile.email,
      avatarUrl: profile.avatarUrl,
      ownedListingIds: ownedListingIds,
    ));
  }

  /// Featured spots (first N approved businesses).
  Future<List<MockSpot>> getFeaturedSpots() async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final list = await _business.listApproved();
    const limit = 10;
    return list.take(limit).map(_businessToSpot).toList();
  }

  /// Categories with subcategories (from business_categories + subcategories). Includes bucket for amenity filters.
  Future<List<MockCategory>> getCategories() async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final categories = await _category.listCategories();
    final result = <MockCategory>[];
    for (final c in categories) {
      final subs = await _category.listSubcategories(categoryId: c.id);
      final count = await _business.listApproved(categoryId: c.id).then((l) => l.length);
      result.add(MockCategory(
        id: c.id,
        name: c.name,
        iconName: _iconName(c.icon),
        count: count,
        subcategories: subs.map((s) => MockSubcategory(id: s.id, name: s.name)).toList(),
        bucket: c.bucket,
      ));
    }
    return result;
  }

  static String _iconName(String? icon) {
    if (icon == null || icon.isEmpty) return 'store';
    return icon;
  }

  /// All approved listings (for filter count / list).
  Future<List<MockListing>> getListings() async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final list = await _business.listApproved();
    final categories = await _category.listCategories();
    final catMap = {for (final c in categories) c.id: c.name};
    final businessIds = list.map((b) => b.id).toList();
    final amenityNamesByBusiness = await _amenities.getAmenityNamesForBusinesses(businessIds);
    final result = <MockListing>[];
    for (final b in list) {
      final hours = await _hours.getForBusiness(b.id);
      final subIds = await _category.getSubcategoryIdsForBusiness(b.id);
      final amenityNames = amenityNamesByBusiness[b.id] ?? [];
      result.add(await _businessToMockListing(b, hours, subIds.isEmpty ? null : subIds.first, catMap[b.categoryId], amenityNames));
    }
    return result;
  }

  /// One listing by id.
  Future<MockListing?> getListingById(String id) async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final b = await _business.getById(id);
    if (b == null) return null;
    final hours = await _hours.getForBusiness(b.id);
    final subIds = await _category.getSubcategoryIdsForBusiness(b.id);
    final categories = await _category.listCategories();
    String? catName;
    for (final c in categories) {
      if (c.id == b.categoryId) {
        catName = c.name;
        break;
      }
    }
    final amenityNamesMap = await _amenities.getAmenityNamesForBusinesses([b.id]);
    final amenityNames = amenityNamesMap[b.id] ?? [];
    return _businessToMockListing(b, hours, subIds.isEmpty ? null : subIds.first, catName ?? b.categoryId, amenityNames);
  }

  Future<MockListing> _businessToMockListing(Business b, List<BusinessHours> hours, String? subcategoryId, String? categoryName, [List<String> amenityNames = const []]) async {
    final dayRanges = _formatHours(hours);
    final parishIds = await _getParishIdsForBusiness(b.id, b.parish);
    return MockListing(
      id: b.id,
      name: b.name,
      tagline: b.tagline ?? b.name,
      description: b.description ?? '',
      categoryId: b.categoryId,
      categoryName: categoryName ?? b.categoryId,
      address: b.address,
      phone: b.phone,
      website: b.website,
      hours: dayRanges.isEmpty ? null : dayRanges,
      amenities: amenityNames,
      parishId: b.parish,
      parishIds: parishIds,
      subcategoryId: subcategoryId,
      isOpenNow: true,
      isClaimable: b.isClaimable,
      rating: null,
      distanceMiles: null,
      imagePlaceholder: b.logoUrl,
    );
  }

  /// All parish ids for this business (primary + service areas). When no table exists, returns [parish] if set.
  Future<List<String>> _getParishIdsForBusiness(String businessId, String? primaryParish) async {
    if (!useSupabase) throw StateError(kNotConfiguredMessage);
    final extra = await _business.getBusinessParishIds(businessId);
    if (primaryParish == null && extra.isEmpty) return [];
    final set = <String>{...[primaryParish].whereType<String>(), ...extra};
    return set.toList();
  }

  static List<DayHours> _formatHours(List<BusinessHours> hours) {
    return hours.map((h) {
      if (h.isClosed == true) {
        return DayHours(day: _dayDisplayName(h.dayOfWeek), range: 'Closed');
      }
      if (is24Hours(h.openTime, h.closeTime)) {
        return DayHours(day: _dayDisplayName(h.dayOfWeek), range: 'Open 24 hours');
      }
      final open = format24hToAmPm(h.openTime) ?? h.openTime ?? '';
      final close = format24hToAmPm(h.closeTime) ?? h.closeTime ?? '';
      return DayHours(day: _dayDisplayName(h.dayOfWeek), range: '$open – $close');
    }).toList();
  }

  static String _dayDisplayName(String dayOfWeek) {
    if (dayOfWeek.isEmpty) return dayOfWeek;
    return dayOfWeek[0].toUpperCase() + dayOfWeek.substring(1).toLowerCase();
  }

  static MockSpot _businessToSpot(Business b) => MockSpot(
        id: b.id,
        name: b.name,
        subtitle: b.tagline ?? b.name,
        categoryId: b.categoryId,
      );

  /// Filter listings (search, category, subcategory, parish, amenities, dealOnly). Listing with no parish set matches any parish filter.
  Future<List<MockListing>> filterListings(ListingFilters filters, {bool openNowOnly = false}) async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final list = await getListings();
    var result = list.where((l) {
      if (openNowOnly && !l.isOpenNow) return false;
      if (filters.searchQuery.isNotEmpty) {
        final q = filters.searchQuery.toLowerCase().trim();
        final nameMatch = l.name.toLowerCase().contains(q);
        final taglineMatch = l.tagline.toLowerCase().contains(q);
        final categoryMatch = (l.categoryName).toLowerCase().contains(q);
        final descMatch = l.description.isNotEmpty && l.description.toLowerCase().contains(q);
        if (!nameMatch && !taglineMatch && !categoryMatch && !descMatch) return false;
      }
      if (filters.categoryId != null && l.categoryId != filters.categoryId) return false;
      if (filters.subcategoryIds.isNotEmpty && (l.subcategoryId == null || !filters.subcategoryIds.contains(l.subcategoryId))) return false;
      if (filters.parishIds.isNotEmpty && l.parishIds.isNotEmpty && !l.parishIds.any((pid) => filters.parishIds.contains(pid))) return false;
      return true;
    }).toList();
    if (filters.amenityIds.isNotEmpty) {
      final idsWithAmenity = await _amenities.getBusinessIdsWithAnyAmenity(filters.amenityIds);
      result = result.where((l) => idsWithAmenity.contains(l.id)).toList();
    }
    if (filters.dealOnly && result.isNotEmpty) {
      final deals = await getActiveDeals();
      final idsWithDeals = deals.map((d) => d.listingId).toSet();
      result = result.where((l) => idsWithDeals.contains(l.id)).toList();
    }
    if (filters.minRating != null) {
      result = result.where((l) => l.rating != null && l.rating! >= filters.minRating!).toList();
    }
    if (filters.maxDistanceMiles != null) {
      result = result.where((l) =>
          l.distanceMiles != null && l.distanceMiles! <= filters.maxDistanceMiles!).toList();
    }
    return result;
  }

  Future<List<MockMenuItem>> getMenuForListing(String listingId) async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final sections = await _menu.getSectionsForBusiness(listingId);
    final items = <MockMenuItem>[];
    for (final s in sections) {
      final sectionItems = await _menu.getItemsForSection(s.id);
      for (final i in sectionItems) {
        items.add(MockMenuItem(
          listingId: listingId,
          name: i.name,
          price: i.price,
          description: i.description,
          section: s.name,
        ));
      }
    }
    return items;
  }

  Future<List<MockSocialLink>> getSocialLinksForListing(String listingId) async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final list = await _links.getForBusiness(listingId);
    return list.map((l) => MockSocialLink(listingId: listingId, url: l.url, label: l.label, type: 'custom')).toList();
  }

  Future<List<MockDeal>> getDealsForListing(String listingId) async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final list = await _deals.listApproved(businessId: listingId, activeOnly: true);
    return list.map(_dealToMock).toList();
  }

  /// Single deal by id (approved only). For My deals and detail. Null if not found.
  Future<MockDeal?> getDealById(String dealId) async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final deal = await _deals.getById(dealId);
    if (deal == null) return null;
    return _dealToMock(deal);
  }

  /// Owner/manager: all deals for a listing (any status) for edit screen.
  Future<List<MockDeal>> getDealsForListingForOwner(String listingId) async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final list = await _deals.listForBusiness(listingId);
    return list.map(_dealToMock).toList();
  }

  /// Events for a business (manager view: all statuses including pending).
  Future<List<MockEvent>> getEventsForListing(String listingId) async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final list = await _events.listForBusiness(listingId);
    return list.map(_eventToMock).toList();
  }

  /// Approved events for a listing (public/customer view).
  Future<List<MockEvent>> getApprovedEventsForListing(String listingId) async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final list = await _events.listApproved(businessId: listingId);
    return list.map(_eventToMock).toList();
  }

  Future<List<MockPunchCard>> getPunchCardsForListing(String listingId) async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final programs = await _punchCards.listActive(businessId: listingId);
    final uid = _auth.currentUserId;
    if (uid == null) return programs.map((p) => _punchToMock(p)).toList();
    final enrollments = await _userPunchCards.listForCurrentUser();
    final byProgram = {for (var e in enrollments) e.programId: e};
    return programs.map((p) {
      final en = byProgram[p.id];
      return _punchToMock(p, enrollment: en);
    }).toList();
  }

  Future<List<MockDeal>> getActiveDeals() async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final list = await _deals.listApproved(activeOnly: true);
    return list.map(_dealToMock).toList();
  }

  /// Active deals filtered by preferred parishes, optional category, and optional deal type.
  /// [parishIds] empty = no parish filter (show all). [categoryId] null = all categories. [dealType] null = all types.
  Future<List<MockDeal>> getActiveDealsFiltered({
    required Set<String> parishIds,
    String? categoryId,
    String? dealType,
  }) async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final filters = ListingFilters(parishIds: parishIds, categoryId: categoryId);
    final listings = await filterListings(filters);
    final allowedIds = listings.map((l) => l.id).toSet();
    final allDeals = await getActiveDeals();
    return allDeals.where((d) {
      if (!allowedIds.contains(d.listingId)) return false;
      if (dealType != null && d.dealType != null && d.dealType != dealType) return false;
      return true;
    }).toList();
  }

  Future<List<MockPunchCard>> getActivePunchCards() async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final programs = await _punchCards.listActive();
    final uid = _auth.currentUserId;
    if (uid == null) return programs.map((p) => _punchToMock(p)).toList();
    final enrollments = await _userPunchCards.listForCurrentUser();
    final byProgram = {for (var e in enrollments) e.programId: e};
    return programs.map((p) {
      final en = byProgram[p.id];
      return _punchToMock(p, enrollment: en);
    }).toList();
  }

  /// Active punch cards filtered by parish and category (via business), like getActiveDealsFiltered.
  Future<List<MockPunchCard>> getActivePunchCardsFiltered({
    required Set<String> parishIds,
    String? categoryId,
  }) async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final filters = ListingFilters(parishIds: parishIds, categoryId: categoryId);
    final listings = await filterListings(filters);
    final allowedIds = listings.map((l) => l.id).toSet();
    final all = await getActivePunchCards();
    return all.where((p) => allowedIds.contains(p.listingId)).toList();
  }

  /// List current user's punch card enrollments with program details (for "My punch cards").
  Future<List<MockPunchCard>> getMyPunchCards() async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    final enrollments = await _userPunchCards.listForCurrentUser();
    if (enrollments.isEmpty) return [];
    final programs = await _punchCards.listActive();
    final byId = {for (var p in programs) p.id: p};
    return enrollments.map((e) {
      final p = byId[e.programId];
      if (p == null) return null;
      return MockPunchCard(
        id: p.id,
        listingId: p.businessId,
        title: p.title ?? 'Punch card',
        rewardDescription: p.rewardDescription,
        punchesRequired: p.punchesRequired,
        punchesEarned: e.currentPunches,
        isActive: p.isActive != false,
        isRedeemed: e.isRedeemed,
        userPunchCardId: e.id,
      );
    }).whereType<MockPunchCard>().toList();
  }

  static MockDeal _dealToMock(Deal d) => MockDeal(
        id: d.id,
        listingId: d.businessId,
        title: d.title,
        description: d.description ?? '',
        discount: _dealTypeDisplayLabel(d.dealType),
        code: null,
        expiry: d.endDate,
        isActive: d.isActive == true,
        dealType: d.dealType,
      );

  static String _dealTypeDisplayLabel(String type) {
    switch (type) {
      case 'percentage':
        return 'Percentage off';
      case 'fixed':
        return 'Fixed off';
      case 'bogo':
        return 'BOGO';
      case 'freebie':
        return 'Freebie';
      case 'flash':
        return 'Flash';
      case 'member_only':
        return 'Member only';
      default:
        return type;
    }
  }

  static MockEvent _eventToMock(BusinessEvent e) => MockEvent(
        id: e.id,
        listingId: e.businessId,
        title: e.title,
        eventDate: e.eventDate,
        description: e.description,
        endDate: e.endDate,
        location: e.location,
        imageUrl: e.imageUrl,
        status: e.status,
      );

  static MockPunchCard _punchToMock(PunchCardProgram p, {UserPunchCard? enrollment}) {
    final en = enrollment;
    return MockPunchCard(
      id: p.id,
      listingId: p.businessId,
      title: p.title ?? 'Punch card',
      rewardDescription: p.rewardDescription,
      punchesRequired: p.punchesRequired,
      punchesEarned: en?.currentPunches ?? 0,
      isActive: p.isActive != false,
      isRedeemed: en?.isRedeemed ?? false,
      userPunchCardId: en?.id,
    );
  }

  /// Allowed parishes (from DB when configured). Falls back to [MockData.parishes] when not configured, DB empty, or on error.
  Future<List<MockParish>> getParishes() async {
    if (!useSupabase) return List<MockParish>.from(MockData.parishes);
    try {
      final list = await ParishRepository().listParishes();
      if (list.isEmpty) return List<MockParish>.from(MockData.parishes);
      return list.map((p) => MockParish(id: p.id, name: p.name)).toList();
    } catch (_) {
      return List<MockParish>.from(MockData.parishes);
    }
  }

  /// Subcategory IDs assigned to this business.
  Future<List<String>> getSubcategoryIdsForBusiness(String businessId) async {
    if (!useSupabase) return Future.error(StateError(kNotConfiguredMessage));
    return _category.getSubcategoryIdsForBusiness(businessId);
  }

  /// Update business profile. Only provided fields are updated.
  Future<void> updateBusiness(
    String id, {
    String? name,
    String? tagline,
    String? categoryId,
    String? address,
    String? city,
    String? parish,
    String? state,
    String? phone,
    String? website,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    double? latitude,
    double? longitude,
    List<String>? parishIds,
  }) async {
    if (!useSupabase) throw StateError(kNotConfiguredMessage);
    await _business.updateBusiness(
      id,
      name: name,
      tagline: tagline,
      categoryId: categoryId,
      address: address,
      city: city,
      parish: parish,
      state: state,
      phone: phone,
      website: website,
      description: description,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      latitude: latitude,
      longitude: longitude,
    );
    if (parishIds != null) await _business.setBusinessParishes(id, parishIds);
  }

  /// Set subcategories for a business. Replaces existing.
  Future<void> setBusinessSubcategories(String businessId, List<String> subcategoryIds) async {
    if (!useSupabase) throw StateError(kNotConfiguredMessage);
    await _business.setBusinessSubcategories(businessId, subcategoryIds);
  }
}
