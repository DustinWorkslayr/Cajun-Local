import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/auth/providers/auth_provider.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/repositories/business_managers_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/notifications_repository.dart';
import 'package:my_app/core/data/repositories/punch_card_programs_repository.dart';
import 'package:my_app/debug_agent_log.dart';
import 'package:my_app/core/preferences/user_parish_preferences.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/screens/admin_shell.dart';
import 'package:my_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:my_app/features/deals/presentation/screens/deals_screen.dart';
import 'package:my_app/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:my_app/features/home/presentation/screens/home_screen.dart';
import 'package:my_app/features/my_listings/presentation/screens/my_listings_screen.dart';
import 'package:my_app/features/local_events/presentation/screens/local_events_screen.dart';
import 'package:my_app/features/messaging/presentation/screens/my_conversations_screen.dart';
import 'package:my_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:my_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:my_app/features/news/presentation/screens/news_screen.dart';
import 'package:my_app/features/news/presentation/screens/news_post_detail_screen.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:my_app/features/choose_for_me/presentation/screens/choose_for_me_screen.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/app_logo.dart';
import 'package:my_app/shared/widgets/ask_local_sheet.dart';
import 'package:my_app/shared/widgets/explore_category_picker_dialog.dart';
import 'package:my_app/shared/widgets/parish_onboarding_dialog.dart';
import 'package:my_app/shared/widgets/quick_scan_sheet.dart';

/// Logo height in AppBar for non-home tabs (Explore, Favorites, Deals, Profile). Smaller than home (112), larger than nav (26).
const double _kAppBarLogoHeight = 88;

/// AppBar toolbar height and leading width so the logo is not clipped.
const double _kAppBarToolbarHeight = 96;
const double _kAppBarLeadingWidth = 120;

/// Root scaffold with bottom navigation (Explore, Home, Favorites, Deals, Profile).
/// Home uses its own custom header; other tabs use AppBar. Bottom nav: 5 icons with Home in center. Ask Local in menu.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String? _exploreInitialCategoryId;
  bool _parishOnboardingChecked = false;
  final GlobalKey<NavigatorState> _newsNavigatorKey = GlobalKey<NavigatorState>();

  /// Incremented when parish onboarding completes so HomeScreen refetches (without being recreated).
  int _parishPrefsVersion = 0;
  bool _profileShowListings = false;
  bool _menuOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Active loyalty (punch) cards across businesses the current user manages. Null = not loaded.
  List<QuickScanLoyaltyCard>? _quickScanLoyaltyCards;

  /// Unread notifications count for app bar badge. Null = not loaded.
  Future<int>? _notificationsUnreadFuture;

  void _openMenu() {
    setState(() => _menuOpen = true);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _closeMenu() {
    setState(() => _menuOpen = false);
    _scaffoldKey.currentState?.closeEndDrawer();
  }

  Future<void> _maybeShowParishOnboarding() async {
    if (!mounted) return;
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    final done = await UserParishPreferences.hasCompletedParishOnboarding();
    if (!mounted || done) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ParishOnboardingDialog(
        onComplete: (ids) async {
          await UserParishPreferences.setPreferredParishIds(ids);
          await UserParishPreferences.setCompletedParishOnboarding();
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
    // Trigger home refetch after onboarding (parish prefs now set). HomeScreen refetches in place instead of being recreated.
    if (mounted) setState(() => _parishPrefsVersion++);
  }

  void _navigateToExploreWithCategory(MockCategory category) {
    setState(() {
      _currentIndex = 2; // Explore tab
      _exploreInitialCategoryId = category.id;
    });
  }

  void _navigateToExplore() {
    _showExploreCategoryPickerThenNavigate();
  }

  /// Switches to Explore tab immediately so the list starts loading, then shows the category picker
  /// on top. When the user selects, we apply the category and close the dialog (list keeps loading in background).
  Future<void> _showExploreCategoryPickerThenNavigate() async {
    // Switch to Explore tab first so CategoriesScreen mounts and starts loading the list.
    setState(() {
      _currentIndex = 2; // Explore tab
      _exploreInitialCategoryId = null;
    });
    final categories = await AppDataScope.of(context).dataSource.getCategories();
    if (!mounted) return;
    final selectedId = await showExploreCategoryPickerDialog(context: context, categories: categories);
    if (!mounted) return;
    // null = user dismissed; keep Explore tab, leave category as-is (or all)
    if (selectedId != null) {
      setState(() {
        _exploreInitialCategoryId = selectedId == kExploreAllSentinel ? null : selectedId;
      });
    }
  }

  Future<void> _signOut() async {
    _closeMenu();
    await ref.read(authNotifierProvider.notifier).signOut();
    if (mounted) {
      setState(() {
        _quickScanLoyaltyCards = null;
        _notificationsUnreadFuture = null;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = ref.watch(authNotifierProvider).valueOrNull?.id;
    if (_quickScanLoyaltyCards == null && uid != null) {
      _loadQuickScanLoyaltyCards(uid);
    }
    if (_notificationsUnreadFuture == null && uid != null) {
      _notificationsUnreadFuture = NotificationsRepository().unreadCount(uid);
    }
  }

  Future<void> _loadQuickScanLoyaltyCards(String uid) async {
    final managers = BusinessManagersRepository();
    final punchRepo = PunchCardProgramsRepository();
    final businessRepo = BusinessRepository();
    final bizIds = await managers.listBusinessIdsForUser(uid);
    final list = <QuickScanLoyaltyCard>[];
    for (final id in bizIds) {
      final programs = await punchRepo.listActive(businessId: id);
      final b = await businessRepo.getByIdForManager(id);
      final businessName = b?.name ?? id;
      for (final p in programs) {
        list.add(
          QuickScanLoyaltyCard(
            programId: p.id,
            programTitle: p.title?.trim().isNotEmpty == true ? p.title! : 'Untitled',
            businessName: businessName,
          ),
        );
      }
    }
    if (mounted) setState(() => _quickScanLoyaltyCards = list);
  }

  void _openQuickScan() {
    if (_quickScanLoyaltyCards == null || _quickScanLoyaltyCards!.isEmpty) return;
    showQuickScanSheet(context, loyaltyCards: _quickScanLoyaltyCards!);
  }

  void _openMessages() {
    _closeMenu();
    final uid = ref.read(authNotifierProvider).valueOrNull?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to view your messages.')));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MyConversationsScreen(userId: uid)));
  }

  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        parishPrefsVersion: _parishPrefsVersion,
        openMenu: _openMenu,
        onSelectCategory: _navigateToExploreWithCategory,
        onNavigateToExplore: _navigateToExplore,
        onNavigateToFavorites: () => setState(() => _currentIndex = 3),
        onNavigateToDeals: () => setState(() => _currentIndex = 4),
        onNavigateToNews: _goToNewsTab,
        onNavigateToNewsPost: _goToNewsPost,
        onOpenLocalEvents: () {
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LocalEventsScreen()));
        },
        onOpenChooseForMe: _onChooseForMeTap,
      ),
      Navigator(
        key: _newsNavigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(builder: (_) => const NewsScreen());
        },
      ),
      CategoriesScreen(initialCategoryId: _exploreInitialCategoryId),
      const FavoritesScreen(),
      const DealsScreen(),
      _profileShowListings
          ? MyListingsScreen(embeddedInShell: true, onBack: () => setState(() => _profileShowListings = false))
          : ProfileScreen(
              onMyListings: () => setState(() => _profileShowListings = true),
              onNavigateToHome: () => setState(() => _currentIndex = 0),
              onHandleNotificationActionUrl: (url) => _handleNotificationActionUrl(context, url),
            ),
    ];
  }

  /// Order: Home, News, Explore, Favorites, Deals, Profile (Home far left).
  static const List<String> _titles = ['Home', 'News', 'Explore', 'Favorites', 'Deals', 'Profile'];

  void _onAskLocalTap() {
    final user = ref.read(authNotifierProvider).valueOrNull;
    final tierService = AppDataScope.of(context).userTierService;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to use Ask Local.')));
      return;
    }
    if (!(tierService.value?.canUseAskLocal ?? false)) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppTheme.specWhite,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ask Local is included with Cajun+ Membership and Pro',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
              ),
              const SizedBox(height: 8),
              Text(
                'Get Cajun+ Membership for AI-powered local recommendations.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(onPressed: () => Navigator.of(ctx).pop(), expanded: false, child: const Text('Got it')),
            ],
          ),
        ),
      );
      return;
    }
    // For now, passing user.id as dummy token. Real token should be fetched if needed.
    if (user.id.isNotEmpty) {
      showAskLocalSheet(context, accessToken: user.id);
    }
  }

  void _onChooseForMeTap() {
    _closeMenu();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChooseForMeScreen()));
  }

  void _goToNewsTab() {
    setState(() => _currentIndex = 1);
  }

  void _goToNewsPost(String postId) {
    setState(() => _currentIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _newsNavigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => NewsPostDetailScreen(postId: postId)),
      );
    });
  }

  /// Handles in-app action URLs from notifications (app://news/id, app://listings/id).
  /// Returns true if the URL was handled (caller should not launch externally).
  bool _handleNotificationActionUrl(BuildContext shellContext, String actionUrl) {
    final uri = Uri.tryParse(actionUrl);
    if (uri == null) return false;
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return false;
    final pathOnly = uri.path;
    // app://news/id -> host=news, pathSegments=[id]; /news/id -> pathSegments=[news, id]
    if ((uri.scheme == 'app' && uri.host == 'news') || pathOnly.startsWith('/news/')) {
      final postId = pathSegments.length >= 2 && pathSegments[0] == 'news' ? pathSegments[1] : pathSegments.last;
      if (postId.isEmpty) return false;
      Navigator.of(shellContext).pop();
      setState(() => _currentIndex = 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _newsNavigatorKey.currentState?.push(
          MaterialPageRoute<void>(builder: (_) => NewsPostDetailScreen(postId: postId)),
        );
      });
      return true;
    }
    if ((uri.scheme == 'app' && uri.host == 'listings') || pathOnly.startsWith('/listings/')) {
      final listingId = pathSegments.length >= 2 && pathSegments[0] == 'listings' ? pathSegments[1] : pathSegments.last;
      if (listingId.isEmpty) return false;
      Navigator.of(shellContext).pop();
      setState(() => _currentIndex = 2);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(
          shellContext,
        ).push(MaterialPageRoute<void>(builder: (_) => ListingDetailScreen(listingId: listingId)));
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_parishOnboardingChecked) {
      _parishOnboardingChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowParishOnboarding());
    }
    final isHome = _currentIndex == 0;
    const profileTabIndex = 5;
    final isProfile = _currentIndex == profileTabIndex;
    final showListingsInProfile = isProfile && _profileShowListings;
    final screens = _buildScreens();
    // #region agent log
    agentLog('main_shell.dart:build', 'Scaffold building', {
      'currentIndex': _currentIndex,
      'screensLength': screens.length,
      'isHome': isHome,
    }, 'H1');
    // #endregion

    final scaffold = Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        toolbarHeight: _kAppBarToolbarHeight,
        leadingWidth: _kAppBarLeadingWidth,
        leading: showListingsInProfile
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _profileShowListings = false),
                tooltip: 'Back to Profile',
              )
            : Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Center(child: AppLogo(height: _kAppBarLogoHeight)),
              ),
        title: Text(
          showListingsInProfile ? 'My Listings' : _titles[_currentIndex],
          style: TextStyle(
            fontFamily: 'Brobane',
            fontSize: 26,
            fontWeight: FontWeight.normal,
            color: AppTheme.specNavy,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_quickScanLoyaltyCards != null && _quickScanLoyaltyCards!.isNotEmpty)
            IconButton(
              onPressed: _openQuickScan,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              color: AppTheme.specNavy,
              tooltip: 'Quick scan punch card',
            ),
          _NotificationsIcon(
            unreadFuture: _notificationsUnreadFuture,
            onOpen: () {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        NotificationsScreen(onHandleActionUrl: (url) => _handleNotificationActionUrl(context, url)),
                  ),
                );
                if (!mounted) return;
                final uid = ref.read(authNotifierProvider).valueOrNull?.id;
                if (uid != null) {
                  setState(() => _notificationsUnreadFuture = NotificationsRepository().unreadCount(uid));
                }
              });
            },
          ),
          IconButton(
            onPressed: _openMenu,
            icon: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: AlwaysStoppedAnimation<double>(_menuOpen ? 1 : 0),
              color: AppTheme.specNavy,
              size: 26,
            ),
            tooltip: 'Menu',
          ),
        ],
        scrolledUnderElevation: 12,
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      endDrawer: Drawer(
        backgroundColor: AppTheme.specOffWhite,
        child: _AppMenuDrawer(
          currentIndex: _currentIndex,
          onClose: _closeMenu,
          onNavigateToTab: (index) {
            _closeMenu();
            if (index == 2) {
              _showExploreCategoryPickerThenNavigate();
            } else {
              setState(() => _currentIndex = index);
            }
          },
          onOpenAskLocal: _onAskLocalTap,
          onOpenChooseForMe: _onChooseForMeTap,
          onOpenLocalEvents: () {
            _closeMenu();
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LocalEventsScreen()));
          },
          onOpenNotifications: () {
            _closeMenu();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    NotificationsScreen(onHandleActionUrl: (url) => _handleNotificationActionUrl(context, url)),
              ),
            );
          },
          onOpenMessages: _openMessages,
          onOpenAdmin: () {
            _closeMenu();
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdminShell()));
          },
          onSignOut: _signOut,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // #region agent log
            final mediaH = MediaQuery.sizeOf(context).height;
            final mediaW = MediaQuery.sizeOf(context).width;
            final effectiveHeight = constraints.maxHeight > 0 ? constraints.maxHeight : (mediaH - kToolbarHeight);
            final effectiveWidth = constraints.maxWidth > 0 ? constraints.maxWidth : mediaW;
            agentLog('main_shell.dart:body', 'Body constraints', {
              'maxWidth': constraints.maxWidth,
              'maxHeight': constraints.maxHeight,
              'mediaHeight': mediaH,
              'mediaWidth': mediaW,
              'effectiveHeight': effectiveHeight,
              'effectiveWidth': effectiveWidth,
            }, 'H1');
            // #endregion
            // When parent gives zero height (e.g. Flutter web route), use OverflowBox so the child
            // gets effective size from MediaQuery and can render; we overflow the zero-sized slot.
            final isTablet = AppLayout.isTablet(context);
            const profileTabIndex = 4;
            final showFooter = !(isTablet && _currentIndex == profileTabIndex);
            final bottomNav = _CustomBottomNav(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index == 2) {
                  _showExploreCategoryPickerThenNavigate();
                } else {
                  setState(() => _currentIndex = index);
                }
              },
              screenCount: screens.length,
              titles: _titles,
            );
            final bodyChildren = <Widget>[
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: IndexedStack(key: ValueKey<int>(_currentIndex), index: _currentIndex, children: screens),
                ),
              ),
              if (showFooter) bottomNav,
            ];
            if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
              return OverflowBox(
                minWidth: effectiveWidth,
                maxWidth: effectiveWidth,
                minHeight: effectiveHeight,
                maxHeight: effectiveHeight,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: effectiveWidth,
                  height: effectiveHeight,
                  child: Column(children: bodyChildren),
                ),
              );
            }
            return SizedBox(
              width: effectiveWidth,
              height: effectiveHeight,
              child: Column(children: bodyChildren),
            );
          },
        ),
      ),
    );
    return scaffold;
  }
}

/// App bar notification bell with optional unread badge.
class _NotificationsIcon extends StatelessWidget {
  const _NotificationsIcon({this.unreadFuture, required this.onOpen});

  final Future<int>? unreadFuture;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (unreadFuture == null) {
      return IconButton(
        onPressed: onOpen,
        icon: const Icon(Icons.notifications_outlined),
        color: AppTheme.specNavy,
        tooltip: 'Notifications',
      );
    }
    return FutureBuilder<int>(
      future: unreadFuture,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onOpen,
              icon: const Icon(Icons.notifications_outlined),
              color: AppTheme.specNavy,
              tooltip: 'Notifications',
            ),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.specRed, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.specWhite, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.title, required this.selected, required this.onTap});

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AppTheme.specGold : AppTheme.specNavy;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
      selected: selected,
      onTap: onTap,
    );
  }
}

/// Side menu content: all pages, Ask Local, Local Events, Notifications, Messages, conditional Admin, Sign out.
class _AppMenuDrawer extends ConsumerStatefulWidget {
  const _AppMenuDrawer({
    required this.currentIndex,
    required this.onClose,
    required this.onNavigateToTab,
    required this.onOpenAskLocal,
    required this.onOpenChooseForMe,
    required this.onOpenLocalEvents,
    required this.onOpenNotifications,
    required this.onOpenMessages,
    required this.onOpenAdmin,
    required this.onSignOut,
  });

  final int currentIndex;
  final VoidCallback onClose;
  final ValueChanged<int> onNavigateToTab;
  final VoidCallback onOpenAskLocal;
  final VoidCallback onOpenChooseForMe;
  final VoidCallback onOpenLocalEvents;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenAdmin;
  final VoidCallback onSignOut;

  @override
  ConsumerState<_AppMenuDrawer> createState() => _AppMenuDrawerState();
}

class _AppMenuDrawerState extends ConsumerState<_AppMenuDrawer> {
  bool? _isAdmin;
  bool _adminCheckStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isAdmin != null || _adminCheckStarted) return;
    _adminCheckStarted = true;
    ref.read(authNotifierProvider.notifier).isAdmin().then((v) {
      if (mounted) setState(() => _isAdmin = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'Menu',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: AppTheme.specNavy,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavTile(
                  icon: Icons.home_rounded,
                  title: 'Home',
                  selected: widget.currentIndex == 0,
                  onTap: () => widget.onNavigateToTab(0),
                ),
                _NavTile(
                  icon: Icons.article_rounded,
                  title: 'News',
                  selected: widget.currentIndex == 1,
                  onTap: () => widget.onNavigateToTab(1),
                ),
                _NavTile(
                  icon: Icons.explore_rounded,
                  title: 'Explore',
                  selected: widget.currentIndex == 2,
                  onTap: () => widget.onNavigateToTab(2),
                ),
                _NavTile(
                  icon: Icons.favorite_rounded,
                  title: 'Favorites',
                  selected: widget.currentIndex == 3,
                  onTap: () => widget.onNavigateToTab(3),
                ),
                _NavTile(
                  icon: Icons.local_offer_rounded,
                  title: 'Deals',
                  selected: widget.currentIndex == 4,
                  onTap: () => widget.onNavigateToTab(4),
                ),
                _NavTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  selected: widget.currentIndex == 5,
                  onTap: () => widget.onNavigateToTab(5),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: Icon(Icons.support_agent_rounded, color: AppTheme.specGold),
                  title: Text(
                    'Ask Local',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.specNavy),
                  ),
                  subtitle: const Text('AI-powered local recommendations'),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onClose();
                      widget.onOpenAskLocal();
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.casino_rounded, color: AppTheme.specGold),
                  title: Text(
                    'Choose for me',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.specNavy),
                  ),
                  subtitle: const Text('Pick a random restaurant'),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onClose();
                      widget.onOpenChooseForMe();
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.event_rounded, color: AppTheme.specNavy),
                  title: Text(
                    'Local Events',
                    style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.specNavy),
                  ),
                  subtitle: const Text('Happenings from local businesses'),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onClose();
                      widget.onOpenLocalEvents();
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.notifications_outlined, color: AppTheme.specNavy),
                  title: Text(
                    'Notifications',
                    style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.specNavy),
                  ),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onOpenNotifications());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.specNavy),
                  title: Text(
                    'Messages',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.specNavy),
                  ),
                  subtitle: const Text('Conversations with businesses'),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onOpenMessages());
                  },
                ),
                if (_isAdmin == true) ...[
                  const Divider(height: 24),
                  ListTile(
                    leading: Icon(Icons.admin_panel_settings_rounded, color: AppTheme.specNavy),
                    title: Text(
                      'Admin',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.specNavy),
                    ),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onOpenAdmin());
                    },
                  ),
                ],
                const Divider(height: 24),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: AppTheme.specNavy),
                  title: Text(
                    'Sign out',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.specNavy),
                  ),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onSignOut());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Single bottom nav item with hover scale and gold-tinted press/hover feedback.
class _BottomNavItem extends StatefulWidget {
  const _BottomNavItem({required this.icon, required this.selected, required this.label, required this.onTap});

  final IconData icon;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          hoverColor: AppTheme.specGold.withValues(alpha: 0.14),
          focusColor: AppTheme.specGold.withValues(alpha: 0.2),
          highlightColor: AppTheme.specGold.withValues(alpha: 0.22),
          splashColor: AppTheme.specGold.withValues(alpha: 0.35),
          child: Tooltip(
            message: widget.label,
            child: Center(
              child: AnimatedScale(
                scale: _hovered ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                child: widget.selected
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppTheme.specGold.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 0),
                            BoxShadow(
                              color: AppTheme.specGold.withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, size: 26, color: AppTheme.specNavy),
                      )
                    : Icon(widget.icon, size: 26, color: AppTheme.specNavy.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom nav: 5 icons only (no labels), rounded floating bar. Home, Explore, Favorites, Deals, Profile.
class _CustomBottomNav extends StatelessWidget {
  const _CustomBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.screenCount,
    required this.titles,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int screenCount;
  final List<String> titles;

  static const List<IconData> _icons = [
    Icons.home_rounded,
    Icons.article_rounded,
    Icons.explore_rounded,
    Icons.favorite_rounded,
    Icons.local_offer_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final barCount = screenCount.clamp(1, _icons.length);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottomPadding),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.specWhite,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            // Soft slide shadow (offset downward)
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(barCount, (index) {
              final selected = index == currentIndex;
              final label = index < titles.length ? titles[index] : '';
              final iconData = index < _icons.length ? _icons[index] : Icons.circle_rounded;
              return Expanded(
                child: _BottomNavItem(icon: iconData, selected: selected, label: label, onTap: () => onTap(index)),
              );
            }),
          ),
        ),
      ),
    );
  }
}
