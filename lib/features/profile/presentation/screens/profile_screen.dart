import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/services/app_storage_service.dart';
import 'package:my_app/core/data/services/storage_upload_constants.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/repositories/business_managers_repository.dart';
import 'package:my_app/core/data/repositories/form_submissions_repository.dart';
import 'package:my_app/core/data/repositories/user_plans_repository.dart';
import 'package:my_app/core/stripe/stripe_checkout_service.dart';
import 'package:my_app/core/stripe/stripe_config.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/subscription/resolved_permissions.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/screens/admin_shell.dart';
import 'package:my_app/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:my_app/features/deals/presentation/screens/my_deals_screen.dart';
import 'package:my_app/features/deals/presentation/screens/my_punch_cards_screen.dart';
import 'package:my_app/features/deals/presentation/screens/scan_punch_screen.dart';
import 'package:my_app/features/messaging/presentation/screens/my_conversations_screen.dart';
import 'package:my_app/features/my_listings/presentation/screens/form_submissions_inbox_screen.dart';
import 'package:my_app/features/my_listings/presentation/screens/my_listings_screen.dart';
import 'package:my_app/features/profile/presentation/screens/about_screen.dart';
import 'package:my_app/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/page_loader.dart';
import 'package:my_app/shared/widgets/subscription_upsell_popup.dart';
import 'package:url_launcher/url_launcher.dart';

/// Placeholder user when profile load fails; UI shows loadError instead of fake data.
const _anonymousUser = MockUser(displayName: '', email: null, avatarUrl: null, ownedListingIds: []);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onMyListings, this.onNavigateToHome});

  /// When set (e.g. from MainShell), opens My Listings in-shell instead of pushing a route.
  final VoidCallback? onMyListings;

  /// When set (e.g. from MainShell in tablet mode), navigates back to the Home tab. Shown as Home in the left rail.
  final VoidCallback? onNavigateToHome;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<_ProfilePageData>? _dataFuture;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load once when context is ready (AppDataScope available).
    if (!_loadStarted) {
      _loadStarted = true;
      _dataFuture = _loadProfileData();
    }
  }

  Future<_ProfilePageData> _loadProfileData() async {
    try {
      final scope = AppDataScope.of(context);
      final auth = scope.authRepository;
      final dataSource = scope.dataSource;
      final useSupabase = dataSource.useSupabase;

      final userFuture = dataSource.getCurrentUser();
      final isAdminFuture =
          (useSupabase && auth.currentUserId != null) ? auth.isAdmin() : Future.value(false);
      final uid = auth.currentUserId;
      final businessIdsFuture = (useSupabase && uid != null)
          ? BusinessManagersRepository().listBusinessIdsForUser(uid)
          : Future.value(<String>[]);
      final results = await Future.wait([userFuture, isAdminFuture, businessIdsFuture])
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Profile load timed out');
      });
      if (!mounted) return _ProfilePageData(user: _anonymousUser, isAdmin: false, isBusinessManager: false);
      final businessIds = results[2] as List<String>;
      final isBusinessManager = businessIds.isNotEmpty;
      int inboxUnreadCount = 0;
      if (businessIds.isNotEmpty) {
        inboxUnreadCount = await FormSubmissionsRepository().unreadCountForBusinesses(businessIds);
      }
      return _ProfilePageData(
        user: results[0] as MockUser,
        isAdmin: results[1] as bool,
        isBusinessManager: isBusinessManager,
        inboxUnreadCount: inboxUnreadCount,
      );
    } on TimeoutException catch (e) {
      debugPrint('Profile load timeout: $e');
      if (!mounted) return _ProfilePageData(user: _anonymousUser, isAdmin: false, isBusinessManager: false);
      return _ProfilePageData(user: _anonymousUser, isAdmin: false, isBusinessManager: false, loadError: 'Loading data failed.');
    } catch (e, st) {
      debugPrint('Profile load error: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return _ProfilePageData(user: _anonymousUser, isAdmin: false, isBusinessManager: false);
      return _ProfilePageData(
        user: _anonymousUser,
        isAdmin: false,
        isBusinessManager: false,
        loadError: 'Loading data failed.',
      );
    }
  }

  /// Starts Stripe Checkout for user subscription (Cajun+ Membership). Opens browser.
  Future<void> _startStripeCheckout() async {
    if (!mounted) return;
    final scope = AppDataScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening checkout…')),
    );
    try {
      final plans = await UserPlansRepository().list();
      if (!mounted) return;
      final tier = StripeConfig.defaultUserTier;
      final plan = plans.where((p) => p.tier.toLowerCase() == tier).firstOrNull;
      if (plan == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No subscription plan available. Please try again later.')),
        );
        return;
      }
      final planId = plan.id;
      final useYearly = StripeConfig.defaultUserInterval == 'yearly';
      String? priceId = useYearly ? plan.stripePriceIdYearly : plan.stripePriceIdMonthly;
      if (priceId == null || priceId.isEmpty) {
        final fallback = StripeConfig.userPlans[tier];
        priceId = useYearly ? fallback?.yearly : fallback?.monthly;
      }
      if (priceId == null || priceId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription not configured. Add Stripe Price IDs in Admin → Plans.')),
        );
        return;
      }
      if (priceId.contains('placeholder')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Subscription not configured. Add real Stripe Price IDs in Admin → Plans (replace placeholders).',
            ),
          ),
        );
        return;
      }
      final stripe = StripeCheckoutService();
      // When STRIPE_RETURN_BASE_URL is unset, success/cancel URLs are null and
      // not sent; stripe-checkout Edge Function uses STRIPE_RETURN_BASE_URL secret.
      final url = await stripe.createCheckoutSession(
        priceId: priceId,
        mode: 'subscription',
        successUrl: StripeCheckoutService.successUrl(),
        cancelUrl: StripeCheckoutService.cancelUrl(),
        metadata: {
          'type': 'user_subscription',
          'reference_id': planId,
        },
      );
      if (!mounted) return;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        scope.userTierService.refresh();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open browser. URL: $url')),
        );
      }
    } on StripeCheckoutException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout: ${e.message}')),
      );
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('Stripe checkout error: $e');
      debugPrintStack(stackTrace: st);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    }
  }

  /// Opens Stripe Customer Portal (manage subscription, payment method, billing).
  Future<void> _openCustomerPortal() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening billing portal…')),
    );
    try {
      final stripe = StripeCheckoutService();
      final url = await stripe.createCustomerPortalSession(
        returnUrl: StripeCheckoutService.portalReturnUrl(),
      );
      if (!mounted) return;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        final scope = AppDataScope.of(context);
        scope.userTierService.refresh();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open portal: $url')),
        );
      }
    } on StripeCheckoutException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Portal failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfilePageData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ProfileLoadError(
            message: snapshot.error.toString(),
            onRetry: () {
              setState(() {
                _dataFuture = _loadProfileData();
              });
            },
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return Container(
            color: AppTheme.specOffWhite,
            child: const PageLoader(message: 'Loading profile…'),
          );
        }
        final data = snapshot.data!;
        return _ProfileContent(
          user: data.user,
          isAdmin: data.isAdmin,
          isBusinessManager: data.isBusinessManager,
          inboxUnreadCount: data.inboxUnreadCount,
          loadError: data.loadError,
          onRefresh: () {
            _dataFuture = _loadProfileData();
            setState(() {});
          },
          onMyListings: widget.onMyListings,
          onNavigateToHome: widget.onNavigateToHome,
          onStartStripeCheckout: _startStripeCheckout,
          onOpenCustomerPortal: _openCustomerPortal,
        );
      },
    );
  }
}

class _ProfilePageData {
  const _ProfilePageData({
    required this.user,
    required this.isAdmin,
    this.isBusinessManager = false,
    this.inboxUnreadCount = 0,
    this.loadError,
  });
  final MockUser user;
  final bool isAdmin;
  final bool isBusinessManager;
  final int inboxUnreadCount;
  final String? loadError;
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: AppTheme.specOffWhite,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.specRed),
              const SizedBox(height: 16),
              Text(
                'Could not load profile',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.specNavy,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              AppSecondaryButton(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatefulWidget {
  const _ProfileContent({
    required this.user,
    required this.isAdmin,
    required this.onRefresh,
    this.isBusinessManager = false,
    this.inboxUnreadCount = 0,
    this.loadError,
    this.onMyListings,
    this.onNavigateToHome,
    this.onStartStripeCheckout,
    this.onOpenCustomerPortal,
  });

  final MockUser user;
  final bool isAdmin;
  final bool isBusinessManager;
  final int inboxUnreadCount;
  final VoidCallback onRefresh;
  final String? loadError;
  final VoidCallback? onMyListings;
  final VoidCallback? onNavigateToHome;
  final Future<void> Function()? onStartStripeCheckout;
  final Future<void> Function()? onOpenCustomerPortal;

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

/// Section indices for profile shell (tablet rail / mobile tabs).
const int _kProfileTab = 0;
const int _kBillingTab = 1;
const int _kPreferencesTab = 2;
const int _kAccountTab = 3;
const int _kAdminTab = 4;
const int _kMyListingsTab = 5;

class _ProfileContentState extends State<_ProfileContent>
    with SingleTickerProviderStateMixin {
  late String _displayName;
  late String? _email;
  bool _profileEditing = false;
  bool _uploadingAvatar = false;
  TextEditingController? _displayNameController;
  TextEditingController? _emailController;
  bool _notificationsDeals = true;
  bool _notificationsListings = true;
  bool _notificationsReminders = false;

  late TabController _tabController;
  int _selectedIndex = 0;

  List<({String label, IconData icon})> get _sections {
    final list = <({String label, IconData icon})>[
      (label: 'Profile', icon: Icons.person_rounded),
      (label: 'Billing', icon: Icons.credit_card_rounded),
      (label: 'Preferences', icon: Icons.tune_rounded),
      (label: 'Account', icon: Icons.settings_rounded),
    ];
    if (widget.isAdmin) list.add((label: 'Admin', icon: Icons.admin_panel_settings_rounded));
    list.add((label: 'My Listings', icon: Icons.store_rounded));
    return list;
  }

  List<int> get _sectionKeys {
    final list = <int>[0, 1, 2, 3];
    if (widget.isAdmin) list.add(4);
    list.add(5);
    return list;
  }

  @override
  void initState() {
    super.initState();
    _displayName = widget.user.displayName;
    _email = widget.user.email;
    _tabController = TabController(length: _sections.length, vsync: this);
    _tabController.addListener(_syncIndexFromTab);
  }

  void _syncIndexFromTab() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() => _selectedIndex = _tabController.index);
    }
  }

  @override
  void didUpdateWidget(covariant _ProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.displayName != widget.user.displayName) _displayName = widget.user.displayName;
    if (oldWidget.user.email != widget.user.email) _email = widget.user.email;
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncIndexFromTab);
    _tabController.dispose();
    _displayNameController?.dispose();
    _emailController?.dispose();
    super.dispose();
  }

  void _startProfileEdit() {
    _displayNameController = TextEditingController(text: _displayName);
    _emailController = TextEditingController(text: _email ?? '');
    setState(() => _profileEditing = true);
  }

  void _saveProfile() {
    final newName = _displayNameController?.text.trim() ?? _displayName;
    final newEmail = _emailController?.text.trim();
    _displayNameController?.dispose();
    _emailController?.dispose();
    _displayNameController = null;
    _emailController = null;
    setState(() {
      _profileEditing = false;
      _displayName = newName.isEmpty ? widget.user.displayName : newName;
      _email = (newEmail == null || newEmail.isEmpty) ? widget.user.email : newEmail;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }

  void _cancelProfileEdit() {
    _displayNameController?.dispose();
    _emailController?.dispose();
    _displayNameController = null;
    _emailController = null;
    setState(() {
      _profileEditing = false;
      _displayName = widget.user.displayName;
      _email = widget.user.email;
    });
  }

  void _onDestinationSelected(int index) {
    final sectionKey = index < _sectionKeys.length ? _sectionKeys[index] : index;
    // Admin: go straight to Admin shell (no intermediate card).
    if (sectionKey == _kAdminTab) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AdminShell()),
      );
      return;
    }
    // My Listings: open directly (in-shell or pushed) — shows no-listings/create flow when empty.
    if (sectionKey == _kMyListingsTab) {
      if (widget.onMyListings != null) {
        widget.onMyListings!();
      } else {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MyListingsScreen()),
        );
      }
      return;
    }
    setState(() => _selectedIndex = index);
    _tabController.animateTo(index);
  }

  Future<void> _signOut() async {
    final auth = AppDataScope.of(context).authRepository;
    await auth.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out')),
      );
    }
  }

  Future<void> _pickAndSetProfilePhoto() async {
    final scope = AppDataScope.of(context);
    final auth = scope.authRepository;
    final uid = auth.currentUserId;
    final useSupabase = scope.dataSource.useSupabase;
    if (!useSupabase || uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to add a profile picture')),
      );
      return;
    }
    if (_uploadingAvatar) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedImageExtensions,
      allowMultiple: false,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final bytes = result.files.single.bytes!;
      final name = result.files.single.name;
      final ext = name.contains('.') ? name.split('.').last : 'jpg';
      final url = await AppStorageService().uploadAvatar(
        userId: uid,
        bytes: bytes,
        extension: ext,
      );
      await auth.updateOwnProfile(avatarUrl: url);
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppDataScope.of(context);
    final auth = scope.authRepository;
    final dataSource = scope.dataSource;
    final useSupabase = dataSource.useSupabase;
    final signedIn = useSupabase && auth.currentUserId != null;
    final hasListings = widget.user.ownedListingIds.isNotEmpty || widget.isBusinessManager;
    final padding = AppLayout.horizontalPadding(context);
    final isTablet = AppLayout.isTablet(context);
    final theme = Theme.of(context);

    if (isTablet) {
      // Tablet: left NavigationRail + top bar (homepage/listing-edit style), Sign out in rail.
      return Container(
        color: AppTheme.specOffWhite,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NavigationRail(
              backgroundColor: AppTheme.specWhite,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
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
              leading: widget.onNavigateToHome != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onNavigateToHome,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.home_rounded,
                                      size: 24,
                                      color: AppTheme.specNavy.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Home',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: AppTheme.specNavy.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    )
                  : const SizedBox(height: 8),
              trailing: signedIn
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _signOut,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.logout_rounded, size: 24, color: AppTheme.specNavy.withValues(alpha: 0.8)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sign out',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: AppTheme.specNavy.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(height: 8),
              destinations: [
                for (final s in _sections)
                  NavigationRailDestination(
                    icon: Icon(s.icon),
                    label: Text(s.label),
                  ),
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
                                _sections[_selectedIndex].label,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.specNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        padding.left,
                        20,
                        padding.right,
                        24,
                      ),
                      child: _buildTabContent(
                        context,
                        _sectionKeys[_selectedIndex],
                        auth: auth,
                        signedIn: signedIn,
                        hasListings: hasListings,
                        padding: padding,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.specOffWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppTheme.specWhite,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.specNavy,
              unselectedLabelColor: AppTheme.specNavy.withValues(alpha: 0.6),
              indicatorColor: AppTheme.specGold,
              tabs: [
                for (final s in _sections)
                  Tab(icon: Icon(s.icon, size: 20), text: s.label),
              ],
              onTap: _onDestinationSelected,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (var i = 0; i < _sections.length; i++)
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      padding.left,
                      16,
                      padding.right,
                      24,
                    ),
                    child: _buildTabContent(
                      context,
                      _sectionKeys[i],
                      auth: auth,
                      signedIn: signedIn,
                      hasListings: hasListings,
                      padding: padding,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    int sectionKey, {
    required AuthRepository auth,
    required bool signedIn,
    required bool hasListings,
    required EdgeInsets padding,
  }) {
    switch (sectionKey) {
      case _kProfileTab:
        return _buildProfileTab(context, padding);
      case _kBillingTab:
        return _buildBillingTab(context, padding);
      case _kPreferencesTab:
        return _buildPreferencesTab(context, padding);
      case _kAccountTab:
        return _buildAccountTab(context, auth, signedIn, hasListings, padding, widget.inboxUnreadCount);
      case _kAdminTab:
        return _buildAdminTab(context, padding);
      case _kMyListingsTab:
        return _buildMyListingsTab(context, padding);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAdminTab(BuildContext context, EdgeInsets padding) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Admin',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.specNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _SpecCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.admin_panel_settings_rounded, color: AppTheme.specGold, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Admin dashboard',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.specNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Manage businesses, claims, plans, and app content.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              AppSecondaryButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AdminShell()),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                label: const Text('Open Admin'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyListingsTab(BuildContext context, EdgeInsets padding) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'My Listings',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.specNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _SpecCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.store_rounded, color: AppTheme.specGold, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Your businesses',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.specNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your business listings, hours, menu, deals, and punch cards.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              AppSecondaryButton(
                onPressed: () {
                  if (widget.onMyListings != null) {
                    widget.onMyListings!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const MyListingsScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.list_rounded, size: 20),
                label: const Text('Go to My Listings'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab(BuildContext context, EdgeInsets padding) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.loadError != null) ...[
          _SpecCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.specRed, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.loadError!,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _SpecCard(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            children: [
              GestureDetector(
                onTap: _uploadingAvatar ? null : _pickAndSetProfilePhoto,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppTheme.specNavy.withValues(alpha: 0.12),
                      backgroundImage: (widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty)
                          ? NetworkImage(widget.user.avatarUrl!)
                          : null,
                      child: _uploadingAvatar
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: AppTheme.specNavy, strokeWidth: 2),
                            )
                          : (widget.user.avatarUrl == null || widget.user.avatarUrl!.isEmpty)
                              ? Text(
                                  _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: AppTheme.specNavy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                    ),
                    if (!_uploadingAvatar)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.specGold,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.camera_alt_rounded, size: 20, color: AppTheme.specNavy),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to change photo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.specNavy,
                ),
              ),
              if (_email != null && _email!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _email!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Personal information',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.specNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _ProfileSettingsCard(
          displayName: _displayName,
          email: _email,
          isEditing: _profileEditing,
          displayNameController: _displayNameController,
          emailController: _emailController,
          onEditPressed: _startProfileEdit,
          onSavePressed: _saveProfile,
          onCancelPressed: _cancelProfileEdit,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBillingTab(BuildContext context, EdgeInsets padding) {
    final theme = Theme.of(context);
    final scope = AppDataScope.of(context);
    return ValueListenableBuilder<ResolvedPermissions?>(
      valueListenable: scope.userTierService.permissions,
      builder: (context, perms, _) {
        final resolved = perms ?? ResolvedPermissions.free;
        final isPaid = resolved.tier == 'plus' || resolved.tier == 'pro';
        final planLabel = isPaid
            ? (resolved.planName ?? (resolved.tier == 'pro' ? 'Pro' : 'Cajun+ Membership'))
            : 'Free';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Billing & subscription',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.specNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _SpecCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Your plan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.specNavy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? AppTheme.specGold.withValues(alpha: 0.25)
                              : AppTheme.specNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: isPaid
                              ? Border.all(color: AppTheme.specGold.withValues(alpha: 0.6))
                              : null,
                        ),
                        child: Text(
                          planLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isPaid ? AppTheme.specNavy : AppTheme.specNavy.withValues(alpha: 0.85),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isPaid
                        ? 'You have access to Ask Local, exclusive deals, and more.'
                        : 'Enjoy discovering local businesses and deals. Get Cajun+ Membership for Ask Local and exclusive perks.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!isPaid) _buildUpgradeCta(context) else _buildDowngradeMinimal(context),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SpecCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment method',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.specNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPaid ? 'Manage in billing portal.' : 'No payment method on file.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.75),
                    ),
                  ),
                  if (isPaid) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: widget.onOpenCustomerPortal,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.specNavy,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Open billing portal'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SpecCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Billing history',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.specNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No billing history yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildUpgradeCta(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.specGold.withValues(alpha: 0.2),
            AppTheme.specGold.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cajun+ Membership',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: nav,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask Local, exclusive deals, and support Cajun Local — \$2.99/mo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: nav.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            onPressed: () {
              SubscriptionUpsellPopup.show(
                context,
                onSubscribe: () {
                  Navigator.of(context).pop();
                  widget.onStartStripeCheckout?.call();
                },
                onStartFreeTrial: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Free trial coming soon.')),
                  );
                },
              );
            },
            expanded: false,
            icon: const Icon(Icons.workspace_premium_rounded, size: 22),
            label: const Text('Get Cajun+ Membership'),
          ),
        ],
      ),
    );
  }

  Widget _buildDowngradeMinimal(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          TextButton(
            onPressed: () => _showDowngradeConfirmDialog(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.specNavy.withValues(alpha: 0.6),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Downgrade',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.specNavy.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDowngradeConfirmDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DowngradeConfirmDialog(
        onCancelSubscription: () {
          Navigator.of(ctx).pop();
          widget.onOpenCustomerPortal?.call();
        },
        onKeepPlan: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Widget _buildPreferencesTab(BuildContext context, EdgeInsets padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.specNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _NotificationsCard(
          dealsEnabled: _notificationsDeals,
          listingsEnabled: _notificationsListings,
          remindersEnabled: _notificationsReminders,
          onDealsChanged: (v) => setState(() => _notificationsDeals = v),
          onListingsChanged: (v) => setState(() => _notificationsListings = v),
          onRemindersChanged: (v) => setState(() => _notificationsReminders = v),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAccountTab(
    BuildContext context,
    AuthRepository auth,
    bool signedIn,
    bool hasListings,
    EdgeInsets padding,
    int inboxUnreadCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Account',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.specNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _AccountCard(
          signedIn: signedIn,
          hasListings: hasListings,
          canScanPunch: widget.isBusinessManager,
          onSignOut: () async {
            await auth.signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out')),
              );
            }
          },
          onScanPunch: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ScanPunchScreen()),
            );
          },
          onMyDeals: signedIn
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const MyDealsScreen()),
                  );
                }
              : null,
          onMyLoyaltyCards: signedIn
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const MyPunchCardsScreen()),
                  );
                }
              : null,
          onMessages: hasListings && signedIn
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const FormSubmissionsInboxScreen()),
                  );
                }
              : null,
          messagesBadge: hasListings ? inboxUnreadCount : null,
          onMyConversations: !hasListings && auth.currentUserId != null
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MyConversationsScreen(userId: auth.currentUserId!),
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          'About & legal',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.specNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _AboutCard(
          onAbout: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
            );
          },
          onPrivacy: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyScreen()),
            );
          },
        ),
        const SizedBox(height: 32),
        // Sign in / Sign out in red, near the bottom (not in the list with others).
        Center(
          child: signedIn
              ? TextButton(
                  onPressed: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed out')),
                      );
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: AppTheme.specRed),
                  child: Text(
                    'Sign out',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.specRed,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: AppTheme.specRed),
                  child: Text(
                    'Sign in',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.specRed,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

const double _profileCardRadius = 16;

/// White card with home-theme shadow (specWhite, 16 radius).
class _SpecCard extends StatelessWidget {
  const _SpecCard({
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.specWhite,
          borderRadius: BorderRadius.circular(_profileCardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_profileCardRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(_profileCardRadius),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// "We hate to see you go" — asks why they wish to cancel, then confirm or keep plan.
class _DowngradeConfirmDialog extends StatefulWidget {
  const _DowngradeConfirmDialog({
    required this.onCancelSubscription,
    required this.onKeepPlan,
  });

  final VoidCallback onCancelSubscription;
  final VoidCallback onKeepPlan;

  @override
  State<_DowngradeConfirmDialog> createState() => _DowngradeConfirmDialogState();
}

class _DowngradeConfirmDialogState extends State<_DowngradeConfirmDialog> {
  String? _selectedReason;

  static const List<String> _reasons = [
    'Too expensive',
    'Not using it enough',
    'Found an alternative',
    'Only needed for a short time',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);

    return Dialog(
      backgroundColor: AppTheme.specOffWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.sentiment_dissatisfied_outlined, size: 48, color: nav.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'We hate to see you go',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: nav,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Before you cancel, would you tell us why? Your feedback helps us improve.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: sub,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              decoration: InputDecoration(
                labelText: 'Reason for cancelling',
                hintText: 'Select a reason',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppTheme.specWhite,
              ),
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _selectedReason = v),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(
                  onPressed: widget.onKeepPlan,
                  style: TextButton.styleFrom(foregroundColor: nav),
                  child: const Text('Keep my plan'),
                ),
                const Spacer(),
                AppDangerButton(
                  onPressed: () => widget.onCancelSubscription(),
                  child: const Text('Continue to cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Single card with Sign out, My deals, My loyalty cards, Messages/My conversations, Scan punch rows.
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.signedIn,
    required this.hasListings,
    required this.onSignOut,
    this.onMyDeals,
    this.onMyLoyaltyCards,
    this.onMessages,
    this.messagesBadge,
    this.onMyConversations,
    this.canScanPunch = false,
    required this.onScanPunch,
  });

  final bool signedIn;
  final bool hasListings;
  final VoidCallback onSignOut;
  final VoidCallback? onMyDeals;
  final VoidCallback? onMyLoyaltyCards;
  final VoidCallback? onMessages;
  final int? messagesBadge;
  final VoidCallback? onMyConversations;
  final bool canScanPunch;
  final VoidCallback onScanPunch;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    // Sign out is shown near bottom of Account tab in red, not in this list.
    if (signedIn && onMyDeals != null) {
      children.add(_SettingsRow(
        icon: Icons.bookmark_rounded,
        label: 'My deals',
        onTap: onMyDeals!,
      ));
    }
    if (signedIn && onMyLoyaltyCards != null) {
      children.add(_SettingsRow(
        icon: Icons.loyalty_rounded,
        label: 'My loyalty cards',
        onTap: onMyLoyaltyCards!,
      ));
    }
    if (signedIn && onMessages != null) {
      children.add(_SettingsRow(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Messages',
        onTap: onMessages!,
        badge: messagesBadge != null && messagesBadge! > 0 ? messagesBadge : null,
      ));
    } else if (signedIn && onMyConversations != null) {
      children.add(_SettingsRow(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'My conversations',
        onTap: onMyConversations!,
      ));
    }
    if (canScanPunch) {
      children.add(_SettingsRow(icon: Icons.qr_code_scanner_rounded, label: 'Scan punch', onTap: onScanPunch));
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return _SpecCard(
      padding: EdgeInsets.zero,
      onTap: null,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppTheme.specNavy.withValues(alpha: 0.08)),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Single card with About and Privacy rows.
class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.onAbout, required this.onPrivacy});

  final VoidCallback onAbout;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return _SpecCard(
      padding: EdgeInsets.zero,
      onTap: null,
      child: Column(
        children: [
          _SettingsRow(icon: Icons.info_outline_rounded, label: 'About Cajun Local', onTap: onAbout),
          Divider(height: 1, color: AppTheme.specNavy.withValues(alpha: 0.08)),
          _SettingsRow(icon: Icons.description_outlined, label: 'Privacy policy', onTap: onPrivacy),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.specNavy, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.specNavy,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (badge != null && badge! > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.specGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge! > 99 ? '99+' : '$badge',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.specNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.specGold),
          ],
        ),
      ),
    );
  }
}

class _ProfileSettingsCard extends StatelessWidget {
  const _ProfileSettingsCard({
    required this.displayName,
    required this.email,
    required this.isEditing,
    this.displayNameController,
    this.emailController,
    required this.onEditPressed,
    required this.onSavePressed,
    required this.onCancelPressed,
  });

  final String displayName;
  final String? email;
  final bool isEditing;
  final TextEditingController? displayNameController;
  final TextEditingController? emailController;
  final VoidCallback onEditPressed;
  final VoidCallback onSavePressed;
  final VoidCallback onCancelPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
    );

    return _SpecCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isEditing) ...[
            Text(
              'Display name',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.specNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              autofocus: true,
              controller: displayNameController,
              style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: TextStyle(color: AppTheme.specNavy.withValues(alpha: 0.5)),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: BorderSide(color: AppTheme.specGold, width: 1.5),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            if (email != null) ...[
              const SizedBox(height: 12),
              Text(
                'Email',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.specNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: emailController,
                style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy),
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(color: AppTheme.specNavy.withValues(alpha: 0.5)),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border.copyWith(
                    borderSide: BorderSide(color: AppTheme.specGold, width: 1.5),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancelPressed,
                  child: Text('Cancel', style: TextStyle(color: AppTheme.specNavy)),
                ),
                const SizedBox(width: 8),
                AppSecondaryButton(
                  onPressed: onSavePressed,
                  child: const Text('Save'),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Display name',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.specNavy,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (email != null && email!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Email',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.specNavy.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.specNavy,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: AppTheme.specGold),
                  onPressed: onEditPressed,
                  tooltip: 'Edit profile',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({
    required this.dealsEnabled,
    required this.listingsEnabled,
    required this.remindersEnabled,
    required this.onDealsChanged,
    required this.onListingsChanged,
    required this.onRemindersChanged,
  });

  final bool dealsEnabled;
  final bool listingsEnabled;
  final bool remindersEnabled;
  final ValueChanged<bool> onDealsChanged;
  final ValueChanged<bool> onListingsChanged;
  final ValueChanged<bool> onRemindersChanged;

  @override
  Widget build(BuildContext context) {
    return _SpecCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _NotificationRow(
            label: 'Deals & promotions',
            subtitle: 'New deals and punch card offers',
            value: dealsEnabled,
            onChanged: onDealsChanged,
          ),
          Divider(height: 1, color: AppTheme.specNavy.withValues(alpha: 0.08)),
          _NotificationRow(
            label: 'New listings',
            subtitle: 'When businesses join your area',
            value: listingsEnabled,
            onChanged: onListingsChanged,
          ),
          Divider(height: 1, color: AppTheme.specNavy.withValues(alpha: 0.08)),
          _NotificationRow(
            label: 'Reminders',
            subtitle: 'Punch card and favorite updates',
            value: remindersEnabled,
            onChanged: onRemindersChanged,
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.specNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.specGold.withValues(alpha: 0.5),
            activeThumbColor: AppTheme.specGold,
          ),
        ],
      ),
    );
  }
}

