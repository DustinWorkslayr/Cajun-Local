/// Mock data for Cajun Local (no backend yet).
library;

// Classes for deals/punchcards remain for now as they haven't been refactored to Freezed yet.

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
    this.dealType,
  });
  final String id;
  final String listingId;
  final String title;
  final String description;
  final String? discount;
  final String? code;
  final DateTime? expiry;
  final bool isActive;
  /// Backend deal_type (percentage, fixed, bogo, freebie, other, flash, member_only). Used for filtering.
  final String? dealType;
}

/// Loyalty punch card: earn punches toward a reward. Only active cards shown.
/// When from backend + user enrolled: punchesEarned, isRedeemed, userPunchCardId are set.
class MockPunchCard {
  const MockPunchCard({
    required this.id,
    required this.listingId,
    required this.title,
    required this.rewardDescription,
    required this.punchesRequired,
    this.punchesEarned = 0,
    this.isActive = true,
    this.isRedeemed = false,
    this.userPunchCardId,
  });
  final String id;
  final String listingId;
  final String title;
  final String rewardDescription;
  final int punchesRequired;
  final int punchesEarned;
  final bool isActive;
  /// True when user has redeemed the reward (server-side only).
  final bool isRedeemed;
  /// When non-null, user is enrolled; use for "Show QR" or my-cards.
  final String? userPunchCardId;
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

  static const List<MockDeal> deals = [
    MockDeal(
      id: 'd1',
      listingId: '1',
      title: '10% off lunch',
      description: 'Valid Monday–Friday 11am–2pm. Dine-in only.',
      discount: '10% off',
      code: 'CAJUN10',
      isActive: true,
      dealType: 'percentage',
    ),
    MockDeal(
      id: 'd2',
      listingId: '1',
      title: 'Free dessert with entrée',
      description: 'Order any entrée and get a slice of bread pudding or pecan pie on the house.',
      discount: 'Free dessert',
      isActive: true,
      dealType: 'freebie',
    ),
    MockDeal(
      id: 'd3',
      listingId: '2',
      title: 'Cover charge waived',
      description: 'Show this deal at the door for no cover on Thursday nights.',
      discount: 'No cover',
      code: 'ZYDECO',
      isActive: true,
      dealType: 'other',
    ),
    MockDeal(
      id: 'd4',
      listingId: '3',
      title: '15% off first purchase',
      description: 'First-time visitors get 15% off any purchase over \$20.',
      discount: '15% off',
      code: 'SPICE15',
      isActive: true,
      dealType: 'percentage',
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

  static List<MockDeal> getDealsForListing(String listingId) {
    return deals.where((d) => d.listingId == listingId && d.isActive).toList();
  }

  static List<MockPunchCard> getPunchCardsForListing(String listingId) {
    return punchCards.where((p) => p.listingId == listingId && p.isActive).toList();
  }

  static List<MockMenuItem> getMenuForListing(String listingId) {
    return menuItems.where((m) => m.listingId == listingId).toList();
  }

  static List<MockSocialLink> getSocialLinksForListing(String listingId) =>
      socialLinks.where((s) => s.listingId == listingId).toList();
}
