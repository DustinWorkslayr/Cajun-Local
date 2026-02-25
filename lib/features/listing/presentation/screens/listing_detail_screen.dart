import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/listing_data_source.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/models/user_deal.dart';
import 'package:my_app/core/data/models/business_claim.dart';
import 'package:my_app/core/data/repositories/business_claims_repository.dart';
import 'package:my_app/core/data/repositories/business_managers_repository.dart';
import 'package:my_app/core/data/repositories/favorites_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/services/send_email_service.dart';
import 'package:my_app/core/data/models/review.dart';
import 'package:my_app/core/data/repositories/business_images_repository.dart';
import 'package:my_app/core/data/repositories/business_subscriptions_repository.dart';
import 'package:my_app/core/data/repositories/reviews_repository.dart';
import 'package:my_app/core/data/repositories/event_rsvps_repository.dart';
import 'package:my_app/core/data/repositories/user_deals_repository.dart';
import 'package:my_app/core/data/repositories/user_punch_cards_repository.dart';
import 'package:my_app/core/favorites/favorites_scope.dart';
import 'package:my_app/core/subscription/resolved_permissions.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/subscription_upsell_popup.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/listing/presentation/screens/claim_business_screen.dart';
import 'package:my_app/features/my_listings/presentation/screens/listing_edit_screen.dart';
import 'package:my_app/core/data/contact_form_templates.dart';
import 'package:my_app/features/messaging/presentation/screens/conversation_thread_screen.dart';
import 'package:my_app/shared/widgets/contact_form_widget.dart';
import 'package:my_app/shared/widgets/deal_detail_popup.dart';
import 'package:my_app/shared/widgets/punch_qr_sheet.dart';

/// Loaded data for listing detail (from data source or mock).
class _DetailData {
  const _DetailData({
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
  });
  final MockListing listing;
  final List<MockMenuItem> menuItems;
  final List<MockSocialLink> socialLinks;
  final List<MockDeal> deals;
  final List<MockPunchCard> punchCards;
  final List<MockEvent> events;
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
}

/// Elegant, futuristic business listing detail page.
class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return _ListingDetailBody(listingId: listingId);
  }
}

class _ListingDetailBody extends StatefulWidget {
  const _ListingDetailBody({required this.listingId});
  final String listingId;

  @override
  State<_ListingDetailBody> createState() => _ListingDetailBodyState();
}

class _ListingDetailBodyState extends State<_ListingDetailBody> {
  Future<_DetailData?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future == null) {
      final scope = AppDataScope.of(context);
      _future = _load(scope.dataSource, scope.authRepository.currentUserId, scope.favoritesRepository);
      setState(() {}); // Rebuild so FutureBuilder receives the future and shows loading/content
    }
  }

  Future<_DetailData?> _load(ListingDataSource ds, String? userId, FavoritesRepository favRepo) async {
    final listing = await ds.getListingById(widget.listingId);
    if (listing == null) return null;
    String? bannerImageUrl;
    String? logoUrl;
    List<String> imageUrls = const [];
    BusinessClaim? userClaim;
    bool isPartner = false;
    String? contactFormTemplate;
    double? listingLatitude;
    double? listingLongitude;
    if (ds.useSupabase) {
      final business = await BusinessRepository().getByIdForAdmin(widget.listingId);
      logoUrl = business?.logoUrl;
      contactFormTemplate = business?.contactFormTemplate;
      listingLatitude = business?.latitude;
      listingLongitude = business?.longitude;
      final images = await BusinessImagesRepository().getApprovedForBusiness(widget.listingId);
      imageUrls = images.map((e) => e.url).toList();
      bannerImageUrl = business?.bannerUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : null);
      if (userId != null) {
        userClaim = await BusinessClaimsRepository().getForUserAndBusiness(userId, widget.listingId);
      }
      isPartner = await BusinessSubscriptionsRepository().isPartnerBusiness(widget.listingId);
    }
    int favoritesCount = 0;
    if (ds.useSupabase) {
      favoritesCount = await favRepo.getCountForBusiness(widget.listingId);
    }
    List<Review> reviews = const [];
    double averageRating = 0;
    int reviewCount = 0;
    String? subscriptionTier;
    if (ds.useSupabase) {
      final reviewsList = await ReviewsRepository().listForAdmin(
        businessId: widget.listingId,
        status: 'approved',
      );
      reviews = reviewsList;
      reviewCount = reviews.length;
      if (reviews.isNotEmpty) {
        final sum = reviews.fold<int>(0, (s, r) => s + r.rating);
        averageRating = sum / reviews.length;
      }
      final sub = await BusinessSubscriptionsRepository().getByBusinessId(widget.listingId);
      subscriptionTier = sub?.planTier;
    }
    final results = await Future.wait([
      ds.getMenuForListing(widget.listingId),
      ds.getSocialLinksForListing(widget.listingId),
      ds.getDealsForListing(widget.listingId),
      ds.getPunchCardsForListing(widget.listingId),
      ds.getApprovedEventsForListing(widget.listingId),
    ]);
    bool isOwnerOrManager = false;
    if (userId != null) {
      final user = await ds.getCurrentUser();
      isOwnerOrManager = user.ownedListingIds.contains(widget.listingId);
    }
    return _DetailData(
      listing: listing,
      menuItems: results[0] as List<MockMenuItem>,
      socialLinks: results[1] as List<MockSocialLink>,
      deals: results[2] as List<MockDeal>,
      punchCards: results[3] as List<MockPunchCard>,
      events: results[4] as List<MockEvent>,
      bannerImageUrl: bannerImageUrl,
      logoUrl: logoUrl,
      imageUrls: imageUrls,
      userClaim: userClaim,
      isPartner: isPartner,
      isOwnerOrManager: isOwnerOrManager,
      contactFormTemplate: contactFormTemplate,
      favoritesCount: favoritesCount,
      reviews: reviews,
      averageRating: averageRating,
      reviewCount: reviewCount,
      subscriptionTier: subscriptionTier,
      distanceMi: null,
      listingLatitude: listingLatitude,
      listingLongitude: listingLongitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DetailData?>(
      future: _future,
      builder: (context, snapshot) {
        // Not started yet (first frame before didChangeDependencies set _future) — show loading
        if (_future == null) {
          return Scaffold(
            backgroundColor: AppTheme.specOffWhite,
            appBar: AppBar(
              title: const Text('Listing'),
              backgroundColor: AppTheme.specOffWhite,
              foregroundColor: AppTheme.specNavy,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.specOffWhite,
            appBar: AppBar(
              title: const Text('Listing'),
              backgroundColor: AppTheme.specOffWhite,
              foregroundColor: AppTheme.specNavy,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.specOffWhite,
            appBar: AppBar(
              title: const Text('Listing'),
              backgroundColor: AppTheme.specOffWhite,
              foregroundColor: AppTheme.specNavy,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Couldn\'t load this listing',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.specNavy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    AppSecondaryButton(
                      onPressed: () {
                        setState(() {
                          final scope = AppDataScope.of(context);
                          _future = _load(scope.dataSource, scope.authRepository.currentUserId, scope.favoritesRepository);
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return Scaffold(
            backgroundColor: AppTheme.specOffWhite,
            appBar: AppBar(
              title: const Text('Listing'),
              backgroundColor: AppTheme.specOffWhite,
              foregroundColor: AppTheme.specNavy,
            ),
            body: const Center(child: Text('Listing not found')),
          );
        }
        final scope = AppDataScope.of(context);
        return _ListingDetailContent(
          data: data,
          isSignedIn: scope.authRepository.currentUserId != null,
          currentUserId: scope.authRepository.currentUserId,
          onReload: () {
            setState(() {
              _future = _load(scope.dataSource, scope.authRepository.currentUserId, scope.favoritesRepository);
            });
          },
        );
      },
    );
  }
}

class _ListingDetailContent extends StatelessWidget {
  const _ListingDetailContent({
    required this.data,
    required this.isSignedIn,
    required this.currentUserId,
    required this.onReload,
  });
  final _DetailData data;
  final bool isSignedIn;
  final String? currentUserId;
  final VoidCallback onReload;

  static const double _heroHeight = 280;
  static const double _contentRadius = 20;

  @override
  Widget build(BuildContext context) {
    final listing = data.listing;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = AppLayout.isTablet(context);
    final padding = AppLayout.horizontalPadding(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.specOffWhite,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildHero(context, listing),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -_contentRadius),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.specWhite,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(_contentRadius),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const SizedBox(height: 24),
                  ),
                ),
              ),
            ];
          },
          body: isTablet
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DetailScrollContent(
                        listing: listing,
                        data: data,
                        theme: theme,
                        colorScheme: colorScheme,
                        isSignedIn: isSignedIn,
                        currentUserId: currentUserId,
                        onClaimSubmitted: onReload,
                        onReload: onReload,
                        padding: padding,
                      ),
                    ),
                    _StickyConnectPanel(
                      listing: listing,
                      data: data,
                      isSignedIn: isSignedIn,
                      currentUserId: currentUserId,
                      onClaimSubmitted: onReload,
                    ),
                  ],
                )
              : _DetailScrollContent(
                  listing: listing,
                  data: data,
                  theme: theme,
                  colorScheme: colorScheme,
                  isSignedIn: isSignedIn,
                  currentUserId: currentUserId,
                  onClaimSubmitted: onReload,
                  onReload: onReload,
                  padding: padding,
                ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, MockListing listing) {
    final showCarousel = data.isPartner && data.imageUrls.length > 1;
    final singleImageUrl = data.bannerImageUrl ?? (data.imageUrls.isNotEmpty ? data.imageUrls.first : null);

    return SliverAppBar(
      expandedHeight: _heroHeight,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: _GlassButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (data.isOwnerOrManager) ...[
          Tooltip(
            message: 'Edit listing',
            child: _GlassButton(
              icon: Icons.edit_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ListingEditScreen(listingId: listing.id),
                  ),
                );
              },
            ),
          ),
        ],
        ValueListenableBuilder<Set<String>>(
          valueListenable: FavoritesScope.of(context),
          builder: (context, ids, _) {
            final isFav = ids.contains(listing.id);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data.favoritesCount > 0) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      data.favoritesCount.toString(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                _GlassButton(
                  icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  onTap: () async {
                    final next = Set<String>.from(ids);
                    final scope = AppDataScope.of(context);
                    if (next.contains(listing.id)) {
                      next.remove(listing.id);
                      if (scope.dataSource.useSupabase) {
                        await scope.favoritesRepository.remove(listing.id);
                      }
                    } else {
                      final perms = scope.userTierService.value ?? ResolvedPermissions.free;
                      if (scope.dataSource.useSupabase &&
                          perms.wouldExceedFavoritesLimit(ids.length)) {
                        if (!context.mounted) return;
                        await SubscriptionUpsellPopup.show(context);
                        return;
                      }
                      next.add(listing.id);
                      if (scope.dataSource.useSupabase) {
                        await scope.favoritesRepository.add(listing.id);
                      }
                    }
                    if (!context.mounted) return;
                    FavoritesScope.of(context).value = next;
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
        _GlassButton(
          icon: Icons.share_rounded,
          onTap: () {},
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (showCarousel)
              PageView.builder(
                itemCount: data.imageUrls.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    data.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _heroGradient(),
                  );
                },
              )
            else if (singleImageUrl != null)
              Image.network(
                singleImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _heroGradient(),
              )
            else
              _heroGradient(),
            if (!showCarousel && data.logoUrl != null && data.logoUrl!.isNotEmpty)
              Positioned(
                left: 24,
                bottom: 100,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.specWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            CustomPaint(
              painter: _GridOverlayPainter(
                color: Colors.white.withValues(alpha: 0.04),
                spacing: 24,
              ),
            ),
            if (data.deals.isNotEmpty)
              Positioned(
                left: 16,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.specNavy.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, size: 18, color: AppTheme.specGold),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          data.deals.first.title,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (data.subscriptionTier != null && data.subscriptionTier!.isNotEmpty)
              Positioned(
                top: 72,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.specWhite.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    data.subscriptionTier!.toLowerCase() == 'local_partner' ||
                            data.subscriptionTier!.toLowerCase() == 'enterprise' ||
                            data.subscriptionTier!.toLowerCase() == 'premium'
                        ? '+ Local Partner'
                        : '+ Local Plus',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.specGold,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _heroGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.specNavy.withValues(alpha: 0.95),
            AppTheme.specNavy.withValues(alpha: 0.85),
            AppTheme.specNavy.withValues(alpha: 0.7),
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Single scroll with Business Identity, Action Row, Deal Card, and tabbed content.
class _DetailScrollContent extends StatefulWidget {
  const _DetailScrollContent({
    required this.listing,
    required this.data,
    required this.theme,
    required this.colorScheme,
    required this.isSignedIn,
    required this.currentUserId,
    required this.onClaimSubmitted,
    required this.onReload,
    required this.padding,
  });

  final MockListing listing;
  final _DetailData data;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isSignedIn;
  final String? currentUserId;
  final VoidCallback onClaimSubmitted;
  final VoidCallback onReload;
  final EdgeInsets padding;

  @override
  State<_DetailScrollContent> createState() => _DetailScrollContentState();
}

class _DetailScrollContentState extends State<_DetailScrollContent> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final data = widget.data;
    final theme = widget.theme;
    final colorScheme = widget.colorScheme;
    final hasHours = listing.hours != null && listing.hours!.isNotEmpty;
    final showClaim = listing.isClaimable == true && widget.isSignedIn && widget.currentUserId != null;
    final hasPendingClaim = data.userClaim?.status == 'pending';
    final hasApprovedClaim = data.userClaim?.status == 'approved';
    final hasDeals = data.deals.isNotEmpty;
    final hasPunch = data.punchCards.isNotEmpty;
    final hasEvents = data.events.isNotEmpty;

    return ListView(
      padding: EdgeInsets.fromLTRB(widget.padding.left, 20, widget.padding.right, 36),
      children: [
        _BusinessIdentitySection(
          listing: listing,
          data: data,
          theme: theme,
        ),
        const SizedBox(height: 16),
        _ActionRow(
          listing: listing,
          data: data,
          onReload: widget.onReload,
        ),
        if (hasDeals) ...[
          const SizedBox(height: 20),
          _FeaturedDealCard(
            deal: data.deals.first,
            listingName: listing.name,
            openStatus: hasHours ? (listing.isOpenNow ? 'Open now' : 'Closed') : null,
            hoursSummary: hasHours && listing.hours != null ? _formatHoursSummary(listing.hours!) : null,
            isSignedIn: widget.isSignedIn,
            onReload: widget.onReload,
          ),
        ],
        const SizedBox(height: 24),
        _SegmentedTabs(
          selectedIndex: _selectedTabIndex,
          onChanged: (i) => setState(() => _selectedTabIndex = i),
          theme: theme,
        ),
        const SizedBox(height: 16),
        if (_selectedTabIndex == 0)
          _InfoTabContent(
            listing: listing,
            data: data,
            theme: theme,
            colorScheme: colorScheme,
            isSignedIn: widget.isSignedIn,
            showClaim: showClaim,
            hasPendingClaim: hasPendingClaim,
            hasApprovedClaim: hasApprovedClaim,
            currentUserId: widget.currentUserId,
            onClaimSubmitted: widget.onClaimSubmitted,
            onReload: widget.onReload,
          )
        else if (_selectedTabIndex == 1)
          _DealsTabContent(
            listingId: data.listing.id,
            listingName: data.listing.name,
            deals: data.deals,
          )
        else if (_selectedTabIndex == 2)
          _MenusTabContent(menuItems: data.menuItems, theme: theme)
        else
          _ReviewsTabContent(
            data: data,
            theme: theme,
          ),
        if (hasPunch) ...[
          const SizedBox(height: 24),
          _Section(
            title: 'Punch cards',
            icon: Icons.loyalty_rounded,
            child: _PunchCardsBlock(
              cards: data.punchCards,
              isSignedIn: widget.isSignedIn,
              onEnroll: widget.onReload,
            ),
          ),
        ],
        if (hasEvents) ...[
          const SizedBox(height: 24),
          _Section(
            title: 'Events',
            icon: Icons.event_rounded,
            child: _EventsBlock(
              events: data.events,
              isSignedIn: widget.isSignedIn,
              onRsvpChanged: widget.onReload,
            ),
          ),
        ],
      ],
    );
  }

  static String? _formatHoursSummary(List<DayHours> hours) {
    if (hours.isEmpty) return null;
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final now = DateTime.now();
    final todayName = dayNames[now.weekday - 1];
    for (final h in hours) {
      if (h.day == todayName) return h.range;
    }
    return null;
  }
}

class _BusinessIdentitySection extends StatelessWidget {
  const _BusinessIdentitySection({
    required this.listing,
    required this.data,
    required this.theme,
  });
  final MockListing listing;
  final _DetailData data;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final nav = AppTheme.specNavy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: nav,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...List.generate(5, (i) => Icon(
              i < data.averageRating.round().clamp(0, 5)
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 20,
              color: AppTheme.specGold,
            )),
            const SizedBox(width: 6),
            Text(
              '(${data.reviewCount})',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: nav.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.check_circle_outline_rounded, size: 18, color: nav.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(
              listing.categoryName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: nav.withValues(alpha: 0.8),
              ),
            ),
            if (data.distanceMi != null) ...[
              Text(
                ' · ${data.distanceMi!.toStringAsFixed(1)} mi',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: nav.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.listing,
    required this.data,
    required this.onReload,
  });
  final MockListing listing;
  final _DetailData data;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.phone_rounded,
            label: 'Call',
            onTap: listing.phone != null
                ? () async { await _ActionRow._launchUrl('tel:${listing.phone}'); }
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.directions_rounded,
            label: 'Directions',
            onTap: listing.address != null
                ? () async {
                    await _ActionRow._launchUrl(
                      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(listing.address!)}',
                    );
                  }
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: FavoritesScope.of(context),
            builder: (context, ids, _) {
              final isFav = ids.contains(listing.id);
              return _ActionButton(
                icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: 'Save',
                onTap: () async {
                  final scope = AppDataScope.of(context);
                  final next = Set<String>.from(ids);
                  if (next.contains(listing.id)) {
                    next.remove(listing.id);
                    if (scope.dataSource.useSupabase) {
                      await scope.favoritesRepository.remove(listing.id);
                    }
                  } else {
                    final perms = scope.userTierService.value ?? ResolvedPermissions.free;
                    if (scope.dataSource.useSupabase &&
                        perms.wouldExceedFavoritesLimit(ids.length)) {
                      if (!context.mounted) return;
                      await SubscriptionUpsellPopup.show(context);
                      return;
                    }
                    next.add(listing.id);
                    if (scope.dataSource.useSupabase) {
                      await scope.favoritesRepository.add(listing.id);
                    }
                  }
                  if (!context.mounted) return;
                  FavoritesScope.of(context).value = next;
                  onReload();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    return Material(
      color: AppTheme.specWhite,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: nav.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: nav),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: nav,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedDealCard extends StatefulWidget {
  const _FeaturedDealCard({
    required this.deal,
    required this.listingName,
    this.openStatus,
    this.hoursSummary,
    required this.isSignedIn,
    required this.onReload,
  });
  final MockDeal deal;
  final String listingName;
  final String? openStatus;
  final String? hoursSummary;
  final bool isSignedIn;
  final VoidCallback onReload;

  @override
  State<_FeaturedDealCard> createState() => _FeaturedDealCardState();
}

class _FeaturedDealCardState extends State<_FeaturedDealCard> {
  bool _claimed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.specGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.deal.discount != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: nav.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.deal.discount!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
              ),
            ),
          Text(
            widget.deal.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: nav,
            ),
          ),
          if (widget.deal.expiry != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: nav.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(
                  _expiryText(widget.deal.expiry!),
                  style: theme.textTheme.bodySmall?.copyWith(color: nav.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            widget.deal.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: nav.withValues(alpha: 0.85),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.openStatus != null || widget.hoursSummary != null) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (widget.openStatus != null) widget.openStatus!,
                if (widget.hoursSummary != null) widget.hoursSummary!,
              ].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: nav.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppPrimaryButton(
            onPressed: () {
              DealDetailPopup.show(
                context,
                deal: widget.deal,
                listingName: widget.listingName,
                showViewBusinessButton: false,
                isClaimed: _claimed,
                isUsed: false,
                usedAt: null,
                onClaim: widget.isSignedIn ? () async {
                  final scope = AppDataScope.of(context);
                  final uid = scope.authRepository.currentUserId;
                  if (uid == null) return;
                  final canClaim = scope.userTierService.value?.canClaimDeals ?? false;
                  if (!canClaim) {
                    await SubscriptionUpsellPopup.show(context);
                    return;
                  }
                  await UserDealsRepository(authRepository: scope.authRepository).claim(uid, widget.deal.id);
                  if (mounted) setState(() => _claimed = true);
                  widget.onReload();
                } : null,
                onClaimUpsell: widget.isSignedIn ? () => SubscriptionUpsellPopup.show(context) : null,
              );
            },
            expanded: false,
            child: const Text('Claim Deal'),
          ),
        ],
      ),
    );
  }

  static String _expiryText(DateTime expiry) {
    final now = DateTime.now();
    final diff = expiry.difference(now);
    if (diff.isNegative) return 'Expired';
    if (diff.inDays == 0) return 'Expires today';
    if (diff.inDays == 1) return 'Expires tomorrow';
    return 'Expires in ${diff.inDays} days';
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.selectedIndex,
    required this.onChanged,
    required this.theme,
  });
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final nav = AppTheme.specNavy;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: nav.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TabChip(label: 'Info', selected: selectedIndex == 0, onTap: () => onChanged(0)),
          _TabChip(label: 'Deals', selected: selectedIndex == 1, onTap: () => onChanged(1)),
          _TabChip(label: 'Menus', selected: selectedIndex == 2, onTap: () => onChanged(2)),
          _TabChip(label: 'Reviews', selected: selectedIndex == 3, onTap: () => onChanged(3)),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    return Expanded(
      child: Material(
        color: selected ? nav : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? AppTheme.specWhite : nav.withValues(alpha: 0.8),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DealsTabContent extends StatelessWidget {
  const _DealsTabContent({
    required this.listingId,
    required this.listingName,
    required this.deals,
  });
  final String listingId;
  final String listingName;
  final List<MockDeal> deals;

  @override
  Widget build(BuildContext context) {
    if (deals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No active deals',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.specNavy.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    return _DealsBlock(
      listingId: listingId,
      listingName: listingName,
      deals: deals,
    );
  }
}

/// Menus / services / products tab: sections and items in card layout.
class _MenusTabContent extends StatelessWidget {
  const _MenusTabContent({
    required this.menuItems,
    required this.theme,
  });

  final List<MockMenuItem> menuItems;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final nav = AppTheme.specNavy;
    final colorScheme = theme.colorScheme;
    if (menuItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                size: 48,
                color: nav.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No menu or services listed yet',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: nav.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    final bySection = <String, List<MockMenuItem>>{};
    for (final item in menuItems) {
      final sec = item.section ?? 'Menu';
      bySection.putIfAbsent(sec, () => []).add(item);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in bySection.entries) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        size: 20,
                        color: AppTheme.specGold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: nav,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...entry.value.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: nav,
                                  ),
                                ),
                                if (item.description != null && item.description!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (item.price != null && item.price!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.specGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.price!,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: nav,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoTabContent extends StatelessWidget {
  const _InfoTabContent({
    required this.listing,
    required this.data,
    required this.theme,
    required this.colorScheme,
    required this.isSignedIn,
    required this.showClaim,
    required this.hasPendingClaim,
    required this.hasApprovedClaim,
    required this.currentUserId,
    required this.onClaimSubmitted,
    required this.onReload,
  });
  final MockListing listing;
  final _DetailData data;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isSignedIn;
  final bool showClaim;
  final bool hasPendingClaim;
  final bool hasApprovedClaim;
  final String? currentUserId;
  final VoidCallback onClaimSubmitted;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final hasHours = listing.hours != null && listing.hours!.isNotEmpty;
    final hasContact = listing.address != null ||
        listing.phone != null ||
        listing.website != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (listing.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              listing.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.55,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (hasContact) ...[
          _ContactBlock(listing: listing),
          const SizedBox(height: 16),
        ],
        if (hasHours) ...[
          _Section(
            title: 'Hours',
            icon: Icons.schedule_outlined,
            child: _HoursBlock(hours: listing.hours!),
          ),
          const SizedBox(height: 16),
        ],
        if (listing.amenities.isNotEmpty) ...[
          _Section(
            title: 'Amenities',
            icon: Icons.check_circle_outline_rounded,
            child: _AmenitiesBlock(amenityNames: listing.amenities),
          ),
          const SizedBox(height: 16),
        ],
        if (data.listingLatitude != null && data.listingLongitude != null) ...[
          _MapPreviewPlaceholder(
            lat: data.listingLatitude!,
            lng: data.listingLongitude!,
          ),
          const SizedBox(height: 16),
        ],
        if (data.socialLinks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Social & links',
            icon: Icons.link_rounded,
            child: _SocialLinksBlock(links: data.socialLinks),
          ),
        ],
        const SizedBox(height: 20),
        _ContactCtaSection(
          listingId: listing.id,
          listingName: listing.name,
          contactFormTemplate: data.contactFormTemplate,
          isSignedIn: isSignedIn,
          onConversationStarted: (conversationId) {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ConversationThreadScreen(
                  conversationId: conversationId,
                  businessName: listing.name,
                ),
              ),
            );
          },
        ),
        if (showClaim && !hasApprovedClaim) ...[
          const SizedBox(height: 16),
          _UnclaimedClaimSection(
            listing: listing,
            hasPendingClaim: hasPendingClaim,
            onClaimTap: () async {
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => ClaimBusinessScreen(
                    businessId: listing.id,
                    businessName: listing.name,
                    userId: currentUserId!,
                  ),
                ),
              );
              if (ok == true) onClaimSubmitted();
            },
          ),
        ],
      ],
    );
  }
}

class _ReviewsTabContent extends StatelessWidget {
  const _ReviewsTabContent({
    required this.data,
    required this.theme,
  });
  final _DetailData data;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final nav = AppTheme.specNavy;
    if (data.reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No reviews yet',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: nav.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ...List.generate(5, (i) => Icon(
              i < data.averageRating.round().clamp(0, 5)
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 24,
              color: AppTheme.specGold,
            )),
            const SizedBox(width: 8),
            Text(
              '${data.averageRating.toStringAsFixed(1)} (${data.reviewCount})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: nav,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final r in data.reviews)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.specWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: nav.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                        i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 16,
                        color: AppTheme.specGold,
                      )),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(r.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: nav.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  if (r.body != null && r.body!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      r.body!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: nav,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.month}/${d.day}/${d.year}';
  }
}

class _MapPreviewPlaceholder extends StatelessWidget {
  const _MapPreviewPlaceholder({required this.lat, required this.lng});
  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.specNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.12)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, size: 32, color: AppTheme.specNavy.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              'Map · $lat, $lng',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.specNavy.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsBlock extends StatefulWidget {
  const _EventsBlock({
    required this.events,
    required this.isSignedIn,
    required this.onRsvpChanged,
  });

  final List<MockEvent> events;
  final bool isSignedIn;
  final VoidCallback onRsvpChanged;

  @override
  State<_EventsBlock> createState() => _EventsBlockState();
}

class _EventsBlockState extends State<_EventsBlock> {
  final _rsvpRepo = EventRsvpsRepository();
  Map<String, String> _myStatusByEventId = {};
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded && widget.events.isNotEmpty) {
      if (widget.isSignedIn) {
        _loadMyRsvps();
      } else {
        setState(() => _loaded = true);
      }
    }
  }

  Future<void> _loadMyRsvps() async {
    final map = <String, String>{};
    await Future.wait(widget.events.map((e) async {
      final rsvp = await _rsvpRepo.getMyRsvpForEvent(e.id);
      map[e.id] = rsvp?.status ?? '';
    }));
    if (!mounted) return;
    setState(() {
      _myStatusByEventId = map;
      _loaded = true;
    });
  }

  Future<void> _setRsvp(String eventId, String status) async {
    await _rsvpRepo.upsert(eventId: eventId, status: status);
    if (mounted) {
      setState(() => _myStatusByEventId[eventId] = status);
      widget.onRsvpChanged();
    }
  }

  static String _dateStr(DateTime d) {
    return '${d.month}/${d.day}/${d.year}';
  }

  static String _timeStr(DateTime d) {
    if (d.hour == 0 && d.minute == 0) return '';
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute == 0 ? '' : ':${d.minute.toString().padLeft(2, '0')}';
    return '$h$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in widget.events) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: nav.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    _dateStr(e.eventDate),
                    if (_timeStr(e.eventDate).isNotEmpty) _timeStr(e.eventDate),
                    if (e.location != null && e.location!.trim().isNotEmpty) e.location,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: nav.withValues(alpha: 0.7),
                  ),
                ),
                if (widget.isSignedIn) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _RsvpChip(
                        label: 'Going',
                        status: 'going',
                        selected: _myStatusByEventId[e.id] == 'going',
                        onTap: () => _setRsvp(e.id, 'going'),
                      ),
                      _RsvpChip(
                        label: 'Interested',
                        status: 'interested',
                        selected: _myStatusByEventId[e.id] == 'interested',
                        onTap: () => _setRsvp(e.id, 'interested'),
                      ),
                      _RsvpChip(
                        label: 'Not going',
                        status: 'not_going',
                        selected: _myStatusByEventId[e.id] == 'not_going',
                        onTap: () => _setRsvp(e.id, 'not_going'),
                      ),
                    ],
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Sign in to RSVP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: nav.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _RsvpChip extends StatelessWidget {
  const _RsvpChip({
    required this.label,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.specGold.withValues(alpha: 0.35),
      checkmarkColor: AppTheme.specNavy,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: selected ? AppTheme.specNavy : AppTheme.specNavy.withValues(alpha: 0.8),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}

class _StickyConnectPanel extends StatelessWidget {
  const _StickyConnectPanel({
    required this.listing,
    required this.data,
    required this.isSignedIn,
    required this.currentUserId,
    required this.onClaimSubmitted,
  });
  final MockListing listing;
  final _DetailData data;
  final bool isSignedIn;
  final String? currentUserId;
  final VoidCallback onClaimSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final hasContact = listing.address != null ||
        listing.phone != null ||
        listing.website != null;
    final hasHours = listing.hours != null && listing.hours!.isNotEmpty;
    final showClaim = listing.isClaimable == true && isSignedIn && currentUserId != null;
    final hasPendingClaim = data.userClaim?.status == 'pending';
    final hasApprovedClaim = data.userClaim?.status == 'approved';

    return SingleChildScrollView(
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        margin: const EdgeInsets.only(right: 16, top: 8),
        decoration: BoxDecoration(
          color: AppTheme.specWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.specNavy.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data.subscriptionTier != null && data.subscriptionTier!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.5)),
                ),
                child: Text(
                  data.subscriptionTier!.toLowerCase() == 'local_partner' ||
                          data.subscriptionTier!.toLowerCase() == 'enterprise' ||
                          data.subscriptionTier!.toLowerCase() == 'premium'
                      ? '+ Local Partner'
                      : '+ Local Plus',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.specGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: nav,
              ),
            ),
            const SizedBox(height: 16),
            if (hasContact) ...[
              _ContactBlock(listing: listing),
              const SizedBox(height: 20),
            ],
            if (hasHours) ...[
              _Section(
                title: 'Hours',
                icon: Icons.schedule_outlined,
                child: _HoursBlock(hours: listing.hours!),
              ),
              const SizedBox(height: 20),
            ],
            if (listing.amenities.isNotEmpty) ...[
              _Section(
                title: 'Amenities',
                icon: Icons.check_circle_outline_rounded,
                child: _AmenitiesBlock(amenityNames: listing.amenities),
              ),
              const SizedBox(height: 20),
            ],
            if (data.listingLatitude != null && data.listingLongitude != null) ...[
              _MapPreviewPlaceholder(
                lat: data.listingLatitude!,
                lng: data.listingLongitude!,
              ),
              const SizedBox(height: 20),
            ],
            if (data.reviewCount > 0) ...[
              Text(
                'Reviews',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: nav,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ...List.generate(5, (i) => Icon(
                    i < data.averageRating.round().clamp(0, 5)
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 18,
                    color: AppTheme.specGold,
                  )),
                  const SizedBox(width: 6),
                  Text(
                    '${data.averageRating.toStringAsFixed(1)} (${data.reviewCount})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: nav,
                    ),
                  ),
                ],
              ),
              if (data.reviews.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.specOffWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: nav.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.reviews.first.body ?? '—',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: nav.withValues(alpha: 0.85),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'More >',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.specGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
            Text(
              'Connect',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: nav,
              ),
            ),
            const SizedBox(height: 16),
            if (showClaim && !hasApprovedClaim) ...[
              _UnclaimedClaimChip(
                hasPendingClaim: hasPendingClaim,
                onTap: () async {
                  final ok = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => ClaimBusinessScreen(
                        businessId: listing.id,
                        businessName: listing.name,
                        userId: currentUserId!,
                      ),
                    ),
                  );
                  if (ok == true) onClaimSubmitted();
                },
              ),
              const SizedBox(height: 16),
            ],
            _ContactCtaSection(
              listingId: listing.id,
              listingName: listing.name,
              contactFormTemplate: data.contactFormTemplate,
              isSignedIn: isSignedIn,
              onConversationStarted: (conversationId) {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ConversationThreadScreen(
                      conversationId: conversationId,
                      businessName: listing.name,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Small badge + CTA at bottom of listing when unclaimed and user can claim.
class _UnclaimedClaimSection extends StatelessWidget {
  const _UnclaimedClaimSection({
    required this.listing,
    required this.hasPendingClaim,
    required this.onClaimTap,
  });
  final MockListing listing;
  final bool hasPendingClaim;
  final VoidCallback onClaimTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.store_outlined, size: 20, color: AppTheme.specNavy),
              const SizedBox(width: 8),
              Text(
                'Unclaimed listing',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.specNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.specGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasPendingClaim)
                  Text(
                    'Your claim is under review. We\'ll notify you once approved.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.9),
                    ),
                  )
                else ...[
                  Text(
                    'Own this business? Submit proof of identification; we\'ll review and approve your claim.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    onPressed: onClaimTap,
                    expanded: false,
                    icon: const Icon(Icons.handshake_rounded, size: 20),
                    label: const Text('Claim this business'),
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

/// Compact chip for sticky panel.
class _UnclaimedClaimChip extends StatelessWidget {
  const _UnclaimedClaimChip({
    required this.hasPendingClaim,
    required this.onTap,
  });
  final bool hasPendingClaim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppTheme.specGold.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: hasPendingClaim ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(
                hasPendingClaim ? Icons.schedule_rounded : Icons.store_outlined,
                size: 20,
                color: AppTheme.specNavy,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasPendingClaim ? 'Claim under review' : 'Unclaimed — tap to claim',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.specNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridOverlayPainter extends CustomPainter {
  _GridOverlayPainter({required this.color, required this.spacing});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: AppTheme.specNavy,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.specNavy,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _HoursBlock extends StatelessWidget {
  const _HoursBlock({required this.hours});

  final List<DayHours> hours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.specOffWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.specNavy.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < hours.length; i++) ...[
            if (i > 0)
              Divider(
                height: 24,
                color: AppTheme.specNavy.withValues(alpha: 0.12),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hours[i].day,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.specNavy,
                  ),
                ),
                Text(
                  hours[i].range,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AmenitiesBlock extends StatelessWidget {
  const _AmenitiesBlock({required this.amenityNames});

  final List<String> amenityNames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.specOffWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.specNavy.withValues(alpha: 0.08),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: amenityNames.map((name) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.specNavy.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.specGold),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.specNavy,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Dynamic CTA to contact: button label from contact form template; tap opens form in popup.
class _ContactCtaSection extends StatelessWidget {
  const _ContactCtaSection({
    required this.listingId,
    required this.listingName,
    required this.contactFormTemplate,
    required this.isSignedIn,
    required this.onConversationStarted,
  });

  final String listingId;
  final String listingName;
  final String? contactFormTemplate;
  final bool isSignedIn;
  final void Function(String conversationId) onConversationStarted;

  void _openFormPopup(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.specOffWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.specNavy.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Text(
                  'Contact $listingName',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: ContactFormWidget(
                    businessId: listingId,
                    businessName: listingName,
                    isSignedIn: isSignedIn,
                    onConversationStarted: onConversationStarted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = contactFormTemplate != null
        ? ContactFormTemplates.getByKey(contactFormTemplate!)
        : null;

    if (def == null) {
      return Text(
        'This business hasn\'t set up a contact form.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (!isSignedIn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign in to send a message.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return AppSecondaryButton(
      onPressed: () => _openFormPopup(context),
      icon: const Icon(Icons.mail_outline_rounded, size: 22),
      label: Text(def.name),
    );
  }
}

class _ContactBlock extends StatelessWidget {
  const _ContactBlock({required this.listing});

  final MockListing listing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (listing.address != null)
          _ContactRow(
            icon: Icons.location_on_outlined,
            label: listing.address!,
            onTap: () {},
          ),
        if (listing.phone != null) ...[
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: listing.phone!,
            onTap: () {},
          ),
        ],
        if (listing.website != null) ...[
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.language_rounded,
            label: listing.website!,
            onTap: () {},
          ),
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppTheme.specOffWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.specNavy),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.specNavy,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppTheme.specGold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLinksBlock extends StatelessWidget {
  const _SocialLinksBlock({required this.links});

  final List<MockSocialLink> links;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final link in links)
          Material(
            color: AppTheme.specOffWhite,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconForType(link.type),
                      size: 20,
                      color: AppTheme.specNavy,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      link.label ?? _labelForType(link.type),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.specNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'facebook':
        return Icons.thumb_up_rounded;
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'twitter':
        return Icons.tag_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  static String _labelForType(String type) {
    switch (type) {
      case 'facebook':
        return 'Facebook';
      case 'instagram':
        return 'Instagram';
      case 'twitter':
        return 'Twitter';
      default:
        return 'Link';
    }
  }
}

class _DealsBlock extends StatefulWidget {
  const _DealsBlock({
    required this.listingId,
    required this.deals,
    this.listingName,
  });

  final String listingId;
  final List<MockDeal> deals;
  final String? listingName;

  @override
  State<_DealsBlock> createState() => _DealsBlockState();
}

class _DealsBlockState extends State<_DealsBlock> {
  Map<String, UserDeal> _userDealsByDealId = {};
  bool _claimedLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_claimedLoaded && widget.deals.isNotEmpty) _loadClaimed();
  }

  Future<void> _loadClaimed() async {
    final auth = AppDataScope.of(context).authRepository;
    final uid = auth.currentUserId;
    if (uid == null) {
      if (mounted) setState(() => _claimedLoaded = true);
      return;
    }
    final list = await UserDealsRepository(authRepository: auth).listForUser(uid);
    if (mounted) {
      setState(() {
      _userDealsByDealId = {for (var e in list) e.dealId: e};
      _claimedLoaded = true;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = AppDataScope.of(context);
    final auth = scope.authRepository;
    final uid = auth.currentUserId;
    final canClaimDeals = uid != null && (scope.userTierService.value?.canClaimDeals ?? false);
    final userDealsRepo = UserDealsRepository(authRepository: auth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final deal in widget.deals)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final ud = _userDealsByDealId[deal.id];
                  DealDetailPopup.show(
                    context,
                    deal: deal,
                    listingName: widget.listingName,
                    showViewBusinessButton: false,
                    isClaimed: ud != null,
                    isUsed: ud?.usedAt != null,
                    usedAt: ud?.usedAt,
                    onClaim: canClaimDeals
                        ? () async {
                            await userDealsRepo.claim(uid, deal.id);
                            final claimerProfile = await AuthRepository().getProfileForAdmin(uid);
                            final ownerUserId = await BusinessManagersRepository().getFirstManagerUserId(deal.listingId) ??
                                await BusinessRepository().getCreatedBy(deal.listingId);
                            if (ownerUserId != null) {
                              final ownerProfile = await AuthRepository().getProfileForAdmin(ownerUserId);
                              final to = ownerProfile?.email?.trim();
                              if (to != null && to.isNotEmpty) {
                                await SendEmailService().send(
                                  to: to,
                                  template: 'deal_claimed',
                                  variables: {
                                    'display_name': claimerProfile?.displayName ?? 'A customer',
                                    'deal_title': deal.title,
                                    'business_name': widget.listingName ?? deal.listingId,
                                  },
                                );
                              }
                            }
                            if (mounted) {
                              setState(() {
                              _userDealsByDealId[deal.id] = UserDeal(
                                userId: uid,
                                dealId: deal.id,
                                claimedAt: DateTime.now(),
                                usedAt: null,
                              );
                            });
                            }
                          }
                        : null,
                    onClaimUpsell: uid != null && !canClaimDeals
                        ? () => SubscriptionUpsellPopup.show(context)
                        : null,
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.specNavy.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.specNavy.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (deal.discount != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.specGold.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                deal.discount!,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.specNavy,
                                ),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              deal.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.specNavy,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppTheme.specGold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        deal.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (deal.code != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Code: ${deal.code!}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: AppTheme.specNavy,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PunchCardsBlock extends StatelessWidget {
  const _PunchCardsBlock({
    required this.cards,
    required this.isSignedIn,
    required this.onEnroll,
  });

  final List<MockPunchCard> cards;
  final bool isSignedIn;
  final VoidCallback onEnroll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final card in cards)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PunchCardTile(
              card: card,
              isSignedIn: isSignedIn,
              onEnroll: onEnroll,
            ),
          ),
      ],
    );
  }
}

class _PunchCardTile extends StatefulWidget {
  const _PunchCardTile({
    required this.card,
    required this.isSignedIn,
    required this.onEnroll,
  });

  final MockPunchCard card;
  final bool isSignedIn;
  final VoidCallback onEnroll;

  @override
  State<_PunchCardTile> createState() => _PunchCardTileState();
}

class _PunchCardTileState extends State<_PunchCardTile> {
  bool _enrolling = false;

  Future<void> _enroll() async {
    setState(() => _enrolling = true);
    try {
      await UserPunchCardsRepository().enroll(widget.card.id);
      if (mounted) {
        widget.onEnroll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You\'re enrolled!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not enroll: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = widget.card;
    final canEnroll = widget.isSignedIn && card.userPunchCardId == null && !card.isRedeemed;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.specOffWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.specNavy.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.specNavy,
                  ),
                ),
              ),
              if (card.isRedeemed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.specGold.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Redeemed',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.specNavy,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            card.rewardDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < card.punchesRequired; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < card.punchesEarned
                          ? AppTheme.specNavy
                          : AppTheme.specNavy.withValues(alpha: 0.12),
                      border: Border.all(
                        color: i < card.punchesEarned
                            ? AppTheme.specNavy
                            : AppTheme.specNavy.withValues(alpha: 0.25),
                      ),
                    ),
                    child: i < card.punchesEarned
                        ? Icon(Icons.check_rounded, size: 14, color: AppTheme.specWhite)
                        : null,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '${card.punchesEarned}/${card.punchesRequired} punches',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (canEnroll) ...[
            const SizedBox(height: 12),
            AppSecondaryButton(
              onPressed: _enrolling ? null : _enroll,
              expanded: true,
              child: _enrolling
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enroll'),
            ),
          ],
          if (card.userPunchCardId != null && !card.isRedeemed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppOutlinedButton(
                onPressed: () => showPunchQrSheet(context, userPunchCardId: card.userPunchCardId!, cardTitle: card.title),
                icon: const Icon(Icons.qr_code_2_rounded, size: 20, color: AppTheme.specNavy),
                label: Text(
                  'Show QR for punch',
                  style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.specNavy, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
