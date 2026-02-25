import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/contact_form_templates.dart';
import 'package:my_app/core/data/models/business.dart';
import 'package:my_app/core/data/models/business_image.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/models/menu_item.dart';
import 'package:my_app/core/data/models/menu_section.dart';
import 'package:my_app/core/data/repositories/business_images_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/business_subscriptions_repository.dart';
import 'package:my_app/core/data/repositories/deals_repository.dart';
import 'package:my_app/core/data/repositories/menu_repository.dart';
import 'package:my_app/core/data/repositories/punch_card_programs_repository.dart';
import 'package:my_app/core/data/services/business_images_storage_service.dart';
import 'package:my_app/core/data/services/storage_upload_constants.dart';
import 'package:my_app/core/subscription/business_tier_service.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/business_tier_upgrade_dialog.dart';
import 'package:my_app/core/preferences/owner_onboarding_preferences.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:my_app/features/my_listings/presentation/screens/business_ads_screen.dart';
import 'package:my_app/features/my_listings/presentation/screens/create_business_item_screen.dart';
import 'package:my_app/features/my_listings/presentation/screens/event_detail_screen.dart';
import 'package:my_app/features/my_listings/presentation/screens/form_submissions_inbox_screen.dart';
import 'package:my_app/features/my_listings/presentation/screens/punch_card_enrollments_screen.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/app_section_card.dart';
import 'package:my_app/shared/widgets/business_amenities_editor.dart';
import 'package:my_app/shared/widgets/business_hours_editor.dart';
import 'package:my_app/shared/widgets/business_links_editor.dart';
import 'package:my_app/shared/widgets/owner_onboarding_dialog.dart';

/// Tabbed edit/dashboard for a business listing. Tablet: left rail; mobile: tabs. Uses homepage theme (specOffWhite, specNavy, specGold).
class ListingEditScreen extends StatefulWidget {
  const ListingEditScreen({super.key, required this.listingId});

  final String listingId;

  @override
  State<ListingEditScreen> createState() => _ListingEditScreenState();
}

class _ListingEditScreenState extends State<ListingEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  bool _hasPendingApproval = false;
  bool _ownerOnboardingChecked = false;
  Future<(MockListing?, List<MockMenuItem>, List<MockDeal>, List<MockPunchCard>, List<MockEvent>, String?)>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (mounted && _selectedIndex != _tabController.index) {
        setState(() => _selectedIndex = _tabController.index);
      }
    });
  }

  Future<(MockListing?, List<MockMenuItem>, List<MockDeal>, List<MockPunchCard>, List<MockEvent>, String?)> _createLoadFuture() {
    final dataSource = AppDataScope.of(context).dataSource;
    return Future.wait([
      dataSource.getListingById(widget.listingId),
      dataSource.getMenuForListing(widget.listingId),
      dataSource.getDealsForListingForOwner(widget.listingId),
      dataSource.getPunchCardsForListing(widget.listingId),
      dataSource.getEventsForListing(widget.listingId),
    ]).then((r) async {
      final tier = SupabaseConfig.isConfigured
          ? await BusinessSubscriptionsRepository().getActivePlanTierForBusiness(widget.listingId)
          : null;
      return (
        r[0] as MockListing?,
        r[1] as List<MockMenuItem>,
        r[2] as List<MockDeal>,
        r[3] as List<MockPunchCard>,
        r[4] as List<MockEvent>,
        tier,
      );
    });
  }

  void _refreshListingData() {
    setState(() => _loadFuture = _createLoadFuture());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFuture ??= _createLoadFuture();
  }

  static bool _isPaidBusinessTier(String? tier) {
    if (tier == null || tier.isEmpty) return false;
    return tier.toLowerCase() != 'free';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _maybeShowOwnerOnboarding(BuildContext context) async {
    final done = await OwnerOnboardingPreferences.hasCompletedOwnerOnboarding();
    if (!context.mounted) return;
    if (done) return;
    await OwnerOnboardingDialog.show(
      context,
      onComplete: () async {
        await OwnerOnboardingPreferences.setCompletedOwnerOnboarding();
      },
      onSelectPlan: (tier) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upgrade to ${tier == 'basic' ? 'Basic' : 'Premium'}: go to More → Billing or contact support.',
            ),
          ),
        );
      },
    );
  }

  void _onDetailsSaveRequested() {
    setState(() {
      _hasPendingApproval = true;
      _loadFuture = _createLoadFuture();
    });
  }

  Widget _buildTabContent(
    int index,
    MockListing listing,
    List<MockMenuItem> menuItems,
    List<MockDeal> deals,
    List<MockPunchCard> punchCards,
    List<MockEvent> events,
    String? businessTier,
  ) {
    switch (index) {
      case 0:
        return _OverviewTab(listingId: widget.listingId, businessTier: businessTier);
      case 1:
        return _DetailsTab(
          listing: listing,
          listingId: widget.listingId,
          onSaveRequested: _onDetailsSaveRequested,
        );
      case 2:
        return _MenuTab(listingId: widget.listingId, items: menuItems);
      case 3:
        final activeDealCount = deals.where((d) => d.isActive).length;
        return _DealsTab(
          listingId: widget.listingId,
          deals: deals,
          punchCards: punchCards,
          businessTier: businessTier,
          activeDealCount: activeDealCount,
          onRefresh: _refreshListingData,
        );
      case 4:
        return _EventsTab(listingId: widget.listingId, events: events);
      case 5:
        if (_isPaidBusinessTier(businessTier)) {
          return FormSubmissionsInboxScreen(
            singleBusinessId: widget.listingId,
            embeddedInTab: true,
          );
        }
        return _FormSubmissionsPaywallTab();
      case 6:
        return _MoreTab(listingId: widget.listingId, hasPaidTier: _isPaidBusinessTier(businessTier));
      default:
        return _OverviewTab(listingId: widget.listingId, businessTier: businessTier);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = AppLayout.isTablet(context);

    if (_loadFuture == null) {
      return Scaffold(
        backgroundColor: AppTheme.specOffWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.specOffWhite,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppTheme.specNavy,
          title: Text('Listing', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return FutureBuilder<(MockListing?, List<MockMenuItem>, List<MockDeal>, List<MockPunchCard>, List<MockEvent>, String?)>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppTheme.specOffWhite,
            appBar: AppBar(
              backgroundColor: AppTheme.specOffWhite,
              surfaceTintColor: Colors.transparent,
              foregroundColor: AppTheme.specNavy,
              title: Text('Listing', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy)),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final listing = snapshot.data?.$1;
        final menuItems = snapshot.data?.$2 ?? const <MockMenuItem>[];
        final deals = snapshot.data?.$3 ?? const <MockDeal>[];
        final punchCards = snapshot.data?.$4 ?? const <MockPunchCard>[];
        final events = snapshot.data?.$5 ?? const <MockEvent>[];

        if (listing == null) {
          return Scaffold(
            backgroundColor: AppTheme.specOffWhite,
            appBar: AppBar(
              backgroundColor: AppTheme.specOffWhite,
              surfaceTintColor: Colors.transparent,
              foregroundColor: AppTheme.specNavy,
              title: Text('Listing', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy)),
            ),
            body: Center(child: Text('Listing not found', style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy))),
          );
        }

        if (!_ownerOnboardingChecked) {
          _ownerOnboardingChecked = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeShowOwnerOnboarding(context);
          });
        }

        if (isTablet) {
          return Scaffold(
            backgroundColor: AppTheme.specOffWhite,
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: AppTheme.specWhite,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    final tier = snapshot.data?.$6;
                    if (index == 6 && !_ListingEditScreenState._isPaidBusinessTier(tier)) {
                      _showMoreTabPaywall(context);
                      return;
                    }
                    setState(() => _selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: AppTheme.specGold),
                  selectedLabelTextStyle: theme.textTheme.labelLarge?.copyWith(color: AppTheme.specNavy, fontWeight: FontWeight.w600),
                  unselectedIconTheme: IconThemeData(color: AppTheme.specNavy.withValues(alpha: 0.7)),
                  unselectedLabelTextStyle: theme.textTheme.labelLarge?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.7)),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Overview')),
                    NavigationRailDestination(icon: Icon(Icons.info_outline_rounded), label: Text('Details')),
                    NavigationRailDestination(icon: Icon(Icons.view_list_rounded), label: Text('Menu')),
                    NavigationRailDestination(icon: Icon(Icons.local_offer_rounded), label: Text('Deals')),
                    NavigationRailDestination(icon: Icon(Icons.event_rounded), label: Text('Events')),
                    NavigationRailDestination(icon: Icon(Icons.inbox_rounded), label: Text('Messages')),
                    NavigationRailDestination(icon: Icon(Icons.monetization_on_rounded), label: Text('More')),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Material(
                        color: AppTheme.specOffWhite,
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    listing.name,
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ListingDetailScreen(listingId: widget.listingId),
                                      ),
                                    );
                                  },
                                  tooltip: 'View as customer',
                                  color: AppTheme.specNavy,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_hasPendingApproval) _PendingApprovalBanner(),
                      Expanded(
                        child: _buildTabContent(_selectedIndex, listing, menuItems, deals, punchCards, events, snapshot.data?.$6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.specOffWhite,
          appBar: AppBar(
            backgroundColor: AppTheme.specOffWhite,
            surfaceTintColor: Colors.transparent,
            foregroundColor: AppTheme.specNavy,
            title: Text(
              listing.name,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.specNavy,
              unselectedLabelColor: AppTheme.specNavy.withValues(alpha: 0.6),
              indicatorColor: AppTheme.specGold,
              indicatorWeight: 3,
              onTap: (index) {
                final tier = snapshot.data?.$6;
                if (index == 6 && !_ListingEditScreenState._isPaidBusinessTier(tier)) {
                  _showMoreTabPaywall(context);
                  _tabController.animateTo(_selectedIndex);
                  return;
                }
                setState(() => _selectedIndex = index);
              },
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: 'Overview'),
                Tab(icon: Icon(Icons.info_outline_rounded, size: 20), text: 'Details'),
                Tab(icon: Icon(Icons.view_list_rounded, size: 20), text: 'Menu'),
                Tab(icon: Icon(Icons.local_offer_rounded, size: 20), text: 'Deals'),
                Tab(icon: Icon(Icons.event_rounded, size: 20), text: 'Events'),
                Tab(icon: Icon(Icons.inbox_rounded, size: 20), text: 'Messages'),
                Tab(icon: Icon(Icons.monetization_on_rounded, size: 20), text: 'More'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListingDetailScreen(listingId: widget.listingId),
                    ),
                  );
                },
                tooltip: 'View as customer',
                color: AppTheme.specNavy,
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasPendingApproval) _PendingApprovalBanner(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(listingId: widget.listingId, businessTier: snapshot.data?.$6),
                    _DetailsTab(
                      listing: listing,
                      listingId: widget.listingId,
                      onSaveRequested: _onDetailsSaveRequested,
                    ),
                    _MenuTab(listingId: widget.listingId, items: menuItems),
                    _DealsTab(
                      listingId: widget.listingId,
                      deals: deals,
                      punchCards: punchCards,
                      businessTier: snapshot.data?.$6,
                      activeDealCount: deals.where((d) => d.isActive).length,
                      onRefresh: _refreshListingData,
                    ),
                    _EventsTab(listingId: widget.listingId, events: events),
                    _isPaidBusinessTier(snapshot.data?.$6)
                        ? FormSubmissionsInboxScreen(
                            singleBusinessId: widget.listingId,
                            embeddedInTab: true,
                          )
                        : const _FormSubmissionsPaywallTab(),
                    _MoreTab(listingId: widget.listingId, hasPaidTier: _isPaidBusinessTier(snapshot.data?.$6)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PendingApprovalBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.9),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 20,
                color: colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Edits pending approval',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onTertiaryContainer,
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

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.listingId, this.businessTier});

  final String listingId;
  final String? businessTier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = BusinessTierService.fromPlanTier(businessTier);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Overview',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tier == BusinessTier.free
              ? 'Your listing at a glance. Upgrade for more insights and features.'
              : tier == BusinessTier.localPlus
                  ? 'Track profile views, saves, redemptions, and messages. Your metrics will appear here as customers interact with your listing.'
                  : 'Full analytics for your listing. Profile views, saves, redemptions, and loyalty metrics.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.specNavy.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 24),
        // Free: minimal stats + upsell cards
        if (tier == BusinessTier.free) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final stats = [
                ('Profile views', '—', Icons.visibility_rounded),
                ('Saves', '—', Icons.favorite_rounded),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats.map((s) => SizedBox(
                  width: constraints.maxWidth > 400 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                  child: _StatCard(label: s.$1, value: s.$2, icon: s.$3),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Get more from your listing',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.specNavy,
            ),
          ),
          const SizedBox(height: 12),
          _OverviewUpsellCard(
            title: 'Local+',
            tagline: 'Up to 3 deals, scheduling, and form submissions.',
            icon: Icons.workspace_premium_rounded,
            onTap: () => _showPlanExplainer(context, 'Local+', _localPlusExplainer),
          ),
          const SizedBox(height: 10),
          _OverviewUpsellCard(
            title: 'Local Partner',
            tagline: 'Unlimited deals, Flash & Member-only deals, loyalty programs, more analytics.',
            icon: Icons.star_rounded,
            onTap: () => _showPlanExplainer(context, 'Local Partner', _localPartnerExplainer),
          ),
        ],
        // Local+: minimal analytics (4 stat cards)
        if (tier == BusinessTier.localPlus)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 400 ? 2 : 1;
              final stats = [
                ('Profile views', '—', Icons.visibility_rounded),
                ('Saves', '—', Icons.favorite_rounded),
                ('Deal redemptions', '—', Icons.local_offer_rounded),
                ('Messages', '—', Icons.inbox_rounded),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats.map((s) => SizedBox(
                  width: crossCount == 2 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                  child: _StatCard(label: s.$1, value: s.$2, icon: s.$3),
                )).toList(),
              );
            },
          ),
        // Partner: more analytics (6 stat cards)
        if (tier == BusinessTier.localPartner)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 400 ? 2 : 1;
              final stats = [
                ('Profile views', '—', Icons.visibility_rounded),
                ('Saves', '—', Icons.favorite_rounded),
                ('Deal redemptions', '—', Icons.local_offer_rounded),
                ('Punch card activations', '—', Icons.loyalty_rounded),
                ('Member-only redemptions', '—', Icons.card_membership_rounded),
                ('Messages', '—', Icons.inbox_rounded),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats.map((s) => SizedBox(
                  width: crossCount == 2 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                  child: _StatCard(label: s.$1, value: s.$2, icon: s.$3),
                )).toList(),
              );
            },
          ),
      ],
    );
  }
}

const String _localPlusExplainer =
    'Local+ gives you up to 3 active deals, the ability to schedule deal start and end dates, '
    'and access to form submissions so you can reply to customers who contact you through your listing. '
    'Upgrade from the More tab or contact support.';

const String _localPartnerExplainer =
    'Local Partner unlocks unlimited deals, Flash Deals, Member-only deals, and loyalty (punch card) programs. '
    'You also get full analytics including punch card activations and member-only redemptions. '
    'Upgrade from the More tab or contact support.';

void _showPlanExplainer(BuildContext context, String planName, String body) {
  final theme = Theme.of(context);
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.specOffWhite,
      title: Text(
        planName,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.specNavy,
        ),
      ),
      content: Text(
        body,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.specNavy.withValues(alpha: 0.85),
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Maybe later', style: TextStyle(color: AppTheme.specNavy.withValues(alpha: 0.7))),
        ),
        AppPrimaryButton(
          onPressed: () {
            Navigator.of(context).pop();
            BusinessTierUpgradeDialog.show(context, message: body, title: planName);
          },
          expanded: false,
          child: const Text('View plans'),
        ),
      ],
    ),
  );
}

/// Paywall when user taps the More tab without a paid business tier. Offers Local+ or Local Partner.
void _showMoreTabPaywall(BuildContext context) {
  final theme = Theme.of(context);
  final nav = AppTheme.specNavy;
  final sub = nav.withValues(alpha: 0.85);
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.specOffWhite,
      title: Row(
        children: [
          Icon(Icons.lock_rounded, color: AppTheme.specGold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unlock the More tab',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: nav,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Upgrade to Local+ or Local Partner to access photo carousel, custom links, contact form, and more.',
            style: theme.textTheme.bodyMedium?.copyWith(color: sub, height: 1.4),
          ),
          const SizedBox(height: 20),
          AppSecondaryButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showPlanExplainer(context, 'Local+', _localPlusExplainer);
            },
            icon: const Icon(Icons.workspace_premium_rounded, size: 20),
            label: const Text('Local+'),
          ),
          const SizedBox(height: 10),
          AppPrimaryButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showPlanExplainer(context, 'Local Partner', _localPartnerExplainer);
            },
            expanded: false,
            icon: const Icon(Icons.star_rounded, size: 20),
            label: const Text('Local Partner'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text('Not now', style: TextStyle(color: nav.withValues(alpha: 0.7))),
        ),
      ],
    ),
  );
}

class _OverviewUpsellCard extends StatelessWidget {
  const _OverviewUpsellCard({
    required this.title,
    required this.tagline,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String tagline;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.specNavy, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tagline,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.info_outline_rounded, color: AppTheme.specGold, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.specGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.specNavy, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.specNavy,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.specNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsTab extends StatefulWidget {
  const _DetailsTab({
    required this.listing,
    required this.listingId,
    required this.onSaveRequested,
  });

  final MockListing listing;
  final String listingId;
  final VoidCallback onSaveRequested;

  @override
  State<_DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<_DetailsTab> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;

  List<MockCategory> _categories = [];
  List<MockParish> _parishes = [];
  List<String> _initialSubcategoryIds = [];
  bool _categoriesLoaded = false;
  bool _parishesLoaded = false;
  bool _subcategoryIdsLoaded = false;
  String? _selectedCategoryId;
  final Set<String> _selectedSubcategoryIds = {};
  String? _selectedParishId;
  final Set<String> _selectedServiceParishIds = {};
  Future<Business?>? _businessFuture;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _nameController = TextEditingController(text: l.name);
    _addressController = TextEditingController(text: l.address ?? '');
    _phoneController = TextEditingController(text: l.phone ?? '');
    _websiteController = TextEditingController(text: l.website ?? '');
    _descriptionController = TextEditingController(text: l.description);
    _selectedCategoryId = l.categoryId;
    _selectedParishId = l.parishId;
    _selectedServiceParishIds.addAll(l.parishIds.where((p) => p != l.parishId));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_categoriesLoaded && _categories.isEmpty) {
      _loadCategories();
    }
    if (!_parishesLoaded) {
      _loadParishes();
    }
    if (!_subcategoryIdsLoaded) {
      _loadInitialSubcategoryIds();
    }
    if (SupabaseConfig.isConfigured && _businessFuture == null) {
      _businessFuture = BusinessRepository().getByIdForManager(widget.listingId);
    }
  }

  Future<void> _loadCategories() async {
    final ds = AppDataScope.of(context).dataSource;
    final list = await ds.getCategories();
    if (mounted) {
      setState(() {
        _categories = list;
        _categoriesLoaded = true;
        if (_selectedCategoryId == null && list.isNotEmpty) {
          _selectedCategoryId = list.first.id;
        }
      });
    }
  }

  Future<void> _loadParishes() async {
    final ds = AppDataScope.of(context).dataSource;
    final list = await ds.getParishes();
    if (mounted) {
      setState(() {
        _parishes = list;
        _parishesLoaded = true;
      });
    }
  }

  Future<void> _loadInitialSubcategoryIds() async {
    final ds = AppDataScope.of(context).dataSource;
    if (!ds.useSupabase) {
      if (mounted) setState(() => _subcategoryIdsLoaded = true);
      return;
    }
    final ids = await ds.getSubcategoryIdsForBusiness(widget.listingId);
    if (mounted) {
      setState(() {
        _initialSubcategoryIds = ids;
        _selectedSubcategoryIds.addAll(ids);
        _subcategoryIdsLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    final l = widget.listing;
    _nameController.text = l.name;
    _addressController.text = l.address ?? '';
    _phoneController.text = l.phone ?? '';
    _websiteController.text = l.website ?? '';
    _descriptionController.text = l.description;
    setState(() {
      _selectedCategoryId = l.categoryId;
      _selectedSubcategoryIds.clear();
      _selectedSubcategoryIds.addAll(_initialSubcategoryIds);
      _selectedParishId = l.parishId;
      _selectedServiceParishIds.clear();
      _selectedServiceParishIds.addAll(l.parishIds.where((p) => p != l.parishId));
      _isEditing = false;
    });
  }

  Future<void> _saveEdits() async {
    final ds = AppDataScope.of(context).dataSource;
    if (ds.useSupabase) {
      await ds.updateBusiness(
        widget.listingId,
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        parish: _selectedParishId,
        parishIds: _selectedServiceParishIds.toList(),
      );
      await ds.setBusinessSubcategories(widget.listingId, _selectedSubcategoryIds.toList());
    }
    if (mounted) {
      setState(() {
        _initialSubcategoryIds = _selectedSubcategoryIds.toList();
        _isEditing = false;
      });
      widget.onSaveRequested();
    }
  }

  void _onCategoryChanged(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSubcategoryIds.clear();
    });
  }

  void _toggleSubcategory(String id) {
    setState(() {
      if (_selectedSubcategoryIds.contains(id)) {
        _selectedSubcategoryIds.remove(id);
      } else {
        _selectedSubcategoryIds.add(id);
      }
    });
  }

  String _parishName(String id) {
    final p = _parishes.where((p) => p.id == id).firstOrNull;
    return p?.name ?? id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listing = widget.listing;
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);
    MockCategory? selectedCat;
    for (final c in _categories) {
      if (c.id == _selectedCategoryId) {
        selectedCat = c;
        break;
      }
    }
    final subcategories = selectedCat?.subcategories ?? <MockSubcategory>[];

    return ListView(
      padding: AppLayout.padding(context, top: 20, bottom: 28),
      children: [
        // Header with edit / save actions
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: nav,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditing ? 'Update your listing info below' : 'View and edit your business information',
                      style: theme.textTheme.bodySmall?.copyWith(color: sub),
                    ),
                  ],
                ),
              ),
              if (!_isEditing)
                AppSecondaryButton(
                  onPressed: _startEditing,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit'),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _cancelEditing,
                      child: Text('Cancel', style: TextStyle(color: sub, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    AppPrimaryButton(
                      onPressed: () => _saveEdits(),
                      expanded: false,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Save changes'),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (_isEditing) ...[
          AppSectionCard(
            title: 'Basic info',
            icon: Icons.business_rounded,
            children: [
              _EditField(label: 'Business name', controller: _nameController, hint: 'How your business appears to customers', specNavy: nav, specSub: sub),
              _EditField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 4,
                hint: 'A short description of what you offer',
                specNavy: nav,
                specSub: sub,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            title: 'Contact & location',
            icon: Icons.location_on_outlined,
            children: [
              _EditField(label: 'Address', controller: _addressController, hint: 'Street address', specNavy: nav, specSub: sub),
              _EditField(label: 'Phone', controller: _phoneController, hint: 'Contact number', specNavy: nav, specSub: sub),
              _EditField(label: 'Website', controller: _websiteController, hint: 'https://...', specNavy: nav, specSub: sub),
            ],
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            title: 'Parish',
            icon: Icons.map_rounded,
            children: [
              Text(
                'Primary parish',
                style: theme.textTheme.labelMedium?.copyWith(color: sub, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedParishId),
                initialValue: _parishes.any((p) => p.id == _selectedParishId) ? _selectedParishId : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.specWhite,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                dropdownColor: AppTheme.specWhite,
                hint: Text('Select parish', style: TextStyle(color: sub)),
                items: _parishes.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: TextStyle(color: nav)))).toList(),
                onChanged: (v) => setState(() => _selectedParishId = v),
              ),
              const SizedBox(height: 16),
              Text(
                'Also serves these parishes (service-based businesses)',
                style: theme.textTheme.labelMedium?.copyWith(color: sub, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _parishes.map((p) {
                  final isPrimary = p.id == _selectedParishId;
                  final selected = _selectedServiceParishIds.contains(p.id);
                  return FilterChip(
                    label: Text(p.name, style: TextStyle(color: (selected || isPrimary) ? nav : sub)),
                    selected: selected,
                    onSelected: isPrimary ? null : (_) {
                      setState(() {
                        if (_selectedServiceParishIds.contains(p.id)) {
                          _selectedServiceParishIds.remove(p.id);
                        } else {
                          _selectedServiceParishIds.add(p.id);
                        }
                      });
                    },
                    selectedColor: AppTheme.specGold.withValues(alpha: 0.35),
                    checkmarkColor: nav,
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            title: 'Category',
            icon: Icons.category_rounded,
            children: [
              Text(
                'Primary category',
                style: theme.textTheme.labelMedium?.copyWith(color: sub, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (!_categoriesLoaded)
                const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)))
              else
                DropdownButtonFormField<String>(
                  initialValue: _categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.specWhite,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  dropdownColor: AppTheme.specWhite,
                  items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: TextStyle(color: nav)))).toList(),
                  onChanged: _onCategoryChanged,
                ),
              if (_selectedCategoryId != null && subcategories.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Tags (optional)',
                  style: theme.textTheme.labelMedium?.copyWith(color: sub, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subcategories.map((s) {
                    final selected = _selectedSubcategoryIds.contains(s.id);
                    return FilterChip(
                      label: Text(s.name, style: TextStyle(color: selected ? nav : sub)),
                      selected: selected,
                      onSelected: (_) => _toggleSubcategory(s.id),
                      selectedColor: AppTheme.specGold.withValues(alpha: 0.35),
                      checkmarkColor: nav,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ] else ...[
          AppSectionCard(
            title: 'Basic info',
            icon: Icons.business_rounded,
            children: [
              _DetailRow(label: 'Business name', value: listing.name, specNavy: nav, specSub: sub),
              _DetailRow(label: 'Description', value: listing.description, specNavy: nav, specSub: sub),
            ],
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            title: 'Contact & location',
            icon: Icons.location_on_outlined,
            children: [
              if (listing.address != null && listing.address!.isNotEmpty)
                _DetailRow(label: 'Address', value: listing.address!, specNavy: nav, specSub: sub),
              if (listing.phone != null && listing.phone!.isNotEmpty)
                _DetailRow(label: 'Phone', value: listing.phone!, specNavy: nav, specSub: sub),
              if (listing.website != null && listing.website!.isNotEmpty)
                _DetailRow(label: 'Website', value: listing.website!, specNavy: nav, specSub: sub),
              if ((listing.address == null || listing.address!.isEmpty) &&
                  (listing.phone == null || listing.phone!.isEmpty) &&
                  (listing.website == null || listing.website!.isEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'No contact info yet. Tap Edit to add.',
                    style: theme.textTheme.bodySmall?.copyWith(color: sub),
                  ),
                ),
            ],
          ),
          if (listing.parishId != null || listing.parishIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            AppSectionCard(
              title: 'Parish',
              icon: Icons.map_rounded,
              children: [
                if (listing.parishId != null)
                  _DetailRow(
                    label: 'Primary parish',
                    value: _parishName(listing.parishId!),
                    specNavy: nav,
                    specSub: sub,
                  ),
                if (listing.parishIds.any((id) => id != listing.parishId)) ...[
                  if (listing.parishId != null) const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Also serves',
                    value: listing.parishIds.where((id) => id != listing.parishId).map((id) => _parishName(id)).join(', '),
                    specNavy: nav,
                    specSub: sub,
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
          AppSectionCard(
            title: 'Category',
            icon: Icons.category_rounded,
            children: [
              _DetailRow(label: 'Category', value: listing.categoryName, specNavy: nav, specSub: sub),
            ],
          ),
        ],
        if (SupabaseConfig.isConfigured) ...[
          const SizedBox(height: 16),
          AppSectionCard(
            title: 'Hours',
            icon: Icons.schedule_rounded,
            children: [
              BusinessHoursEditor(businessId: widget.listingId),
            ],
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            title: 'Amenities',
            icon: Icons.check_circle_outline_rounded,
            children: [
              BusinessAmenitiesEditor(
                businessId: widget.listingId,
                categoryBucket: selectedCat?.bucket,
                onSaved: widget.onSaveRequested,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<Business?>(
            future: _businessFuture,
            builder: (context, snap) {
              final business = snap.data;
              return AppSectionCard(
                title: 'Logo & cover',
                icon: Icons.image_rounded,
                children: [
                  _LogoAndBannerSection(
                    business: business,
                    listingId: widget.listingId,
                    onLogoUpdated: () {
                      setState(() {
                        _businessFuture = BusinessRepository().getByIdForManager(widget.listingId);
                      });
                    },
                    onSaveRequested: widget.onSaveRequested,
                    specNavy: nav,
                    specSub: sub,
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Logo upload + cover photo button for Details tab.
class _LogoAndBannerSection extends StatefulWidget {
  const _LogoAndBannerSection({
    required this.business,
    required this.listingId,
    required this.onLogoUpdated,
    required this.onSaveRequested,
    required this.specNavy,
    required this.specSub,
  });

  final Business? business;
  final String listingId;
  final VoidCallback onLogoUpdated;
  final VoidCallback onSaveRequested;
  final Color specNavy;
  final Color specSub;

  @override
  State<_LogoAndBannerSection> createState() => _LogoAndBannerSectionState();
}

class _LogoAndBannerSectionState extends State<_LogoAndBannerSection> {
  bool _uploadingLogo = false;
  bool _uploadingBanner = false;
  List<BusinessImage> _galleryImages = [];
  bool _galleryLoading = true;
  bool _uploadingGallery = false;
  bool _savingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadGalleryImages();
  }

  Future<void> _loadGalleryImages() async {
    final list = await BusinessImagesRepository().listForBusiness(widget.listingId);
    if (mounted) {
      setState(() {
        _galleryImages = list;
        _galleryLoading = false;
      });
    }
  }

  Future<void> _addGalleryImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedImageExtensions,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file.')),
        );
      }
      return;
    }
    final ext = file.extension ?? 'jpg';
    setState(() => _uploadingGallery = true);
    try {
      final url = await BusinessImagesStorageService().upload(
        businessId: widget.listingId,
        type: 'gallery',
        bytes: bytes,
        extension: ext,
      );
      if (!mounted) return;
      final auth = AppDataScope.of(context).authRepository;
      final uid = auth.currentUserId;
      final isAdmin = uid != null && await auth.isAdmin();
      await BusinessImagesRepository().insert(
        businessId: widget.listingId,
        url: url,
        sortOrder: _galleryImages.length,
        approvedBy: isAdmin ? uid : null,
      );
      if (!mounted) return;
      await _loadGalleryImages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAdmin ? 'Photo added (approved).' : 'Photo added. It will appear after admin approval.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingGallery = false);
      }
    }
  }

  Future<void> _onGalleryReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final reordered = List<BusinessImage>.from(_galleryImages);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    final orderedIds = reordered.map((e) => e.id).toList();
    setState(() => _savingOrder = true);
    try {
      await BusinessImagesRepository().updateSortOrder(orderedIds);
      if (mounted) {
        setState(() {
          _galleryImages = reordered;
          _savingOrder = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save order: $e')),
        );
      }
    }
  }

  Future<void> _uploadLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedImageExtensions,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file.')),
        );
      }
      return;
    }
    final ext = file.extension ?? 'jpg';
    setState(() => _uploadingLogo = true);
    try {
      final url = await BusinessImagesStorageService().upload(
        businessId: widget.listingId,
        type: 'logo',
        bytes: bytes,
        extension: ext,
      );
      await BusinessRepository().updateBusiness(widget.listingId, logoUrl: url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo updated.')));
        widget.onLogoUpdated();
        widget.onSaveRequested();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _uploadBanner() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedImageExtensions,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file.')),
        );
      }
      return;
    }
    final ext = file.extension ?? 'jpg';
    setState(() => _uploadingBanner = true);
    try {
      final url = await BusinessImagesStorageService().upload(
        businessId: widget.listingId,
        type: 'banner',
        bytes: bytes,
        extension: ext,
      );
      await BusinessRepository().updateBusiness(widget.listingId, bannerUrl: url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner updated.')));
        widget.onLogoUpdated();
        widget.onSaveRequested();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingBanner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final business = widget.business;
    final nav = widget.specNavy;
    final sub = widget.specSub;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Logo (your upload)',
          style: theme.textTheme.labelMedium?.copyWith(color: sub, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (business?.logoUrl != null && business!.logoUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              business.logoUrl!,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 80,
                width: 80,
                color: nav.withValues(alpha: 0.1),
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        AppOutlinedButton(
          onPressed: _uploadingLogo ? null : _uploadLogo,
          icon: _uploadingLogo
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: nav),
                )
              : const Icon(Icons.upload_rounded, size: 20),
          label: Text(_uploadingLogo ? 'Uploading...' : 'Upload logo'),
        ),
        const SizedBox(height: 20),
        Text(
          'Listing banner (your upload)',
          style: theme.textTheme.labelMedium?.copyWith(color: sub, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Your cover image for this listing (hero on the detail page). Separate from any admin-set banner.',
          style: theme.textTheme.bodySmall?.copyWith(color: sub),
        ),
        const SizedBox(height: 8),
        if (business?.bannerUrl != null && business!.bannerUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              business.bannerUrl!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 160,
                width: double.infinity,
                color: nav.withValues(alpha: 0.1),
                child: const Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        AppOutlinedButton(
          onPressed: _uploadingBanner ? null : _uploadBanner,
          icon: _uploadingBanner
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: nav),
                )
              : const Icon(Icons.image_rounded, size: 20),
          label: Text(_uploadingBanner ? 'Uploading...' : 'Upload banner'),
        ),
        const SizedBox(height: 20),
        Text(
          'Gallery photos',
          style: theme.textTheme.labelMedium?.copyWith(color: sub, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Add photos and drag to reorder. New photos go at the end.',
          style: theme.textTheme.bodySmall?.copyWith(color: sub),
        ),
        const SizedBox(height: 12),
        AppOutlinedButton(
          onPressed: _uploadingGallery ? null : _addGalleryImage,
          icon: _uploadingGallery
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: nav),
                )
              : const Icon(Icons.add_photo_alternate_rounded, size: 20),
          label: Text(_uploadingGallery ? 'Uploading...' : 'Add photo'),
        ),
        if (_galleryLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
          )
        else if (_galleryImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _galleryImages.length,
            onReorder: _onGalleryReorder,
            itemBuilder: (context, index) {
              final img = _galleryImages[index];
              return ReorderableDragStartListener(
                key: ValueKey(img.id),
                index: index,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: nav.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: nav.withValues(alpha: 0.12)),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        img.url,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 56,
                          height: 56,
                          color: nav.withValues(alpha: 0.1),
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                    title: Text(
                      'Photo ${index + 1}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: nav,
                      ),
                    ),
                    subtitle: img.status != 'approved'
                        ? Text(
                            img.status,
                            style: theme.textTheme.bodySmall?.copyWith(color: sub),
                          )
                        : null,
                    trailing: _savingOrder
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.drag_handle_rounded, color: sub),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.hint,
    this.specNavy,
    this.specSub,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;
  final Color? specNavy;
  final Color? specSub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelColor = specSub ?? colorScheme.onSurfaceVariant;
    final nav = specNavy ?? colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(color: labelColor.withValues(alpha: 0.9)),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: theme.textTheme.bodyLarge?.copyWith(color: nav),
            decoration: InputDecoration(
              hintText: hint ?? 'Enter $label',
              filled: true,
              fillColor: AppTheme.specWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: nav.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: nav.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.specGold, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.specNavy,
    this.specSub,
  });

  final String label;
  final String value;
  final Color? specNavy;
  final Color? specSub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelColor = specSub ?? colorScheme.onSurfaceVariant;
    final valueColor = specNavy ?? colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: labelColor),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _MenuTab extends StatefulWidget {
  const _MenuTab({required this.listingId, required this.items});

  final String listingId;
  final List<MockMenuItem> items;

  @override
  State<_MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<_MenuTab> {
  List<MenuSection> _sections = [];
  Map<String, List<MenuItem>> _itemsBySection = {};
  bool _loading = true;
  bool _useSupabase = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final useSupabase = AppDataScope.of(context).dataSource.useSupabase;
    if (useSupabase != _useSupabase || _loading) {
      _useSupabase = useSupabase;
      if (useSupabase) {
        _loadMenu();
      } else {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMenu() async {
    setState(() => _loading = true);
    final sections = await MenuRepository().getSectionsForBusiness(widget.listingId);
    final itemsBySection = <String, List<MenuItem>>{};
    for (final s in sections) {
      itemsBySection[s.id] = await MenuRepository().getItemsForSection(s.id);
    }
    if (mounted) {
      setState(() {
        _sections = sections;
        _itemsBySection = itemsBySection;
        _loading = false;
      });
    }
  }

  Future<void> _addCategory() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _AddCategoryDialog(),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    try {
      await MenuRepository().createSection(widget.listingId, name.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category added')));
        _loadMenu();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addItem(MenuSection section) async {
    final result = await showDialog<({String name, String? price, String? description})>(
      context: context,
      builder: (ctx) => _AddMenuItemDialog(sectionName: section.name),
    );
    if (result == null || result.name.trim().isEmpty || !mounted) return;
    try {
      await MenuRepository().insertItem(
        sectionId: section.id,
        name: result.name.trim(),
        price: result.price?.trim().isEmpty ?? true ? null : result.price?.trim(),
        description: result.description?.trim().isEmpty ?? true ? null : result.description?.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added')));
        _loadMenu();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);

    if (!_useSupabase) {
      return _buildLegacyMenu(theme, nav, sub);
    }

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: nav));
    }

    return ListView(
      padding: AppLayout.padding(context, top: 20, bottom: 28),
      children: [
        Text(
          'Menu',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: nav,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Create categories first, then add items to each. Tap any name to edit in place.',
          style: theme.textTheme.bodyMedium?.copyWith(color: sub),
        ),
        const SizedBox(height: 20),
        AppOutlinedButton(
          onPressed: _addCategory,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text('Add category'),
        ),
        const SizedBox(height: 24),
        if (_sections.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: nav.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.category_outlined, size: 48, color: nav.withValues(alpha: 0.4)),
                const SizedBox(height: 14),
                Text(
                  'No categories yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: nav,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap "Add category" to create your first section (e.g. Products, Services, Packages), then add items to it.',
                  style: theme.textTheme.bodySmall?.copyWith(color: sub),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._sections.map((section) {
            final items = _itemsBySection[section.id] ?? [];
            return _MenuSectionCard(
              key: ValueKey(section.id),
              section: section,
              items: items,
              onSectionNameSaved: (name) async {
                await MenuRepository().updateSection(section.id, name: name);
                _loadMenu();
              },
              onAddItem: () => _addItem(section),
              onItemUpdated: () => _loadMenu(),
            );
          }),
      ],
    );
  }

  Widget _buildLegacyMenu(ThemeData theme, Color nav, Color sub) {
    final items = widget.items;
    return ListView(
      padding: AppLayout.padding(context, top: 20, bottom: 28),
      children: [
        Text(
          'Menu',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: nav,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Organize your offerings by category—products, services, or both—and edit in place.',
          style: theme.textTheme.bodyMedium?.copyWith(color: sub),
        ),
        const SizedBox(height: 20),
        AppSecondaryButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CreateMenuItemScreen(listingId: widget.listingId),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add item'),
        ),
        const SizedBox(height: 24),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: nav.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.view_list_rounded, size: 48, color: nav.withValues(alpha: 0.4)),
                const SizedBox(height: 14),
                Text('No items yet', style: theme.textTheme.titleMedium?.copyWith(color: nav, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Tap "Add item" above.', style: theme.textTheme.bodySmall?.copyWith(color: sub), textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ...items.map((item) {
            final subtitle = [if (item.description != null) item.description!, if (item.price != null) item.price!].join(' · ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DealPunchCard(
                icon: Icons.view_list_rounded,
                title: item.name,
                subtitle: subtitle.isEmpty ? 'No description' : subtitle,
              ),
            );
          }),
      ],
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New category'),
      content: TextField(
        controller: _controller,
        focusNode: _focus,
        decoration: const InputDecoration(
          labelText: 'Category name',
          hintText: 'e.g. Products, Services, Packages',
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        AppSecondaryButton(
          onPressed: () => _submit(),
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }
}

class _AddMenuItemDialog extends StatefulWidget {
  const _AddMenuItemDialog({required this.sectionName});

  final String sectionName;

  @override
  State<_AddMenuItemDialog> createState() => _AddMenuItemDialogState();
}

class _AddMenuItemDialogState extends State<_AddMenuItemDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add item to ${widget.sectionName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item name',
                hintText: 'e.g. Product or service name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (optional)',
                hintText: 'e.g. \$12',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        AppSecondaryButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              Navigator.of(context).pop((
                name: name,
                price: _priceController.text.trim().isEmpty ? null : _priceController.text.trim(),
                description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
              ));
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _MenuSectionCard extends StatefulWidget {
  const _MenuSectionCard({
    super.key,
    required this.section,
    required this.items,
    required this.onSectionNameSaved,
    required this.onAddItem,
    required this.onItemUpdated,
  });

  final MenuSection section;
  final List<MenuItem> items;
  final void Function(String name) onSectionNameSaved;
  final VoidCallback onAddItem;
  final VoidCallback onItemUpdated;

  @override
  State<_MenuSectionCard> createState() => _MenuSectionCardState();
}

class _MenuSectionCardState extends State<_MenuSectionCard> {
  bool _editingSectionName = false;
  final _sectionNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sectionNameController.text = widget.section.name;
  }

  @override
  void didUpdateWidget(_MenuSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.name != widget.section.name) {
      _sectionNameController.text = widget.section.name;
    }
  }

  @override
  void dispose() {
    _sectionNameController.dispose();
    super.dispose();
  }

  void _startEditingSection() {
    setState(() {
      _editingSectionName = true;
      _sectionNameController.text = widget.section.name;
      _sectionNameController.selection = TextSelection(baseOffset: 0, extentOffset: _sectionNameController.text.length);
    });
  }

  void _saveSectionName() {
    final name = _sectionNameController.text.trim();
    if (name.isNotEmpty && name != widget.section.name) {
      widget.onSectionNameSaved(name);
    }
    setState(() => _editingSectionName = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: nav.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _editingSectionName
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _sectionNameController,
                              autofocus: true,
                              decoration: InputDecoration(
                                isDense: true,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: nav),
                              onSubmitted: (_) => _saveSectionName(),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => setState(() => _editingSectionName = false),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                AppSecondaryButton(
                                  onPressed: _saveSectionName,
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ],
                        )
                      : InkWell(
                          onTap: _startEditingSection,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.category_rounded, size: 22, color: nav.withValues(alpha: 0.8)),
                                const SizedBox(width: 10),
                                Text(
                                  widget.section.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: nav,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.edit_rounded, size: 16, color: sub),
                              ],
                            ),
                          ),
                        ),
                ),
                TextButton.icon(
                  onPressed: widget.onAddItem,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add item'),
                  style: TextButton.styleFrom(foregroundColor: nav),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: widget.items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No items yet. Tap "Add item" to add one.',
                      style: theme.textTheme.bodySmall?.copyWith(color: sub),
                    ),
                  )
                : Column(
                    children: widget.items.map((item) {
                      return _MenuItemRow(
                        key: ValueKey(item.id),
                        item: item,
                        onUpdated: widget.onItemUpdated,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemRow extends StatefulWidget {
  const _MenuItemRow({super.key, required this.item, required this.onUpdated});

  final MenuItem item;
  final VoidCallback onUpdated;

  @override
  State<_MenuItemRow> createState() => _MenuItemRowState();
}

class _MenuItemRowState extends State<_MenuItemRow> {
  bool _editing = false;
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(text: widget.item.price ?? '');
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
  }

  @override
  void didUpdateWidget(_MenuItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _nameController.text = widget.item.name;
      _priceController.text = widget.item.price ?? '';
      _descriptionController.text = widget.item.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    try {
      await MenuRepository().updateItem(
        widget.item.id,
        name: name,
        price: _priceController.text.trim().isEmpty ? null : _priceController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );
      if (mounted) {
        setState(() => _editing = false);
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);

    if (_editing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(color: nav),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: TextButton(
                    onPressed: () => setState(() => _editing = false),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.specOffWhite,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => setState(() => _editing = true),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: nav.withValues(alpha: 0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Icon(Icons.restaurant_rounded, size: 20, color: nav.withValues(alpha: 0.6)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: nav,
                      ),
                    ),
                    if ((widget.item.price ?? '').isNotEmpty || (widget.item.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if ((widget.item.price ?? '').isNotEmpty) widget.item.price,
                          if ((widget.item.description ?? '').isNotEmpty) widget.item.description,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(color: sub),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.edit_rounded, size: 18, color: sub),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DealsTab extends StatelessWidget {
  const _DealsTab({
    required this.listingId,
    required this.deals,
    required this.punchCards,
    this.businessTier,
    this.activeDealCount = 0,
    this.onRefresh,
  });

  final String listingId;
  final List<MockDeal> deals;
  final List<MockPunchCard> punchCards;
  final String? businessTier;
  final int activeDealCount;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useSupabase = AppDataScope.of(context).dataSource.useSupabase;
    final tier = BusinessTierService.fromPlanTier(businessTier);
    final atDealLimit = useSupabase &&
        activeDealCount >= BusinessTierService.maxActiveDeals(tier);
    final canCreatePunchCard = !useSupabase ||
        BusinessTierService.canCreatePunchCard(tier);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Deals & punch cards',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Create coupons and loyalty punch cards. New items require admin approval before they go live.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.specNavy.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AppSecondaryButton(
              onPressed: () {
                if (atDealLimit) {
                  BusinessTierUpgradeDialog.show(
                    context,
                    message: BusinessTierService.upgradeMessageForDealLimit(tier),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CreateDealScreen(listingId: listingId),
                  ),
                ).then((_) => onRefresh?.call());
              },
              icon: Icon(
                atDealLimit ? Icons.lock_outline_rounded : Icons.local_offer_rounded,
                size: 20,
              ),
              label: Text(atDealLimit ? 'Deal limit reached' : 'Add deal'),
            ),
            AppSecondaryButton(
              onPressed: () {
                if (!canCreatePunchCard) {
                  BusinessTierUpgradeDialog.show(
                    context,
                    message: BusinessTierService.upgradeMessageForAdvancedFeatures(),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CreateLoyaltyScreen(listingId: listingId),
                  ),
                ).then((_) => onRefresh?.call());
              },
              icon: Icon(
                canCreatePunchCard ? Icons.loyalty_rounded : Icons.lock_outline_rounded,
                size: 20,
              ),
              label: Text(
                canCreatePunchCard ? 'Add punch card' : 'Upgrade for punch cards',
              ),
            ),
            if (useSupabase)
              AppOutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PunchCardEnrollmentsScreen(businessId: listingId),
                    ),
                  ).then((_) => onRefresh?.call());
                },
                icon: const Icon(Icons.people_outline_rounded, size: 20),
                label: const Text('View enrollments'),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (deals.isNotEmpty) ...[
          Text(
            'Deals (${deals.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.specNavy,
            ),
          ),
          const SizedBox(height: 10),
          ...deals.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DealPunchCard(
                  icon: Icons.local_offer_rounded,
                  title: d.title,
                  subtitle: d.description,
                  dealId: useSupabase ? d.id : null,
                  onRefresh: onRefresh,
                ),
              )),
          const SizedBox(height: 20),
        ],
        if (punchCards.isNotEmpty) ...[
          Text(
            'Punch cards (${punchCards.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.specNavy,
            ),
          ),
          const SizedBox(height: 10),
          ...punchCards.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DealPunchCard(
                  icon: Icons.loyalty_rounded,
                  title: p.title,
                  subtitle: '${p.punchesEarned}/${p.punchesRequired} punches — ${p.rewardDescription}',
                  punchCardId: useSupabase ? p.id : null,
                  onRefresh: onRefresh,
                ),
              )),
        ],
        if (deals.isEmpty && punchCards.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.local_offer_outlined, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.4)),
                const SizedBox(height: 14),
                Text(
                  'No deals or punch cards yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.specNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use the buttons above to create a deal or a punch card. They’ll need admin approval before going live.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.75),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DealPunchCard extends StatelessWidget {
  const _DealPunchCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.dealId,
    this.punchCardId,
    this.onRefresh,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? dealId;
  final String? punchCardId;
  final VoidCallback? onRefresh;

  Future<void> _onDeletePressed(BuildContext context) async {
    final isDeal = dealId != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDeal ? 'Remove this deal?' : 'Remove this loyalty card?'),
        content: Text(
          isDeal
              ? 'This deal will be removed. Customers will no longer see it.'
              : 'This punch card will be removed. Existing customer progress cannot be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          AppDangerButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (dealId != null) {
        await DealsRepository().deleteForManager(dealId!);
      } else if (punchCardId != null) {
        await PunchCardProgramsRepository().deleteForManager(punchCardId!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isDeal ? 'Deal removed' : 'Loyalty card removed')),
        );
        onRefresh?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDelete = (dealId != null || punchCardId != null) && onRefresh != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.specGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.specNavy, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.specNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.75),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 22),
              color: AppTheme.specRed,
              tooltip: dealId != null ? 'Remove deal' : 'Remove loyalty card',
              onPressed: () => _onDeletePressed(context),
            ),
        ],
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({
    required this.listingId,
    required this.events,
  });

  final String listingId;
  final List<MockEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Events',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${events.length} event(s). Events are visible to customers after approval.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.specNavy.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 20),
        AppSecondaryButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CreateEventScreen(listingId: listingId),
              ),
            );
          },
          icon: const Icon(Icons.event_rounded, size: 20),
          label: const Text('Add event'),
        ),
        const SizedBox(height: 24),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.event_outlined, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.4)),
                const SizedBox(height: 14),
                Text(
                  'No events yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.specNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap "Add event" above to create your first event.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.75),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...events.map((e) {
            final dateStr =
                '${e.eventDate.year}-${e.eventDate.month.toString().padLeft(2, '0')}-${e.eventDate.day.toString().padLeft(2, '0')}';
            final statusLabel = e.status == 'pending' ? ' (pending approval)' : '';
            final subtitle =
                '$dateStr${e.location != null ? ' · ${e.location}' : ''}$statusLabel';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EventDetailScreen(
                          eventId: e.id,
                          listingId: listingId,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: _DealPunchCard(
                    icon: Icons.event_rounded,
                    title: e.title,
                    subtitle: subtitle,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

/// Shown when Messages tab is selected but business is not on a paid tier; prompts upgrade to view and reply to messages.
class _FormSubmissionsPaywallTab extends StatelessWidget {
  const _FormSubmissionsPaywallTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const message =
        'Messages are available on Local+ or Local Partner plans. Upgrade to view and reply to contact form messages from this listing.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/local+.png',
              height: 64,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(Icons.lock_outline_rounded, size: 56, color: AppTheme.specGold),
            ),
            const SizedBox(height: 16),
            Text(
              'Messages',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.specNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.specNavy.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 24),
            AppSecondaryButton(
              onPressed: () {
                BusinessTierUpgradeDialog.show(
                  context,
                  message: message,
                );
              },
              icon: const Icon(Icons.workspace_premium_rounded, size: 20),
              label: const Text('View plans'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab({required this.listingId, required this.hasPaidTier});

  final String listingId;
  final bool hasPaidTier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.8);

    if (!hasPaidTier) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Premium features',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: nav,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Unlock with a paid business plan.',
            style: theme.textTheme.bodyMedium?.copyWith(color: sub),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/local+.png',
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(Icons.monetization_on_rounded, color: AppTheme.specGold, size: 28),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Upgrade to unlock',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: nav,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Photo carousel — Show multiple images on your listing.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: sub),
                ),
                const SizedBox(height: 8),
                Text(
                  'Custom links — Add social and website links.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: sub),
                ),
                const SizedBox(height: 20),
                AppPrimaryButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact support or go to Billing to upgrade your plan.')),
                    );
                  },
                  expanded: false,
                  icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                  label: const Text('Learn about plans'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Premium options',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: nav,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Photo carousel, custom links, and contact form.',
          style: theme.textTheme.bodyMedium?.copyWith(color: sub),
        ),
        const SizedBox(height: 24),
        _MoreSection(
          title: 'Photo carousel',
          icon: Icons.image_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add and manage photos for your listing. They appear on your public page.',
                style: theme.textTheme.bodySmall?.copyWith(color: sub),
              ),
              const SizedBox(height: 12),
              if (SupabaseConfig.isConfigured)
                Text(
                  'Add and reorder photos on the Details tab.',
                  style: theme.textTheme.bodySmall?.copyWith(color: sub),
                )
              else
                Text(
                  'Add photos to showcase your business.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: sub,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (SupabaseConfig.isConfigured) ...[
          _AdvertisingSection(
            listingId: listingId,
            theme: theme,
            nav: nav,
            sub: sub,
          ),
          const SizedBox(height: 20),
          _MoreSection(
            title: 'Custom links',
            icon: Icons.link_rounded,
            child: BusinessLinksEditor(businessId: listingId),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _ContactFormTemplateSection(listingId: listingId),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Advertising section for paid-tier owners: how it works, benefits, CTA. Matches upselling style.
class _AdvertisingSection extends StatelessWidget {
  const _AdvertisingSection({
    required this.listingId,
    required this.theme,
    required this.nav,
    required this.sub,
  });

  final String listingId;
  final ThemeData theme;
  final Color nav;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.campaign_rounded, color: AppTheme.specNavy, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advertising',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: nav,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Promote your business with sponsored placements in Explore and Deals. Tap to buy an ad or view performance.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: sub,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppSecondaryButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BusinessAdsScreen(businessId: listingId),
                ),
              );
            },
            icon: const Icon(Icons.campaign_rounded, size: 20),
            label: const Text('Manage ads'),
          ),
        ],
      ),
    );
  }
}

class _MoreSection extends StatelessWidget {
  const _MoreSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.specNavy, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.specNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ContactFormTemplateSection extends StatefulWidget {
  const _ContactFormTemplateSection({required this.listingId});
  final String listingId;

  @override
  State<_ContactFormTemplateSection> createState() => _ContactFormTemplateSectionState();
}

class _ContactFormTemplateSectionState extends State<_ContactFormTemplateSection> {
  Business? _business;
  bool _loading = true;
  String? _selectedKey;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await BusinessRepository().getByIdForManager(widget.listingId);
    if (mounted) {
      setState(() {
        _business = b;
        _selectedKey = b?.contactFormTemplate;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await BusinessRepository().updateContactFormTemplate(
        widget.listingId,
        _selectedKey?.isEmpty == true ? null : _selectedKey,
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _business = _business != null
              ? Business(
                  id: _business!.id,
                  name: _business!.name,
                  status: _business!.status,
                  categoryId: _business!.categoryId,
                  city: _business!.city,
                  parish: _business!.parish,
                  state: _business!.state,
                  latitude: _business!.latitude,
                  longitude: _business!.longitude,
                  description: _business!.description,
                  address: _business!.address,
                  phone: _business!.phone,
                  website: _business!.website,
                  tagline: _business!.tagline,
                  logoUrl: _business!.logoUrl,
                  contactFormTemplate: _selectedKey,
                  createdAt: _business!.createdAt,
                  updatedAt: _business!.updatedAt,
                )
              : null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact form template saved.')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }
    final current = _selectedKey ?? 'none';
    if (current != 'none' && ContactFormTemplates.getByKey(current) == null) {
      // invalid key
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline_rounded, color: AppTheme.specNavy, size: 22),
              const SizedBox(width: 8),
              Text(
                'Contact form template',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.specNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Choose which form visitors see on your listing.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: current,
            onChanged: (v) => setState(() => _selectedKey = (v == 'none' || v == null) ? null : v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ['none', ...ContactFormTemplates.allKeys].map((key) {
                final label = key == 'none' ? 'None (hide form)' : (ContactFormTemplates.getByKey(key)?.name ?? key);
                return RadioListTile<String>(
                  value: key,
                  title: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy)),
                  fillColor: WidgetStateProperty.resolveWith(
                    (Set<WidgetState> states) =>
                        states.contains(WidgetState.selected)
                            ? AppTheme.specNavy
                            : null,
                  ),
                );
              }).toList(),
            ),
          ),
          if (_selectedKey != null && _selectedKey!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final def = ContactFormTemplates.getByKey(_selectedKey!);
                if (def == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview: fields shown',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...def.fields.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '• ${f.label}${f.required ? ' (required)' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.specNavy.withValues(alpha: 0.9),
                            ),
                          ),
                        )),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          AppSecondaryButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
