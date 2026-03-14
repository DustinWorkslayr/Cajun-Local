import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';

import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/models/business_claim.dart';
import 'package:cajun_local/features/businesses/data/models/business_image.dart';
import 'package:cajun_local/features/businesses/data/models/menu_item.dart';
import 'package:cajun_local/features/businesses/data/models/business_link.dart';
import 'package:cajun_local/features/businesses/data/models/business_hours.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_claims_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_images_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_hours_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_subscriptions_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/menu_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_links_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_managers_repository.dart';

import 'package:cajun_local/features/deals/data/models/deal.dart';
import 'package:cajun_local/features/deals/data/models/punch_card_program.dart';
import 'package:cajun_local/features/deals/data/repositories/deals_repository.dart';
import 'package:cajun_local/features/deals/data/repositories/punch_card_programs_repository.dart';

import 'package:cajun_local/features/events/data/models/business_event.dart';
import 'package:cajun_local/features/events/data/repositories/business_events_repository.dart';

import 'package:cajun_local/features/favorites/data/repositories/favorites_repository.dart';
import 'package:cajun_local/features/reviews/data/models/review.dart';
import 'package:cajun_local/features/reviews/data/repositories/reviews_repository.dart';

part 'listing_detail_provider.g.dart';

/// Loaded data for listing detail (from data source or mock).
class ListingDetailData {
  const ListingDetailData({
    required this.listing,
    required this.menuItems,
    required this.socialLinks,
    required this.deals,
    required this.punchCards,
    required this.events,
    this.bannerImageUrl,
    this.logoUrl,
    this.imageUrls = const [],
    this.userClaim,
    this.isPartner = false,
    this.isOwnerOrManager = false,
    this.contactFormTemplate,
    this.favoritesCount = 0,
    this.reviews = const [],
    this.averageRating = 0,
    this.reviewCount = 0,
    this.subscriptionTier,
    this.distanceMi,
    this.listingLatitude,
    this.listingLongitude,
    this.businessHours = const [],
  });
  final Business listing;
  final List<MenuItem> menuItems;
  final List<BusinessLink> socialLinks;
  final List<Deal> deals;
  final List<PunchCardProgram> punchCards;
  final List<BusinessEvent> events;

  /// First approved business image URL (banner). Used for free tier.
  final String? bannerImageUrl;

  /// Business logo URL. Shown in hero for free tier.
  final String? logoUrl;

  /// All approved business image URLs. Carousel for partner tier.
  final List<String> imageUrls;

  /// Current user's claim for this business (pending or approved), if any.
  final BusinessClaim? userClaim;

  /// True when business has paid/partner tier — show carousel and Partner badge.
  final bool isPartner;

  /// True when current user is owner/manager of this listing — show Edit listing.
  final bool isOwnerOrManager;

  /// Contact form template key (e.g. general_inquiry, appointment_request). Null = no form.
  final String? contactFormTemplate;

  /// Total number of users who favorited this listing.
  final int favoritesCount;

  /// Approved reviews for this business.
  final List<Review> reviews;

  /// Average rating (1–5) from approved reviews.
  final double averageRating;

  /// Number of approved reviews.
  final int reviewCount;

  /// Plan tier for badge (e.g. local_plus, local_partner).
  final String? subscriptionTier;

  /// Distance from user in miles (null if unknown).
  final double? distanceMi;

  /// Listing coordinates for map preview (from business when Supabase).
  final double? listingLatitude;
  final double? listingLongitude;
  final List<BusinessHours> businessHours;
}

@riverpod
class ListingDetailController extends _$ListingDetailController {
  @override
  FutureOr<ListingDetailData?> build(String listingId) async {
    return _fetchListing(listingId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchListing(listingId));
  }

  Future<ListingDetailData?> _fetchListing(String id) async {
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    final favRepo = ref.read(favoritesRepositoryProvider);

    final businessRepo = BusinessRepository();
    final listing = await businessRepo.getById(id);
    if (listing == null) return null;

    final menuRepo = ref.read(menuRepositoryProvider);
    final linksRepo = ref.read(businessLinksRepositoryProvider);
    final dealsRepo = ref.read(dealsRepositoryProvider);
    final punchRepo = ref.read(punchCardProgramsRepositoryProvider);
    final eventsRepo = ref.read(businessEventsRepositoryProvider);
    final imagesRepo = ref.read(businessImagesRepositoryProvider);
    final hoursRepo = ref.read(businessHoursRepositoryProvider);
    final subsRepo = ref.read(businessSubscriptionsRepositoryProvider);
    final reviewRepo = ReviewsRepository();
    final claimsRepo = ref.read(businessClaimsRepositoryProvider);
    final managersRepo = ref.read(businessManagersRepositoryProvider);

    // Run all independent fetches in parallel for faster load.
    final futures = <Future<dynamic>>[
      menuRepo.getSectionsForBusiness(id).then((sections) async {
        final items = <MenuItem>[];
        for (final sec in sections) {
          final secItems = await menuRepo.getItemsForSection(sec.id);
          items.addAll(secItems);
        }
        return items;
      }),
      linksRepo.getForBusiness(id),
      dealsRepo.listApproved(businessId: id, activeOnly: true),
      punchRepo.listActive(businessId: id),
      eventsRepo.listApproved(businessId: id),
      imagesRepo.getApprovedForBusiness(id),
      hoursRepo.getForBusiness(id),
      subsRepo.getByBusinessId(id),
      favRepo.getCountForBusiness(id),
      reviewRepo.listForAdmin(businessId: id, status: 'approved'),
    ];

    if (userId != null) {
      futures.add(claimsRepo.getForUserAndBusiness(userId, id));
      futures.add(managersRepo.listBusinessIdsForUser(userId));
    }

    final results = await Future.wait(futures);
    int i = 0;
    final menuItems = results[i++] as List<MenuItem>;
    final socialLinks = results[i++] as List<BusinessLink>;
    final deals = results[i++] as List<Deal>;
    final punchCards = results[i++] as List<PunchCardProgram>;
    final events = results[i++] as List<BusinessEvent>;
    final images = results[i++] as List<BusinessImage>;
    final businessHours = results[i++] as List<BusinessHours>;
    final sub = results[i++] as dynamic;
    final favoritesCount = results[i++] as int;
    final reviews = results[i++] as List<Review>;

    BusinessClaim? userClaim;
    bool isOwnerOrManager = false;
    if (userId != null) {
      userClaim = results[i++] as BusinessClaim?;
      final managedIds = results[i++] as List<String>;
      isOwnerOrManager = managedIds.contains(id);
    }

    final imageUrls = images.map((e) => e.url).toList();
    final bannerImageUrl = listing.bannerUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : null);
    final logoUrl = listing.logoUrl;
    final String? subscriptionTier = sub?.planTier as String?;
    final bool isPartner = (subscriptionTier?.toLowerCase() == 'enterprise');

    double averageRating = 0;
    if (reviews.isNotEmpty) {
      final sum = reviews.fold<int>(0, (s, r) => s + r.rating);
      averageRating = sum / reviews.length;
    }

    return ListingDetailData(
      listing: listing,
      menuItems: menuItems,
      socialLinks: socialLinks,
      deals: deals,
      punchCards: punchCards,
      events: events,
      bannerImageUrl: bannerImageUrl,
      logoUrl: logoUrl,
      imageUrls: imageUrls,
      userClaim: userClaim,
      isPartner: isPartner,
      isOwnerOrManager: isOwnerOrManager,
      contactFormTemplate: listing.contactFormTemplate,
      favoritesCount: favoritesCount,
      reviews: reviews,
      averageRating: averageRating,
      reviewCount: reviews.length,
      subscriptionTier: subscriptionTier,
      distanceMi: null,
      listingLatitude: listing.latitude,
      listingLongitude: listing.longitude,
      businessHours: businessHours,
    );
  }
}
