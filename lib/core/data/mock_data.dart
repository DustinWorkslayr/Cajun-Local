/// Mock data for Cajun Local (no backend yet).

/// Filter state for listings (search, category, subcategories, parishes).
class ListingFilters {
  const ListingFilters({
    this.searchQuery = '',
    this.categoryId,
    this.subcategoryIds = const {},
    this.parishIds = const {},
  });

  final String searchQuery;
  final String? categoryId;
  final Set<String> subcategoryIds;
  final Set<String> parishIds;

  ListingFilters copyWith({
    String? searchQuery,
    Object? categoryId = _unchanged,
    Set<String>? subcategoryIds,
    Set<String>? parishIds,
  }) {
    return ListingFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryId: categoryId == _unchanged ? this.categoryId : categoryId as String?,
      subcategoryIds: subcategoryIds ?? this.subcategoryIds,
      parishIds: parishIds ?? this.parishIds,
    );
  }
}

const _unchanged = Object();

class MockSubcategory {
  const MockSubcategory({required this.id, required this.name});
  final String id;
  final String name;
}

class MockCategory {
  const MockCategory({
    required this.id,
    required this.name,
    required this.iconName,
    this.count = 0,
    this.subcategories = const [],
  });
  final String id;
  final String name;
  final String iconName;
  final int count;
  final List<MockSubcategory> subcategories;
}

class MockParish {
  const MockParish({required this.id, required this.name});
  final String id;
  final String name;
}

class MockSpot {
  const MockSpot({
    required this.id,
    required this.name,
    required this.subtitle,
    this.categoryId,
  });
  final String id;
  final String name;
  final String subtitle;
  final String? categoryId;
}

/// Coupon or deal offered by a business. Only active deals shown on Deals page.
class MockDeal {
  const MockDeal({
    required this.id,
    required this.listingId,
    required this.title,
    required this.description,
    this.discount,
    this.code,
    this.expiry,
    this.isActive = true,
  });
  final String id;
  final String listingId;
  final String title;
  final String description;
  final String? discount;
  final String? code;
  final DateTime? expiry;
  final bool isActive;
}

/// Loyalty punch card: earn punches toward a reward. Only active cards shown.
class MockPunchCard {
  const MockPunchCard({
    required this.id,
    required this.listingId,
    required this.title,
    required this.rewardDescription,
    required this.punchesRequired,
    this.punchesEarned = 0,
    this.isActive = true,
  });
  final String id;
  final String listingId;
  final String title;
  final String rewardDescription;
  final int punchesRequired;
  final int punchesEarned;
  final bool isActive;
}

/// Full business listing for detail page.
class MockListing {
  const MockListing({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    this.address,
    this.phone,
    this.website,
    this.hours,
    this.amenities = const [],
    this.imagePlaceholder,
    this.parishId,
    this.subcategoryId,
    this.isOpenNow = true,
  });
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String categoryId;
  final String categoryName;
  final String? address;
  final String? phone;
  final String? website;
  final List<DayHours>? hours;
  final List<String> amenities;
  final String? imagePlaceholder;
  final String? parishId;
  final String? subcategoryId;
  /// Mock: true if business is currently open (for "Open now" filter).
  final bool isOpenNow;
}

class DayHours {
  const DayHours({required this.day, required this.range});
  final String day;
  final String range;
}

/// Menu item for a listing (e.g. food/drink).
class MockMenuItem {
  const MockMenuItem({
    required this.listingId,
    required this.name,
    this.price,
    this.description,
    this.section,
  });
  final String listingId;
  final String name;
  final String? price;
  final String? description;
  final String? section;
}

/// Social or custom URL link for a listing.
class MockSocialLink {
  const MockSocialLink({
    required this.listingId,
    required this.url,
    this.type = 'custom',
    this.label,
  });
  final String listingId;
  final String url;
  final String type;
  final String? label;
}

class MockUser {
  const MockUser({
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.ownedListingIds = const [],
  });
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final List<String> ownedListingIds;
}

abstract class MockData {
  static const MockUser currentUser = MockUser(
    displayName: 'Cajun Explorer',
    email: 'explorer@cajunlocal.app',
    ownedListingIds: ['1'],
  );

  static const List<MockMenuItem> menuItems = [
    MockMenuItem(listingId: '1', section: 'Mains', name: 'Gumbo', price: '\$12', description: 'Chicken & andouille, dark roux'),
    MockMenuItem(listingId: '1', section: 'Mains', name: 'Po\'boy', price: '\$14', description: 'Fried shrimp or catfish, dressed'),
    MockMenuItem(listingId: '1', section: 'Mains', name: 'Crawfish étouffée', price: '\$16', description: 'Served with rice'),
    MockMenuItem(listingId: '1', section: 'Sides', name: 'Red beans & rice', price: '\$6', description: null),
    MockMenuItem(listingId: '1', section: 'Sides', name: 'Hush puppies', price: '\$5', description: null),
    MockMenuItem(listingId: '2', section: 'Bar', name: 'House cocktails', price: '\$10', description: null),
    MockMenuItem(listingId: '2', section: 'Bar', name: 'Louisiana craft beer', price: '\$6', description: null),
  ];

  static const List<MockSocialLink> socialLinks = [
    MockSocialLink(listingId: '1', type: 'facebook', url: 'https://facebook.com/bayoubites'),
    MockSocialLink(listingId: '1', type: 'instagram', url: 'https://instagram.com/bayoubites'),
    MockSocialLink(listingId: '2', type: 'facebook', url: 'https://facebook.com/zydecohall'),
    MockSocialLink(listingId: '2', type: 'instagram', url: 'https://instagram.com/zydecohall'),
    MockSocialLink(listingId: '3', type: 'custom', url: 'https://cajunspicemarket.com/events', label: 'Events'),
  ];

  static const List<MockCategory> categories = [
    MockCategory(
      id: 'food',
      name: 'Restaurants',
      iconName: 'restaurant',
      count: 31,
      subcategories: [
        MockSubcategory(id: 'cajun', name: 'Cajun'),
        MockSubcategory(id: 'creole', name: 'Creole'),
        MockSubcategory(id: 'seafood', name: 'Seafood'),
        MockSubcategory(id: 'poboys', name: 'Po\'boys & Sandwiches'),
      ],
    ),
    MockCategory(
      id: 'coffee',
      name: 'Coffee & Cafe',
      iconName: 'local_cafe',
      count: 9,
      subcategories: [
        MockSubcategory(id: 'coffee_shop', name: 'Coffee shop'),
        MockSubcategory(id: 'bakery', name: 'Bakery & pastries'),
      ],
    ),
    MockCategory(
      id: 'music',
      name: 'Music & Events',
      iconName: 'music_note',
      count: 12,
      subcategories: [
        MockSubcategory(id: 'zydeco', name: 'Zydeco'),
        MockSubcategory(id: 'cajun_music', name: 'Cajun'),
        MockSubcategory(id: 'live_band', name: 'Live band'),
      ],
    ),
    MockCategory(id: 'shops', name: 'Shopping', iconName: 'store', count: 13),
    MockCategory(id: 'outdoors', name: 'Outdoors', iconName: 'terrain', count: 8),
  ];

  static const List<MockParish> parishes = [
    MockParish(id: 'lafayette', name: 'Lafayette'),
    MockParish(id: 'acadia', name: 'Acadia'),
    MockParish(id: 'jefferson', name: 'Jefferson'),
    MockParish(id: 'orleans', name: 'Orleans'),
    MockParish(id: 'st_martin', name: 'St. Martin'),
    MockParish(id: 'vermilion', name: 'Vermilion'),
    MockParish(id: 'iberia', name: 'Iberia'),
    MockParish(id: 'st_landry', name: 'St. Landry'),
    MockParish(id: 'calcasieu', name: 'Calcasieu'),
  ];

  static const List<MockSpot> featuredSpots = [
    MockSpot(id: '1', name: 'Bayou Bites', subtitle: 'Authentic gumbo & po\'boys', categoryId: 'food'),
    MockSpot(id: '2', name: 'Zydeco Hall', subtitle: 'Live music & dancing', categoryId: 'music'),
    MockSpot(id: '3', name: 'Cajun Spice Market', subtitle: 'Local spices & crafts', categoryId: 'shops'),
  ];

  static const List<MockListing> listings = [
    MockListing(
      id: '1',
      name: 'Bayou Bites',
      tagline: 'Authentic gumbo & po\'boys',
      description:
          'Family-owned since 1982. We slow-simmer our roux for hours and source crawfish from the Atchafalaya. '
          'Dine in our restored Creole cottage or on the patio overlooking the bayou.',
      categoryId: 'food',
      categoryName: 'Food & Dining',
      address: '412 Bayou Teche Rd, Lafayette, LA 70501',
      phone: '(337) 555-0142',
      website: 'bayoubites.com',
      hours: [
        DayHours(day: 'Mon – Thu', range: '11:00 AM – 9:00 PM'),
        DayHours(day: 'Fri – Sat', range: '11:00 AM – 10:00 PM'),
        DayHours(day: 'Sun', range: '12:00 PM – 8:00 PM'),
      ],
      amenities: ['Outdoor seating', 'Live music (Fri–Sat)', 'Takeout', 'Wheelchair accessible'],
      parishId: 'lafayette',
      subcategoryId: 'cajun',
      isOpenNow: true,
    ),
    MockListing(
      id: '2',
      name: 'Zydeco Hall',
      tagline: 'Live music & dancing',
      description:
          'The heart of Cajun and zydeco in the region. Two-step and waltz on our maple dance floor, '
          'catch touring bands and local legends, and enjoy a full bar and Louisiana comfort plates.',
      categoryId: 'music',
      categoryName: 'Music & Events',
      address: '200 Festival Way, Lafayette, LA 70506',
      phone: '(337) 555-0198',
      website: 'zydecohall.com',
      hours: [
        DayHours(day: 'Thu – Sat', range: '6:00 PM – 2:00 AM'),
        DayHours(day: 'Sun', range: '4:00 PM – 12:00 AM'),
      ],
      amenities: ['Dance floor', 'Full bar', 'Event rental', 'Food available'],
      parishId: 'lafayette',
      subcategoryId: 'zydeco',
      isOpenNow: true,
    ),
    MockListing(
      id: '3',
      name: 'Cajun Spice Market',
      tagline: 'Local spices & crafts',
      description:
          'Curated selection of Cajun and Creole spices, hot sauces, and artisan crafts from Louisiana makers. '
          'Tastings and gift boxes available. Your one stop for authentic flavor to take home.',
      categoryId: 'shops',
      categoryName: 'Local Shops',
      address: '101 Main St, Breaux Bridge, LA 70517',
      phone: '(337) 555-0221',
      website: 'cajunspicemarket.com',
      hours: [
        DayHours(day: 'Mon – Sat', range: '9:00 AM – 6:00 PM'),
        DayHours(day: 'Sun', range: '10:00 AM – 4:00 PM'),
      ],
      amenities: ['Tastings', 'Gift wrapping', 'Shipping', 'Local art'],
      parishId: 'st_martin',
      subcategoryId: null,
      isOpenNow: false,
    ),
  ];

  static MockListing? getListingById(String id) {
    try {
      return listings.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Filter listings by filters and optional open-now.
  static List<MockListing> filterListings(
    ListingFilters filters, {
    bool openNowOnly = false,
  }) {
    var result = listings.where((l) {
      if (openNowOnly && !l.isOpenNow) return false;
      if (filters.searchQuery.isNotEmpty) {
        final q = filters.searchQuery.toLowerCase();
        if (!l.name.toLowerCase().contains(q) &&
            !l.tagline.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (filters.categoryId != null && l.categoryId != filters.categoryId) {
        return false;
      }
      if (filters.subcategoryIds.isNotEmpty &&
          (l.subcategoryId == null || !filters.subcategoryIds.contains(l.subcategoryId))) {
        return false;
      }
      if (filters.parishIds.isNotEmpty &&
          (l.parishId == null || !filters.parishIds.contains(l.parishId))) {
        return false;
      }
      return true;
    }).toList();
    return result;
  }

  static const List<MockDeal> deals = [
    MockDeal(
      id: 'd1',
      listingId: '1',
      title: '10% off lunch',
      description: 'Valid Monday–Friday 11am–2pm. Dine-in only.',
      discount: '10% off',
      code: 'CAJUN10',
      isActive: true,
    ),
    MockDeal(
      id: 'd2',
      listingId: '1',
      title: 'Free dessert with entrée',
      description: 'Order any entrée and get a slice of bread pudding or pecan pie on the house.',
      discount: 'Free dessert',
      isActive: true,
    ),
    MockDeal(
      id: 'd3',
      listingId: '2',
      title: 'Cover charge waived',
      description: 'Show this deal at the door for no cover on Thursday nights.',
      discount: 'No cover',
      code: 'ZYDECO',
      isActive: true,
    ),
    MockDeal(
      id: 'd4',
      listingId: '3',
      title: '15% off first purchase',
      description: 'First-time visitors get 15% off any purchase over \$20.',
      discount: '15% off',
      code: 'SPICE15',
      isActive: true,
    ),
  ];

  static const List<MockPunchCard> punchCards = [
    MockPunchCard(
      id: 'p1',
      listingId: '1',
      title: 'Bayou Bites loyalty',
      rewardDescription: 'Free gumbo after 8 visits',
      punchesRequired: 8,
      punchesEarned: 3,
      isActive: true,
    ),
    MockPunchCard(
      id: 'p2',
      listingId: '2',
      title: 'Zydeco regular',
      rewardDescription: 'Free entry after 5 paid covers',
      punchesRequired: 5,
      punchesEarned: 2,
      isActive: true,
    ),
    MockPunchCard(
      id: 'p3',
      listingId: '3',
      title: 'Spice Market rewards',
      rewardDescription: 'Free small hot sauce after 4 purchases',
      punchesRequired: 4,
      punchesEarned: 0,
      isActive: true,
    ),
  ];

  static List<MockDeal> get activeDeals =>
      deals.where((d) => d.isActive).toList();

  static List<MockPunchCard> get activePunchCards =>
      punchCards.where((p) => p.isActive).toList();

  /// In-memory user-created items (not persisted). Merged with static data in getters.
  static final List<MockDeal> _userDeals = [];
  static final List<MockPunchCard> _userPunchCards = [];
  static final List<MockMenuItem> _userMenuItems = [];

  static List<MockDeal> getDealsForListing(String listingId) {
    final fromStatic = deals.where((d) => d.listingId == listingId && d.isActive).toList();
    final fromUser = _userDeals.where((d) => d.listingId == listingId && d.isActive).toList();
    return [...fromStatic, ...fromUser];
  }

  static List<MockPunchCard> getPunchCardsForListing(String listingId) {
    final fromStatic = punchCards.where((p) => p.listingId == listingId && p.isActive).toList();
    final fromUser = _userPunchCards.where((p) => p.listingId == listingId && p.isActive).toList();
    return [...fromStatic, ...fromUser];
  }

  static List<MockMenuItem> getMenuForListing(String listingId) {
    final fromStatic = menuItems.where((m) => m.listingId == listingId).toList();
    final fromUser = _userMenuItems.where((m) => m.listingId == listingId).toList();
    return [...fromStatic, ...fromUser];
  }

  static void addDeal(MockDeal deal) => _userDeals.add(deal);
  static void addPunchCard(MockPunchCard card) => _userPunchCards.add(card);
  static void addMenuItem(MockMenuItem item) => _userMenuItems.add(item);

  static List<MockSocialLink> getSocialLinksForListing(String listingId) =>
      socialLinks.where((s) => s.listingId == listingId).toList();
}
