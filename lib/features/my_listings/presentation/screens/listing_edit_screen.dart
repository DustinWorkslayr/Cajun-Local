import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/data/contact_form_templates.dart';
import 'package:cajun_local/features/listing/presentation/screens/business_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/businesses/data/models/menu_item.dart';
import 'package:cajun_local/features/businesses/data/models/menu_section.dart';
import 'package:cajun_local/features/businesses/data/repositories/menu_repository.dart';
import 'package:cajun_local/features/deals/data/models/deal.dart';
import 'package:cajun_local/features/deals/data/models/punch_card_program.dart';
import 'package:cajun_local/features/deals/data/repositories/deals_repository.dart';
import 'package:cajun_local/features/deals/data/repositories/punch_card_programs_repository.dart';
import 'package:cajun_local/features/events/data/models/business_event.dart';
import 'package:cajun_local/features/businesses/data/models/business_manager_entry.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_managers_repository.dart';
import 'package:cajun_local/core/subscription/business_tier_service.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/business_tier_upgrade_dialog.dart';
import 'package:cajun_local/core/preferences/owner_onboarding_preferences.dart';
import 'package:cajun_local/features/my_listings/presentation/screens/business_ads_screen.dart';
import 'package:cajun_local/features/my_listings/presentation/screens/create_business_item_screen.dart';
import 'package:cajun_local/features/my_listings/presentation/screens/event_detail_screen.dart';
import 'package:cajun_local/features/my_listings/presentation/screens/form_submissions_inbox_screen.dart';
import 'package:cajun_local/features/my_listings/presentation/screens/punch_card_enrollments_screen.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/business_links_editor.dart';
import 'package:cajun_local/shared/widgets/owner_onboarding_dialog.dart';
import 'package:cajun_local/features/my_listings/presentation/controllers/listing_edit_controller.dart';
import 'package:cajun_local/features/my_listings/presentation/widgets/listing_edit/overview_tab.dart';
import 'package:cajun_local/features/my_listings/presentation/widgets/listing_edit/details_tab.dart';
import 'package:cajun_local/shared/widgets/pending_approval_banner.dart';

/// Tabbed edit/dashboard for a business listing. Tablet: left rail; mobile: tabs. Uses homepage theme (specOffWhite, specNavy, specGold).
class ListingEditScreen extends ConsumerStatefulWidget {
  const ListingEditScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingEditScreen> createState() => _ListingEditScreenState();
}

class _ListingEditScreenState extends ConsumerState<ListingEditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  bool _hasPendingApproval = false;
  bool _ownerOnboardingChecked = false;
  void _refreshListingData() {
    ref.read(listingEditControllerProvider(widget.listingId).notifier).refresh();
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
    });
    _refreshListingData();
  }

  Widget _buildTabContent(
    int index,
    Business listing,
    List<MenuSection> menuItems,
    List<Deal> deals,
    List<PunchCardProgram> punchCards,
    List<BusinessEvent> events,
    String? businessTier,
  ) {
    switch (index) {
      case 0:
        return OverviewTab(listingId: widget.listingId, businessTier: businessTier);
      case 1:
        return DetailsTab(listing: listing, listingId: widget.listingId, onSaveRequested: _onDetailsSaveRequested);
      case 2:
        return _MenuTab(listingId: widget.listingId, items: menuItems);
      case 3:
        final activeDealCount = deals.where((d) => d.isActive ?? false).length;
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
          return FormSubmissionsInboxScreen(singleBusinessId: widget.listingId, embeddedInTab: true);
        }
        return _FormSubmissionsPaywallTab();
      case 6:
        return _MoreTab(listingId: widget.listingId, hasPaidTier: _isPaidBusinessTier(businessTier));
      case 7:
        return _AccountAccessTab(listingId: widget.listingId);
      default:
        return OverviewTab(listingId: widget.listingId, businessTier: businessTier);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = AppLayout.isTablet(context);
    final asyncState = ref.watch(listingEditControllerProvider(widget.listingId));

    return asyncState.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.specOffWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.specOffWhite,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppTheme.specNavy,
          title: Text(
            'Listing',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Scaffold(
        backgroundColor: AppTheme.specOffWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.specOffWhite,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppTheme.specNavy,
          title: Text(
            'Listing',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
          ),
        ),
        body: Center(
          child: Text('Error: $err', style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy)),
        ),
      ),
      data: (state) {
        final listing = state.listing;
        final menuItems = state.menuSections;
        final deals = state.deals;
        final punchCards = state.punchCards;
        final events = state.events;
        final businessTier = state.businessTier;

        if (listing == null) {
          return Scaffold(
            backgroundColor: AppTheme.specOffWhite,
            appBar: AppBar(
              backgroundColor: AppTheme.specOffWhite,
              surfaceTintColor: Colors.transparent,
              foregroundColor: AppTheme.specNavy,
              title: Text(
                'Listing',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
              ),
            ),
            body: Center(
              child: Text('Listing not found', style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy)),
            ),
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
                    if (index == 6 && !_isPaidBusinessTier(businessTier)) {
                      showMoreTabPaywall(context);
                      return;
                    }
                    setState(() => _selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: AppTheme.specGold),
                  selectedLabelTextStyle: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.specNavy,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedIconTheme: IconThemeData(color: AppTheme.specNavy.withValues(alpha: 0.7)),
                  unselectedLabelTextStyle: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.7),
                  ),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Overview')),
                    NavigationRailDestination(icon: Icon(Icons.info_outline_rounded), label: Text('Details')),
                    NavigationRailDestination(icon: Icon(Icons.view_list_rounded), label: Text('Menu')),
                    NavigationRailDestination(icon: Icon(Icons.local_offer_rounded), label: Text('Deals')),
                    NavigationRailDestination(icon: Icon(Icons.event_rounded), label: Text('Events')),
                    NavigationRailDestination(icon: Icon(Icons.inbox_rounded), label: Text('Messages')),
                    NavigationRailDestination(icon: Icon(Icons.monetization_on_rounded), label: Text('More')),
                    NavigationRailDestination(icon: Icon(Icons.people_rounded), label: Text('Team')),
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
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.specNavy,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => BusinessDetailScreen(listingId: widget.listingId),
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
                      if (_hasPendingApproval) const PendingApprovalBanner(),
                      Expanded(
                        child: _buildTabContent(
                          _selectedIndex,
                          listing,
                          menuItems,
                          deals,
                          punchCards,
                          events,
                          businessTier,
                        ),
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
              labelColor: AppTheme.specGold,
              unselectedLabelColor: AppTheme.specNavy.withValues(alpha: 0.6),
              indicatorColor: AppTheme.specGold,
              indicatorWeight: 3,
              onTap: (index) {
                if (index == 6 && !_isPaidBusinessTier(businessTier)) {
                  showMoreTabPaywall(context);
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
                Tab(icon: Icon(Icons.people_rounded, size: 20), text: 'Team'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded),
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => BusinessDetailScreen(listingId: widget.listingId)));
                },
                tooltip: 'View as customer',
                color: AppTheme.specNavy,
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasPendingApproval) const PendingApprovalBanner(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    OverviewTab(listingId: widget.listingId, businessTier: businessTier),
                    DetailsTab(listing: listing, listingId: widget.listingId, onSaveRequested: _onDetailsSaveRequested),
                    _MenuTab(listingId: widget.listingId, items: menuItems),
                    _DealsTab(
                      listingId: widget.listingId,
                      deals: deals,
                      punchCards: punchCards,
                      businessTier: businessTier,
                      activeDealCount: deals.where((d) => d.isActive ?? false).length,
                      onRefresh: _refreshListingData,
                    ),
                    _EventsTab(listingId: widget.listingId, events: events),
                    _isPaidBusinessTier(businessTier)
                        ? FormSubmissionsInboxScreen(singleBusinessId: widget.listingId, embeddedInTab: true)
                        : const _FormSubmissionsPaywallTab(),
                    _MoreTab(listingId: widget.listingId, hasPaidTier: _isPaidBusinessTier(businessTier)),
                    _AccountAccessTab(listingId: widget.listingId),
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

class _MenuTab extends ConsumerStatefulWidget {
  const _MenuTab({required this.listingId, required this.items});

  final String listingId;
  final List<dynamic> items;

  @override
  ConsumerState<_MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends ConsumerState<_MenuTab> {
  List<MenuSection> _sections = [];
  Map<String, List<MenuItem>> _itemsBySection = {};
  bool _loading = true;
  bool _useSupabase = false;

  @override
  void initState() {
    super.initState();
    _loadMenu();
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
    final name = await showDialog<String>(context: context, builder: (ctx) => _AddCategoryDialog());
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
        price: (result.price != null && result.price!.trim().isNotEmpty) ? result.price!.trim() : null,
        description: (result.description != null && result.description!.trim().isNotEmpty)
            ? result.description!.trim()
            : null,
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
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: nav),
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: nav.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.category_outlined, size: 48, color: nav.withValues(alpha: 0.4)),
                const SizedBox(height: 14),
                Text(
                  'No categories yet',
                  style: theme.textTheme.titleMedium?.copyWith(color: nav, fontWeight: FontWeight.w700),
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
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: nav),
        ),
        const SizedBox(height: 6),
        Text(
          'Organize your offerings by category—products, services, or both—and edit in place.',
          style: theme.textTheme.bodyMedium?.copyWith(color: sub),
        ),
        const SizedBox(height: 20),
        AppSecondaryButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => CreateMenuItemScreen(listingId: widget.listingId)));
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
                Text(
                  'No items yet',
                  style: theme.textTheme.titleMedium?.copyWith(color: nav, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap "Add item" above.',
                  style: theme.textTheme.bodySmall?.copyWith(color: sub),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...items.map((item) {
            final subtitle = [
              if (item.description != null) item.description!,
              if (item.price != null) item.price!,
            ].join(' · ');
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
        AppSecondaryButton(onPressed: () => _submit(), child: const Text('Add')),
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
              decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
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
                                AppSecondaryButton(onPressed: _saveSectionName, child: const Text('Save')),
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
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: nav),
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
                      return _MenuItemRow(key: ValueKey(item.id), item: item, onUpdated: widget.onItemUpdated);
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
              decoration: const InputDecoration(labelText: 'Name', isDense: true, border: OutlineInputBorder()),
              style: theme.textTheme.bodyMedium?.copyWith(color: nav),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price', isDense: true, border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextButton(onPressed: _save, child: const Text('Save')),
                ),
                Expanded(
                  flex: 2,
                  child: TextButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancel')),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', isDense: true, border: OutlineInputBorder()),
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
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: nav),
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

class _DealsTab extends ConsumerWidget {
  const _DealsTab({
    required this.listingId,
    required this.deals,
    required this.punchCards,
    this.businessTier,
    this.activeDealCount = 0,
    this.onRefresh,
  });

  final String listingId;
  final List<Deal> deals;
  final List<PunchCardProgram> punchCards;
  final String? businessTier;
  final int activeDealCount;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tier = BusinessTierService.fromPlanTier(businessTier);
    final atDealLimit = activeDealCount >= BusinessTierService.maxActiveDeals(tier);
    final canCreatePunchCard = BusinessTierService.canCreatePunchCard(tier);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Deals & punch cards',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
        ),
        const SizedBox(height: 6),
        Text(
          'Create coupons and loyalty punch cards. New items require admin approval before they go live.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
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
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => CreateDealScreen(listingId: listingId)))
                    .then((_) => onRefresh?.call());
              },
              icon: Icon(atDealLimit ? Icons.lock_outline_rounded : Icons.local_offer_rounded, size: 20),
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
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => CreateLoyaltyScreen(listingId: listingId)))
                    .then((_) => onRefresh?.call());
              },
              icon: Icon(canCreatePunchCard ? Icons.loyalty_rounded : Icons.lock_outline_rounded, size: 20),
              label: Text(canCreatePunchCard ? 'Add punch card' : 'Upgrade for punch cards'),
            ),
            if (true) // Assuming we always want this if backend is present
              AppOutlinedButton(
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => PunchCardEnrollmentsScreen(businessId: listingId)))
                      .then((_) => onRefresh?.call());
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
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
          ),
          const SizedBox(height: 10),
          ...deals.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DealPunchCard(
                icon: Icons.local_offer_rounded,
                title: d.title,
                subtitle: d.description ?? '',
                dealId: d.id,
                onRefresh: onRefresh,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (punchCards.isNotEmpty) ...[
          Text(
            'Punch cards (${punchCards.length})',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
          ),
          const SizedBox(height: 10),
          ...punchCards.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DealPunchCard(
                icon: Icons.loyalty_rounded,
                title: p.title ?? 'Punch Card',
                subtitle: '${p.punchesRequired} punches — ${p.rewardDescription}',
                punchCardId: p.id,
                onRefresh: onRefresh,
              ),
            ),
          ),
        ],
        if (deals.isEmpty && punchCards.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.local_offer_outlined, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.4)),
                const SizedBox(height: 14),
                Text(
                  'No deals or punch cards yet',
                  style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.specNavy, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use the buttons above to create a deal or a punch card. They’ll need admin approval before going live.',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.75)),
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          AppDangerButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(isDeal ? 'Deal removed' : 'Loyalty card removed')));
        onRefresh?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not remove: $e')));
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
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
                  style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.specNavy, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.75)),
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
  const _EventsTab({required this.listingId, required this.events});

  final String listingId;
  final List<BusinessEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Events',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
        ),
        const SizedBox(height: 6),
        Text(
          '${events.length} event(s). Events are visible to customers after approval.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 20),
        AppSecondaryButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => CreateEventScreen(listingId: listingId)));
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.event_outlined, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.4)),
                const SizedBox(height: 14),
                Text(
                  'No events yet',
                  style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.specNavy, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap "Add event" above to create your first event.',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.75)),
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
            final subtitle = '$dateStr${e.location != null ? ' · ${e.location}' : ''}$statusLabel';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EventDetailScreen(eventId: e.id, listingId: listingId),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: _DealPunchCard(icon: Icons.event_rounded, title: e.title, subtitle: subtitle),
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
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 24),
            AppSecondaryButton(
              onPressed: () {
                BusinessTierUpgradeDialog.show(context, message: message);
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
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: nav),
          ),
          const SizedBox(height: 6),
          Text('Unlock with a paid business plan.', style: theme.textTheme.bodyMedium?.copyWith(color: sub)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
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
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: nav),
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
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: nav),
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
              Text(
                'Add and reorder photos on the Details tab.',
                style: theme.textTheme.bodySmall?.copyWith(color: sub),
              ),
            ],
          ),
        ),
        _AdvertisingSection(listingId: listingId, theme: theme, nav: nav, sub: sub),
        const SizedBox(height: 20),
        _MoreSection(
          title: 'Custom links',
          icon: Icons.link_rounded,
          child: BusinessLinksEditor(businessId: listingId),
        ),
        const SizedBox(height: 20),
        _ContactFormTemplateSection(listingId: listingId),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Full-tab view for account access (list users, add by email, remove). Managers only (RLS).
class _AccountAccessTab extends StatelessWidget {
  const _AccountAccessTab({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [_AccountAccessSection(listingId: listingId)],
    );
  }
}

/// Account access: list users with access, add by email, remove. Managers only (RLS).
class _AccountAccessSection extends ConsumerStatefulWidget {
  const _AccountAccessSection({required this.listingId});

  final String listingId;

  @override
  ConsumerState<_AccountAccessSection> createState() => _AccountAccessSectionState();
}

class _AccountAccessSectionState extends ConsumerState<_AccountAccessSection> {
  late Future<List<BusinessManagerEntry>> _managersFuture;

  @override
  void initState() {
    super.initState();
    _managersFuture = BusinessManagersRepository().listManagersForBusiness(widget.listingId);
  }

  void _refresh() {
    setState(() {
      _managersFuture = BusinessManagersRepository().listManagersForBusiness(widget.listingId);
    });
  }

  Future<void> _addByEmail() async {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.8);
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Add user access', style: TextStyle(color: nav)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter the email of someone who has a Cajun Local account. They will be able to manage this listing.',
                  style: theme.textTheme.bodySmall?.copyWith(color: sub),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'colleague@example.com'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter an email';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: sub)),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final email = controller.text.trim();
                final userId = await BusinessManagersRepository().lookupUserByEmail(widget.listingId, email);
                if (!ctx.mounted) return;
                if (userId == null) {
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text('No account found with that email. They must sign up first.')));
                  return;
                }
                try {
                  await BusinessManagersRepository().insert(widget.listingId, userId, role: 'owner');
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop(true);
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Could not add user: $e')));
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (added == true && mounted) _refresh();
  }

  Future<void> _removeAccess(BusinessManagerEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove access?'),
        content: Text(
          '${entry.displayName ?? entry.email ?? entry.userId} will no longer be able to manage this listing.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.specRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await BusinessManagersRepository().delete(widget.listingId, entry.userId);
      if (mounted) _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not remove: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.8);
    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.id;

    return _MoreSection(
      title: 'Account access',
      icon: Icons.people_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Users with access can edit this listing, manage deals, and view form submissions.',
            style: theme.textTheme.bodySmall?.copyWith(color: sub),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<BusinessManagerEntry>>(
            future: _managersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                );
              }
              final list = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...list.map((e) {
                    final isCurrent = e.userId == currentUserId;
                    final label = (e.displayName != null && e.displayName!.trim().isNotEmpty)
                        ? e.displayName!
                        : (e.email ?? 'Unknown manager');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded, size: 20, color: nav.withValues(alpha: 0.8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isCurrent ? '$label (you)' : label,
                              style: theme.textTheme.bodyMedium?.copyWith(color: nav),
                            ),
                          ),
                          if (!isCurrent)
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline, color: AppTheme.specRed, size: 22),
                              onPressed: () => _removeAccess(e),
                              tooltip: 'Remove access',
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  AppSecondaryButton(
                    onPressed: _addByEmail,
                    icon: const Icon(Icons.person_add_rounded, size: 20),
                    label: const Text('Add user by email'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Advertising section for paid-tier owners: how it works, benefits, CTA. Matches upselling style.
class _AdvertisingSection extends StatelessWidget {
  const _AdvertisingSection({required this.listingId, required this.theme, required this.nav, required this.sub});

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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
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
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: nav),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Promote your business with sponsored placements in Explore and Deals. Tap to buy an ad or view performance.',
                      style: theme.textTheme.bodySmall?.copyWith(color: sub, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppSecondaryButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => BusinessAdsScreen(businessId: listingId)));
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
  const _MoreSection({required this.title, required this.icon, required this.child});

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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
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
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
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
        _selectedKey == null || _selectedKey!.trim().isEmpty ? null : _selectedKey,
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact form template saved.')));
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
      );
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
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
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
                    (Set<WidgetState> states) => states.contains(WidgetState.selected) ? AppTheme.specNavy : null,
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
                      style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 4),
                    ...def.fields.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• ${f.label}${f.required ? ' (required)' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.9)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          AppSecondaryButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
